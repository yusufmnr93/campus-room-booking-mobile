import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/database/database_helper.dart';
import 'services/preference_service.dart';

/// Entry point aplikasi Campus Room Booking.
void main() async {
  // Binding wajib diinisialisasi sebelum plugin asinkron (SQLite & SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Memuat data lokal tanggal Indonesia secara asinkron.
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Gagal inisialisasi locale id_ID: $e');
  }

  // Membuka database (onCreate + seeding jika file DB belum ada).
  try {
    await DatabaseHelper().database;
  } catch (e) {
    debugPrint('Gagal menginisialisasi database: $e');
  }

  // Membaca SharedPreferences sebelum MaterialApp dibangun (tema & nama).
  final preferenceService = PreferenceService();
  try {
    await preferenceService.init();
  } catch (e) {
    debugPrint('Gagal menginisialisasi SharedPreferences: $e');
  }

  runApp(CampusRoomBookingApp(preferenceService: preferenceService));
}
