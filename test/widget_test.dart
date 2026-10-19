import 'package:flutter_test/flutter_test.dart';
import 'package:campus_room_booking_mobile/core/constants/app_constants.dart';

void main() {
  test('konstanta aplikasi tersedia untuk UI', () {
    expect(AppConstants.appName, 'Campus Room Booking');
    expect(AppConstants.statusBooked, 'BOOKED');
    expect(AppConstants.statusCancelled, 'CANCELLED');
  });
}
