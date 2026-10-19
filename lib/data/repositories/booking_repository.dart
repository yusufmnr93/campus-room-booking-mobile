import '../../core/constants/app_constants.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../database/database_helper.dart';
import 'room_repository.dart';

/// BookingRepository — CRUD booking + cek bentrok via query SQL.
class BookingRepository {
  final DatabaseHelper _dbHelper;
  final RoomRepository _roomRepository;

  BookingRepository({
    DatabaseHelper? dbHelper,
    RoomRepository? roomRepository,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _roomRepository = roomRepository ?? RoomRepository();

  static const String _joinSelect = '''
      SELECT b.*, r.name as roomName, r.building as roomBuilding
      FROM bookings b
      INNER JOIN rooms r ON b.roomId = r.id
  ''';

  /// Query SQL bentrok: BOOKED pada roomId & date yang sama.
  /// Overlap: existing.startTime < new.endTime AND existing.endTime > new.startTime.
  Future<List<Booking>> findConflicts({
    required int roomId,
    required String date,
    required String startTime,
    required String endTime,
    int? excludeBookingId,
  }) async {
    try {
      final db = await _dbHelper.database;
      final where = StringBuffer(
        'roomId = ? AND date = ? AND status = ? AND startTime < ? AND endTime > ?',
      );
      final args = <Object>[
        roomId,
        date,
        AppConstants.statusBooked,
        endTime,
        startTime,
      ];
      if (excludeBookingId != null) {
        where.write(' AND id != ?');
        args.add(excludeBookingId);
      }

      final maps = await db.query(
        'bookings',
        where: where.toString(),
        whereArgs: args,
      );
      return maps.map(Booking.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memeriksa bentrok jadwal: $e');
    }
  }

  Future<bool> hasScheduleConflict({
    required int roomId,
    required String date,
    required String startTime,
    required String endTime,
    int? excludeBookingId,
  }) async {
    final conflicts = await findConflicts(
      roomId: roomId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      excludeBookingId: excludeBookingId,
    );
    return conflicts.isNotEmpty;
  }

  Future<void> _ensureRoomBookable(int roomId) async {
    final Room? room = await _roomRepository.getRoomById(roomId);
    if (room == null) {
      throw Exception('Ruangan tidak ditemukan.');
    }
    if (!room.isActive) {
      throw Exception('Ruangan tidak aktif dan tidak dapat dipesan.');
    }
  }

  /// Menyimpan booking baru setelah cek bentrok di dalam transaksi.
  Future<int> createBooking(Booking booking) async {
    try {
      await _ensureRoomBookable(booking.roomId);
      final db = await _dbHelper.database;

      return await db.transaction((txn) async {
        final conflicts = await txn.query(
          'bookings',
          where:
              'roomId = ? AND date = ? AND status = ? AND startTime < ? AND endTime > ?',
          whereArgs: [
            booking.roomId,
            booking.date,
            AppConstants.statusBooked,
            booking.endTime,
            booking.startTime,
          ],
        );

        if (conflicts.isNotEmpty) {
          final conflict = Booking.fromMap(conflicts.first);
          throw Exception(
            'Jadwal bentrok dengan "${conflict.activityName}" '
            'pada ${conflict.startTime}-${conflict.endTime}.',
          );
        }

        return await txn.insert('bookings', booking.toMap());
      });
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menyimpan booking: $e');
    }
  }

  Future<int> updateBooking(Booking booking) async {
    if (booking.id == null) {
      throw Exception('ID booking tidak valid.');
    }
    try {
      await _ensureRoomBookable(booking.roomId);
      final db = await _dbHelper.database;

      return await db.transaction((txn) async {
        final conflicts = await txn.query(
          'bookings',
          where:
              'roomId = ? AND date = ? AND status = ? AND startTime < ? AND endTime > ? AND id != ?',
          whereArgs: [
            booking.roomId,
            booking.date,
            AppConstants.statusBooked,
            booking.endTime,
            booking.startTime,
            booking.id,
          ],
        );

        if (conflicts.isNotEmpty) {
          final conflict = Booking.fromMap(conflicts.first);
          throw Exception(
            'Jadwal bentrok dengan "${conflict.activityName}" '
            'pada ${conflict.startTime}-${conflict.endTime}.',
          );
        }

        return await txn.update(
          'bookings',
          booking.toMap(),
          where: 'id = ?',
          whereArgs: [booking.id],
        );
      });
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memperbarui booking: $e');
    }
  }

  Future<List<Booking>> getAllBookings({String? status}) async {
    try {
      final db = await _dbHelper.database;
      final buffer = StringBuffer(_joinSelect);
      final args = <Object>[];
      if (status != null && status.isNotEmpty) {
        buffer.write(' WHERE b.status = ?');
        args.add(status);
      }
      buffer.write(' ORDER BY b.date DESC, b.startTime DESC');
      final maps = await db.rawQuery(buffer.toString(), args);
      return maps.map(Booking.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memuat riwayat booking: $e');
    }
  }

  Future<Booking?> getBookingById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery('''
        $_joinSelect
        WHERE b.id = ?
        LIMIT 1
      ''', [id]);
      if (maps.isEmpty) return null;
      return Booking.fromMap(maps.first);
    } catch (e) {
      throw Exception('Gagal memuat detail booking: $e');
    }
  }

  Future<List<Booking>> getSchedule(int roomId, String date) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery('''
        $_joinSelect
        WHERE b.roomId = ? AND b.date = ? AND b.status = ?
        ORDER BY b.startTime ASC
      ''', [roomId, date, AppConstants.statusBooked]);
      return maps.map(Booking.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memuat jadwal: $e');
    }
  }

  Future<int> cancelBooking(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'bookings',
        {'status': AppConstants.statusCancelled},
        where: 'id = ? AND status = ?',
        whereArgs: [id, AppConstants.statusBooked],
      );
    } catch (e) {
      throw Exception('Gagal membatalkan booking: $e');
    }
  }

  /// Menghapus satu baris booking dari SQLite.
  Future<int> deleteBooking(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'bookings',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Gagal menghapus booking: $e');
    }
  }

  /// Menghapus seluruh riwayat booking yang tersimpan.
  Future<int> deleteAllBookings() async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('bookings');
    } catch (e) {
      throw Exception('Gagal menghapus semua booking: $e');
    }
  }

  Future<int> getActiveBookingCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookings WHERE status = ?',
        [AppConstants.statusBooked],
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      throw Exception('Gagal menghitung booking aktif: $e');
    }
  }

  Future<int> getTotalBookingCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM bookings');
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      throw Exception('Gagal menghitung total booking: $e');
    }
  }

  Future<List<Booking>> getTodayBookings() async {
    try {
      final db = await _dbHelper.database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final maps = await db.rawQuery('''
        $_joinSelect
        WHERE b.date = ? AND b.status = ?
        ORDER BY b.startTime ASC
      ''', [today, AppConstants.statusBooked]);
      return maps.map(Booking.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memuat booking hari ini: $e');
    }
  }

  /// Booking BOOKED terdekat (tanggal/jam belum lewat).
  Future<Booking?> getNearestBooking() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final maps = await db.rawQuery('''
        $_joinSelect
        WHERE b.status = ?
          AND (b.date > ? OR (b.date = ? AND b.endTime > ?))
        ORDER BY b.date ASC, b.startTime ASC
        LIMIT 1
      ''', [AppConstants.statusBooked, today, today, time]);
      if (maps.isEmpty) return null;
      return Booking.fromMap(maps.first);
    } catch (e) {
      throw Exception('Gagal memuat booking terdekat: $e');
    }
  }
}
