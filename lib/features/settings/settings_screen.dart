import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/booking_repository.dart';
import '../../services/preference_service.dart';

/// Pengaturan: tema, nama pengguna, hapus semua riwayat, info aplikasi.
class SettingsScreen extends StatefulWidget {
  final PreferenceService preferenceService;
  final Future<void> Function(String) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.preferenceService,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  late final TextEditingController _nameController;
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.preferenceService.getThemeMode();
    _nameController = TextEditingController(
      text: widget.preferenceService.getUserName(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Menulis nama ke SharedPreferences (I/O asinkron).
  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengguna wajib diisi.')),
      );
      return;
    }
    await widget.preferenceService.setUserName(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nama pengguna disimpan.')),
    );
    setState(() {});
  }

  Future<void> _changeTheme(String mode) async {
    await widget.onThemeChanged(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _deleteAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua riwayat?'),
        content: const Text(
          'Seluruh data booking di perangkat ini akan dihapus permanen. Data ruangan tidak terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _bookingRepo.deleteAllBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua riwayat booking telah dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tampilan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<String>(
              groupValue: _themeMode,
              onChanged: (v) {
                if (v != null) _changeTheme(v);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Mengikuti sistem'),
                    value: 'system',
                  ),
                  RadioListTile<String>(
                    title: Text('Terang'),
                    value: 'light',
                  ),
                  RadioListTile<String>(
                    title: Text('Gelap'),
                    value: 'dark',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Profil',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengguna',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveName,
                      child: const Text('Simpan Nama'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('Hapus semua riwayat booking'),
              subtitle: const Text('Menghapus data SQLite pada tabel bookings'),
              onTap: _deleteAllHistory,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tentang Aplikasi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Versi ${AppConstants.appVersion}'),
                  const SizedBox(height: 8),
                  Text(AppConstants.appDescription),
                  const SizedBox(height: 8),
                  const Text(
                    'UTS Pemrograman Multiplatform — aplikasi standalone offline '
                    'dengan SQLite dan Shared Preferences.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
