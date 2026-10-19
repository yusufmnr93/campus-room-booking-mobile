import 'package:flutter_test/flutter_test.dart';
import 'package:campus_room_booking_mobile/core/utils/date_utils.dart';

void main() {
  group('validateBooking', () {
    final now = DateTime(2026, 10, 19, 9, 0);

    test('gagal jika ruangan kosong', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: null,
          isRoomActive: true,
          date: '2026-10-20',
          startTime: '10:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Ruangan wajib dipilih.',
      );
    });

    test('gagal jika ruangan nonaktif', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: false,
          date: '2026-10-20',
          startTime: '10:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Ruangan tidak aktif dan tidak dapat dipesan.',
      );
    });

    test('gagal jika jam selesai tidak lebih besar', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-20',
          startTime: '12:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Jam selesai harus lebih besar dari jam mulai.',
      );
    });

    test('gagal jika format jam salah', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-20',
          startTime: '9:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Format jam mulai tidak valid. Gunakan HH:mm.',
      );
    });

    test('gagal jika tanggal sudah lewat', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-18',
          startTime: '10:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Tanggal pemesanan tidak boleh sebelum hari ini.',
      );
    });

    test('gagal jika jam mulai hari ini sudah lewat', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-19',
          startTime: '08:00',
          endTime: '10:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Jam mulai tidak boleh sudah lewat untuk tanggal hari ini.',
      );
    });

    test('lolos untuk data valid di masa depan', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-20',
          startTime: '10:00',
          endTime: '12:00',
          activityName: 'Rapat',
          purpose: 'Koordinasi',
          now: now,
        ),
        isNull,
      );
    });

    test('gagal jika nama kegiatan kosong', () {
      expect(
        AppDateUtils.validateBooking(
          roomId: 1,
          isRoomActive: true,
          date: '2026-10-20',
          startTime: '10:00',
          endTime: '12:00',
          activityName: '  ',
          purpose: 'Koordinasi',
          now: now,
        ),
        'Nama kegiatan wajib diisi.',
      );
    });
  });
}
