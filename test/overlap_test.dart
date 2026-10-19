import 'package:flutter_test/flutter_test.dart';
import 'package:campus_room_booking_mobile/core/utils/date_utils.dart';

void main() {
  group('hasTimeOverlap', () {
    test('bentrok jika rentang waktu tumpang tindih', () {
      expect(
        AppDateUtils.hasTimeOverlap(
          existingStart: '08:00',
          existingEnd: '10:00',
          newStart: '09:00',
          newEnd: '11:00',
        ),
        isTrue,
      );
    });

    test('tidak bentrok jika back-to-back (selesai = mulai berikutnya)', () {
      expect(
        AppDateUtils.hasTimeOverlap(
          existingStart: '08:00',
          existingEnd: '10:00',
          newStart: '10:00',
          newEnd: '12:00',
        ),
        isFalse,
      );
    });

    test('tidak bentrok jika di luar rentang', () {
      expect(
        AppDateUtils.hasTimeOverlap(
          existingStart: '08:00',
          existingEnd: '10:00',
          newStart: '13:00',
          newEnd: '15:00',
        ),
        isFalse,
      );
    });

    test('bentrok jika booking baru menelan booking lama', () {
      expect(
        AppDateUtils.hasTimeOverlap(
          existingStart: '09:00',
          existingEnd: '10:00',
          newStart: '08:00',
          newEnd: '12:00',
        ),
        isTrue,
      );
    });
  });
}
