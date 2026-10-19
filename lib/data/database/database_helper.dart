import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// DatabaseHelper — Singleton untuk koneksi SQLite.
///
/// onCreate: membuat tabel + seeding ruangan (hanya sekali).
/// onConfigure: PRAGMA foreign_keys=ON.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const String dbName = 'campus_room_booking.db';
  static const int dbVersion = 2;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Membuka file DB secara asinkron (I/O disk, tidak boleh di UI thread).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Dipanggil SQLite hanya saat file DB baru dibuat.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        building TEXT NOT NULL,
        facilities TEXT NOT NULL DEFAULT '',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomId INTEGER NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        activityName TEXT NOT NULL,
        purpose TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusBooked}',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (roomId) REFERENCES rooms (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_bookings_room_date ON bookings (roomId, date, status)',
    );

    // Seeding hanya di onCreate agar tidak menggandakan data.
    await _seedRooms(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "UPDATE bookings SET status = '${AppConstants.statusBooked}' WHERE status = 'PENDING'",
      );
    }
  }

  Future<void> _seedRooms(Database db) async {
    final now = DateTime.now().toIso8601String();

    final rooms = [
      {
        'name': 'Aula Gedung A',
        'capacity': 200,
        'building': 'Gedung A',
        'facilities': 'AC, Proyektor, Sound System, Podium, WiFi',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Ruang Kelas A-101',
        'capacity': 40,
        'building': 'Gedung A',
        'facilities': 'AC, Proyektor, Whiteboard',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Ruang Seminar B-201',
        'capacity': 80,
        'building': 'Gedung B',
        'facilities': 'AC, Proyektor, WiFi, Whiteboard',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Ruang Diskusi B-102',
        'capacity': 15,
        'building': 'Gedung B',
        'facilities': 'AC, Whiteboard, WiFi',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Lab Komputer C-101',
        'capacity': 40,
        'building': 'Gedung C',
        'facilities': 'AC, Komputer 40 Unit, Proyektor, WiFi',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Lab Multimedia C-201',
        'capacity': 30,
        'building': 'Gedung C',
        'facilities': 'AC, Komputer 30 Unit, Proyektor, Green Screen, WiFi',
        'isActive': 0, // Demo aturan ruangan nonaktif
        'createdAt': now,
      },
      {
        'name': 'Ruang Rapat D-301',
        'capacity': 20,
        'building': 'Gedung D',
        'facilities': 'AC, Proyektor, Whiteboard, WiFi',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Ruang Kelas E-102',
        'capacity': 50,
        'building': 'Gedung E',
        'facilities': 'AC, Proyektor, Whiteboard',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Auditorium Utama',
        'capacity': 500,
        'building': 'Gedung Rektorat',
        'facilities': 'AC, Proyektor, Sound System, Podium, WiFi, Panggung',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Ruang Sidang Rektorat',
        'capacity': 25,
        'building': 'Gedung Rektorat',
        'facilities': 'AC, Proyektor, Sound System, WiFi',
        'isActive': 1,
        'createdAt': now,
      },
    ];

    final batch = db.batch();
    for (final room in rooms) {
      batch.insert('rooms', room);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
