import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// PreferenceService — persistensi key-value via Shared Preferences.
///
/// Menyimpan data sederhana yang tetap ada setelah aplikasi ditutup:
/// tema, nama pengguna, dan filter terakhir daftar ruangan.
class PreferenceService {
  SharedPreferences? _prefs;

  /// Membaca SharedPreferences dari penyimpanan perangkat (I/O asinkron).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError(
        'PreferenceService belum diinisialisasi. Panggil init() terlebih dahulu.',
      );
    }
    return _prefs!;
  }

  String getThemeMode() {
    try {
      return _safePrefs.getString(AppConstants.prefThemeMode) ??
          AppConstants.defaultThemeMode;
    } catch (_) {
      return AppConstants.defaultThemeMode;
    }
  }

  /// Menulis tema ke disk secara asinkron agar tersimpan setelah app ditutup.
  Future<bool> setThemeMode(String mode) async {
    if (!['light', 'dark', 'system'].contains(mode)) {
      return false;
    }
    try {
      return await _safePrefs.setString(AppConstants.prefThemeMode, mode);
    } catch (_) {
      return false;
    }
  }

  String getUserName() {
    try {
      final name = _safePrefs.getString(AppConstants.prefUserName);
      if (name == null || name.trim().isEmpty) {
        return AppConstants.defaultUserName;
      }
      return name;
    } catch (_) {
      return AppConstants.defaultUserName;
    }
  }

  /// Menyimpan nama pengguna secara asinkron ke SharedPreferences.
  Future<bool> setUserName(String name) async {
    try {
      return await _safePrefs.setString(
        AppConstants.prefUserName,
        name.trim(),
      );
    } catch (_) {
      return false;
    }
  }

  String getLastFilterBuilding() {
    try {
      return _safePrefs.getString(AppConstants.prefLastFilterBuilding) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> setLastFilterBuilding(String building) async {
    try {
      return await _safePrefs.setString(
        AppConstants.prefLastFilterBuilding,
        building,
      );
    } catch (_) {
      return false;
    }
  }

  int getLastFilterMinCapacity() {
    try {
      return _safePrefs.getInt(AppConstants.prefLastFilterMinCapacity) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> setLastFilterMinCapacity(int capacity) async {
    try {
      return await _safePrefs.setInt(
        AppConstants.prefLastFilterMinCapacity,
        capacity,
      );
    } catch (_) {
      return false;
    }
  }
}
