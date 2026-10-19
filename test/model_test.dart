import 'package:flutter_test/flutter_test.dart';
import 'package:campus_room_booking_mobile/core/constants/app_constants.dart';
import 'package:campus_room_booking_mobile/models/booking.dart';
import 'package:campus_room_booking_mobile/models/room.dart';

void main() {
  group('Room fromMap/toMap', () {
    test('round-trip mempertahankan field utama', () {
      final room = Room(
        id: 3,
        name: 'Lab Komputer C-101',
        capacity: 40,
        building: 'Gedung C',
        facilities: 'AC, WiFi',
        isActive: false,
        createdAt: '2026-01-01T00:00:00.000',
      );

      final map = room.toMap();
      expect(map['id'], 3);
      expect(map['isActive'], 0);
      expect(map['capacity'], 40);

      final restored = Room.fromMap(map);
      expect(restored.id, room.id);
      expect(restored.name, room.name);
      expect(restored.capacity, room.capacity);
      expect(restored.building, room.building);
      expect(restored.facilities, room.facilities);
      expect(restored.isActive, isFalse);
      expect(restored.createdAt, room.createdAt);
    });

    test('fromMap membaca isActive=1 sebagai true', () {
      final room = Room.fromMap({
        'id': 1,
        'name': 'Aula',
        'capacity': 200,
        'building': 'Gedung A',
        'facilities': 'AC',
        'isActive': 1,
        'createdAt': '2026-01-01T00:00:00.000',
      });
      expect(room.isActive, isTrue);
      expect(room.facilitiesList, ['AC']);
    });
  });

  group('Booking fromMap/toMap', () {
    test('round-trip tanpa field JOIN', () {
      final booking = Booking(
        id: 9,
        roomId: 2,
        date: '2026-10-20',
        startTime: '08:00',
        endTime: '10:00',
        activityName: 'Seminar',
        purpose: 'Akademik',
        status: AppConstants.statusBooked,
        createdAt: '2026-10-19T01:00:00.000',
      );

      final map = booking.toMap();
      expect(map.containsKey('roomName'), isFalse);
      expect(map['status'], 'BOOKED');

      final restored = Booking.fromMap(map);
      expect(restored.id, 9);
      expect(restored.roomId, 2);
      expect(restored.date, '2026-10-20');
      expect(restored.startTime, '08:00');
      expect(restored.endTime, '10:00');
      expect(restored.activityName, 'Seminar');
      expect(restored.purpose, 'Akademik');
      expect(restored.status, 'BOOKED');
      expect(restored.isActive, isTrue);
      expect(restored.canCancel, isTrue);
    });

    test('fromMap membaca alias JOIN roomName', () {
      final booking = Booking.fromMap({
        'id': 1,
        'roomId': 5,
        'date': '2026-10-21',
        'startTime': '13:00',
        'endTime': '15:00',
        'activityName': 'Rapat',
        'purpose': 'Dosen',
        'status': 'CANCELLED',
        'createdAt': '2026-10-19T01:00:00.000',
        'roomName': 'Ruang Rapat D-301',
        'roomBuilding': 'Gedung D',
      });
      expect(booking.roomName, 'Ruang Rapat D-301');
      expect(booking.roomBuilding, 'Gedung D');
      expect(booking.isActive, isFalse);
      expect(booking.statusLabel, 'Dibatalkan');
    });
  });
}
