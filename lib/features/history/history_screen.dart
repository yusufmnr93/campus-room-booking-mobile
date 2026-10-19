import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../booking/booking_form_screen.dart';
import 'booking_detail_screen.dart';

/// Riwayat semua booking dengan filter status.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  bool _isLoading = true;
  String? _error;
  List<Booking> _bookings = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  /// Memuat riwayat dari SQLite; UI menampilkan loading sampai Future selesai.
  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await _bookingRepo.getAllBookings(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Booking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingFormScreen()),
          );
          if (!mounted) return;
          _loadBookings();
        },
        icon: const Icon(Icons.add),
        label: const Text('Pesan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _statusFilter == null,
                  onSelected: (_) {
                    setState(() => _statusFilter = null);
                    _loadBookings();
                  },
                ),
                ChoiceChip(
                  label: const Text('Dipesan'),
                  selected: _statusFilter == AppConstants.statusBooked,
                  onSelected: (_) {
                    setState(() => _statusFilter = AppConstants.statusBooked);
                    _loadBookings();
                  },
                ),
                ChoiceChip(
                  label: const Text('Dibatalkan'),
                  selected: _statusFilter == AppConstants.statusCancelled,
                  onSelected: (_) {
                    setState(
                      () => _statusFilter = AppConstants.statusCancelled,
                    );
                    _loadBookings();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Memuat riwayat...')
                : _error != null
                    ? ErrorStateWidget(
                        message: _error!,
                        onRetry: _loadBookings,
                      )
                    : _bookings.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.history_rounded,
                            title: 'Belum Ada Riwayat',
                            subtitle: 'Booking yang Anda buat akan muncul di sini.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _bookings.length,
                              itemBuilder: (context, index) {
                                final booking = _bookings[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      booking.activityName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${booking.roomName ?? 'Ruangan'} • ${booking.date}\n'
                                      '${booking.startTime}–${booking.endTime}',
                                    ),
                                    isThreeLine: true,
                                    trailing: StatusBadge(status: booking.status),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingDetailScreen(
                                            bookingId: booking.id!,
                                          ),
                                        ),
                                      );
                                      if (!mounted) return;
                                      _loadBookings();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
