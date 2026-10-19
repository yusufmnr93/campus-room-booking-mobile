import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/preference_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/rooms/room_list_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';

/// Root widget: menerapkan themeMode dari SharedPreferences ke MaterialApp.
class CampusRoomBookingApp extends StatefulWidget {
  final PreferenceService preferenceService;

  const CampusRoomBookingApp({super.key, required this.preferenceService});

  @override
  State<CampusRoomBookingApp> createState() => _CampusRoomBookingAppState();
}

class _CampusRoomBookingAppState extends State<CampusRoomBookingApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _parseThemeMode(widget.preferenceService.getThemeMode());
  }

  /// Menulis tema ke SharedPreferences lalu memperbarui MaterialApp.
  Future<void> _setThemeMode(String mode) async {
    await widget.preferenceService.setThemeMode(mode);
    if (!mounted) return; // Hindari setState setelah widget dibuang.
    setState(() {
      _themeMode = _parseThemeMode(mode);
    });
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainNavigation(
        preferenceService: widget.preferenceService,
        onThemeChanged: _setThemeMode,
      ),
    );
  }
}

/// Bottom navigation: Dashboard, Ruangan, Jadwal, Riwayat, Pengaturan.
class MainNavigation extends StatefulWidget {
  final PreferenceService preferenceService;
  final Future<void> Function(String) onThemeChanged;

  const MainNavigation({
    super.key,
    required this.preferenceService,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _goToRooms() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        preferenceService: widget.preferenceService,
        onSeeRooms: _goToRooms,
      ),
      RoomListScreen(preferenceService: widget.preferenceService),
      const ScheduleScreen(),
      const HistoryScreen(),
      SettingsScreen(
        preferenceService: widget.preferenceService,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'Ruangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
