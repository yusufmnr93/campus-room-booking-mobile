import 'package:sqflite/sqflite.dart';
import '../../models/room.dart';
import '../database/database_helper.dart';

/// RoomRepository — operasi CRUD/query ruangan (seluruh method asinkron).
class RoomRepository {
  final DatabaseHelper _dbHelper;

  RoomRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Query SQLite bersifat asinkron karena akses disk.
  Future<List<Room>> getAllRooms() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('rooms', orderBy: 'name ASC');
      return maps.map(Room.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar ruangan: $e');
    }
  }

  Future<List<Room>> getActiveRooms() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'rooms',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return maps.map(Room.fromMap).toList();
    } catch (e) {
      throw Exception('Gagal memuat ruangan aktif: $e');
    }
  }

  Future<Room?> getRoomById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'rooms',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Room.fromMap(maps.first);
    } catch (e) {
      throw Exception('Gagal memuat detail ruangan: $e');
    }
  }

  Future<int> getRoomCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM rooms');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Gagal menghitung ruangan: $e');
    }
  }

  Future<int> getActiveRoomCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM rooms WHERE isActive = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Gagal menghitung ruangan aktif: $e');
    }
  }

  Future<List<String>> getBuildings() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery(
        'SELECT DISTINCT building FROM rooms ORDER BY building ASC',
      );
      return maps.map((m) => m['building'] as String).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar gedung: $e');
    }
  }
}
