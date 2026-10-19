import 'package:flutter/material.dart';
import '../../data/repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../booking/booking_form_screen.dart';

/// Detail booking: batalkan (status CANCELLED) dan hapus (konfirmasi).
class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  bool _isLoading = true;
  String? _error;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final booking = await _bookingRepo.getBookingById(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isLoading = false;
        if (booking == null) {
          _error = 'Booking tidak ditemukan.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
      'Batalkan booking?',
      'Status akan diubah menjadi Dibatalkan. Slot jadwal menjadi tersedia kembali.',
    );
    if (!ok || !mounted) return;
    try {
      await _bookingRepo.cancelBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dibatalkan.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      'Hapus booking?',
      'Data booking akan dihapus permanen dari perangkat ini.',
    );
    if (!ok || !mounted) return;
    try {
      await _bookingRepo.deleteBooking(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dihapus.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Booking')),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat detail booking...')
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : booking == null
                  ? const ErrorStateWidget(message: 'Booking tidak ditemukan')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.activityName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(status: booking.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _row('Ruangan', booking.roomName ?? '-'),
                                _row('Gedung', booking.roomBuilding ?? '-'),
                                _row('Tanggal', booking.date),
                                _row(
                                  'Waktu',
                                  '${booking.startTime} – ${booking.endTime}',
                                ),
                                _row('Tujuan', booking.purpose),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (booking.canCancel)
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingFormScreen(
                                    existing: booking,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              _load();
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Ubah Booking'),
                          ),
                        if (booking.canCancel) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _cancel,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Batalkan'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Hapus'),
                        ),
                      ],
                    ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
