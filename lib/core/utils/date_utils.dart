import '../constants/app_constants.dart';

/// Utilitas tanggal/waktu dan validasi booking (logika murni, mudah diuji).
class AppDateUtils {
  AppDateUtils._();

  static final RegExp timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Format DateTime ke yyyy-MM-dd.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Format jam ke HH:mm.
  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? tryParseDate(String date) {
    if (!datePattern.hasMatch(date)) return null;
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Cek bentrok jam. Sama dengan SQL:
  /// existing.startTime < new.endTime AND existing.endTime > new.startTime.
  /// String HH:mm dapat dibandingkan leksikografis.
  static bool hasTimeOverlap({
    required String existingStart,
    required String existingEnd,
    required String newStart,
    required String newEnd,
  }) {
    return existingStart.compareTo(newEnd) < 0 &&
        existingEnd.compareTo(newStart) > 0;
  }

  /// Validasi form booking. Mengembalikan pesan error Bahasa Indonesia, atau null jika valid.
  static String? validateBooking({
    required int? roomId,
    required bool? isRoomActive,
    required String date,
    required String startTime,
    required String endTime,
    required String activityName,
    required String purpose,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (roomId == null) {
      return 'Ruangan wajib dipilih.';
    }
    if (isRoomActive == false) {
      return 'Ruangan tidak aktif dan tidak dapat dipesan.';
    }
    if (date.trim().isEmpty) {
      return 'Tanggal wajib diisi.';
    }
    if (startTime.trim().isEmpty) {
      return 'Jam mulai wajib diisi.';
    }
    if (endTime.trim().isEmpty) {
      return 'Jam selesai wajib diisi.';
    }
    if (activityName.trim().isEmpty) {
      return 'Nama kegiatan wajib diisi.';
    }
    if (purpose.trim().isEmpty) {
      return 'Tujuan kegiatan wajib diisi.';
    }
    if (!datePattern.hasMatch(date)) {
      return 'Format tanggal tidak valid. Gunakan yyyy-MM-dd.';
    }
    if (!timePattern.hasMatch(startTime)) {
      return 'Format jam mulai tidak valid. Gunakan HH:mm.';
    }
    if (!timePattern.hasMatch(endTime)) {
      return 'Format jam selesai tidak valid. Gunakan HH:mm.';
    }
    if (endTime.compareTo(startTime) <= 0) {
      return 'Jam selesai harus lebih besar dari jam mulai.';
    }

    final parsedDate = tryParseDate(date);
    if (parsedDate == null) {
      return 'Tanggal tidak valid.';
    }

    final todayDate = DateTime(current.year, current.month, current.day);
    if (parsedDate.isBefore(todayDate)) {
      return 'Tanggal pemesanan tidak boleh sebelum hari ini.';
    }

    if (parsedDate.year == todayDate.year &&
        parsedDate.month == todayDate.month &&
        parsedDate.day == todayDate.day) {
      final nowTime = formatTime(current.hour, current.minute);
      if (startTime.compareTo(nowTime) <= 0) {
        return 'Jam mulai tidak boleh sudah lewat untuk tanggal hari ini.';
      }
    }

    return null;
  }

  static String statusLabel(String status) {
    switch (status) {
      case AppConstants.statusBooked:
        return 'Dipesan';
      case AppConstants.statusCancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
