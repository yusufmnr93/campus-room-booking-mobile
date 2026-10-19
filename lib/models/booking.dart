import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';

/// Model Booking — merepresentasikan data pemesanan ruangan
/// sesuai tabel `bookings` di SQLite lokal.
///
/// Status: BOOKED (memblokir jadwal) | CANCELLED (tidak memblokir).
class Booking {
  final int? id;
  final int roomId;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String activityName;
  final String purpose;
  final String status;
  final String createdAt;

  /// Diisi saat query JOIN dengan tabel rooms.
  final String? roomName;
  final String? roomBuilding;

  Booking({
    this.id,
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.activityName,
    required this.purpose,
    this.status = AppConstants.statusBooked,
    String? createdAt,
    this.roomName,
    this.roomBuilding,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      roomId: map['roomId'] as int,
      date: map['date'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      activityName: map['activityName'] as String,
      purpose: map['purpose'] as String,
      status: map['status'] as String? ?? AppConstants.statusBooked,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      roomName: map['roomName'] as String?,
      roomBuilding: map['roomBuilding'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'roomId': roomId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'activityName': activityName,
      'purpose': purpose,
      'status': status,
      'createdAt': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  bool get isActive => status == AppConstants.statusBooked;

  bool get canCancel => status == AppConstants.statusBooked;

  String get statusLabel => AppDateUtils.statusLabel(status);

  Booking copyWith({
    int? id,
    int? roomId,
    String? date,
    String? startTime,
    String? endTime,
    String? activityName,
    String? purpose,
    String? status,
    String? createdAt,
    String? roomName,
    String? roomBuilding,
  }) {
    return Booking(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activityName: activityName ?? this.activityName,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      roomName: roomName ?? this.roomName,
      roomBuilding: roomBuilding ?? this.roomBuilding,
    );
  }

  @override
  String toString() =>
      'Booking(id: $id, room: $roomId, date: $date, $startTime-$endTime, status: $status)';
}
