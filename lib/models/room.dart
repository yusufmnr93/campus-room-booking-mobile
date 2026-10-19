/// Model Ruangan — merepresentasikan data ruangan kampus
/// Sesuai dengan tabel `rooms` di SQLite lokal
class Room {
  final int? id;
  final String name;
  final int capacity;
  final String building;
  final String facilities; // Comma-separated: "AC, Proyektor, Sound System"
  final bool isActive;
  final String createdAt;

  Room({
    this.id,
    required this.name,
    required this.capacity,
    required this.building,
    required this.facilities,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Konversi dari Map (hasil query SQLite) ke object Room
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      building: map['building'] as String,
      facilities: map['facilities'] as String? ?? '',
      isActive: (map['isActive'] as int?) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Konversi object Room ke Map untuk insert/update SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'capacity': capacity,
      'building': building,
      'facilities': facilities,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Daftar fasilitas (dipisah koma pada kolom `facilities`).
  List<String> get facilitiesList {
    if (facilities.trim().isEmpty) return [];
    return facilities.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
  }

  Room copyWith({
    int? id,
    String? name,
    int? capacity,
    String? building,
    String? facilities,
    bool? isActive,
    String? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      building: building ?? this.building,
      facilities: facilities ?? this.facilities,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Room(id: $id, name: $name, building: $building)';
}
