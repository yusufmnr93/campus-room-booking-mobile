import 'package:flutter/material.dart';
import '../../data/repositories/room_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../models/room.dart';
import '../../models/booking.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../booking/booking_form_screen.dart';

/// Halaman Detail Ruangan — menampilkan informasi lengkap ruangan
/// dan jadwal booking yang telah terdaftar.
class RoomDetailScreen extends StatefulWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final RoomRepository _roomRepo = RoomRepository();
  final BookingRepository _bookingRepo = BookingRepository();

  bool _isLoading = true;
  String? _error;
  Room? _room;
  List<Booking> _upcomingBookings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Memuat detail ruangan dan jadwal hari ini dari SQLite (I/O asinkron).
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final room = await _roomRepo.getRoomById(widget.roomId);
      if (room == null) {
        throw Exception('Ruangan tidak ditemukan');
      }

      // Ambil jadwal hari ini untuk ruangan ini
      final today = DateTime.now().toIso8601String().split('T')[0];
      final bookings = await _bookingRepo.getSchedule(widget.roomId, today);

      if (!mounted) return;
      setState(() {
        _room = room;
        _upcomingBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_room?.name ?? 'Detail Ruangan'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat detail ruangan...')
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _loadData)
              : _room == null
                  ? const ErrorStateWidget(
                      message: 'Ruangan tidak ditemukan')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Header ruangan
                        _buildHeader(colorScheme),
                        const SizedBox(height: 16),

                        // Info kapasitas & gedung
                        _buildInfoSection(colorScheme),
                        const SizedBox(height: 16),

                        // Fasilitas
                        _buildFacilitiesSection(colorScheme),
                        const SizedBox(height: 16),

                        // Jadwal hari ini
                        _buildTodaySchedule(colorScheme),
                        const SizedBox(height: 24),

                        // Tombol booking
                        if (_room!.isActive)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingFormScreen(
                                      preselectedRoomId: _room!.id,
                                    ),
                                  ),
                                );
                                _loadData();
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Pesan Ruangan'),
                            ),
                          ),
                        if (!_room!.isActive)
                          Card(
                            color: colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: colorScheme.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Ruangan sedang tidak aktif dan tidak dapat dipesan.',
                                      style: TextStyle(
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _room!.isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.meeting_room_rounded,
                color: _room!.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _room!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _room!.isActive
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                          : colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _room!.isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _room!.isActive
                            ? const Color(0xFF2E7D32)
                            : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Gedung',
              _room!.building,
            ),
            const Divider(height: 20),
            _buildInfoRow(
              Icons.people_outline_rounded,
              'Kapasitas',
              '${_room!.capacity} orang',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection(ColorScheme colorScheme) {
    final facilities = _room!.facilitiesList;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fasilitas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (facilities.isEmpty)
              Text(
                'Tidak ada informasi fasilitas',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: facilities.map((f) {
                  return Chip(
                    avatar: Icon(
                      _getFacilityIcon(f),
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(f, style: const TextStyle(fontSize: 13)),
                    backgroundColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.4),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFacilityIcon(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('ac')) return Icons.ac_unit_rounded;
    if (lower.contains('proyektor')) return Icons.videocam_rounded;
    if (lower.contains('sound')) return Icons.speaker_rounded;
    if (lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('komputer')) return Icons.computer_rounded;
    if (lower.contains('whiteboard')) return Icons.dashboard_rounded;
    if (lower.contains('podium')) return Icons.campaign_rounded;
    if (lower.contains('panggung')) return Icons.theater_comedy_rounded;
    if (lower.contains('green screen')) return Icons.camera_alt_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildTodaySchedule(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_upcomingBookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: const Color(0xFF2E7D32),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tidak ada booking hari ini',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_upcomingBookings.length, (index) {
                final booking = _upcomingBookings[index];
                return Container(
                  margin: EdgeInsets.only(
                      bottom:
                          index < _upcomingBookings.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.activityName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${booking.startTime} - ${booking.endTime}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
