import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';

/// Jadwal: pilih ruangan + tanggal, tampilkan booking BOOKED hari itu.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final RoomRepository _roomRepo = RoomRepository();
  final BookingRepository _bookingRepo = BookingRepository();

  bool _loadingRooms = true;
  bool _loadingSchedule = false;
  String? _error;
  List<Room> _rooms = [];
  List<Booking> _bookings = [];
  int? _roomId;
  DateTime _date = AppDateUtils.today();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _error = null;
    });
    try {
      final rooms = await _roomRepo.getAllRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _roomId = rooms.isNotEmpty ? rooms.first.id : null;
        _loadingRooms = false;
      });
      if (_roomId != null) {
        await _loadSchedule();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingRooms = false;
      });
    }
  }

  Future<void> _loadSchedule() async {
    if (_roomId == null) return;
    setState(() {
      _loadingSchedule = true;
      _error = null;
    });
    try {
      final bookings = await _bookingRepo.getSchedule(
        _roomId!,
        AppDateUtils.formatDate(_date),
      );
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loadingSchedule = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSchedule = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal jadwal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _date = picked);
      await _loadSchedule();
    }
  }

  String _dateLabel() {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date);
    } catch (_) {
      return AppDateUtils.formatDate(_date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Ruangan')),
      body: _loadingRooms
          ? const LoadingWidget(message: 'Memuat ruangan...')
          : _error != null && _rooms.isEmpty
              ? ErrorStateWidget(message: _error!, onRetry: _loadRooms)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            key: ValueKey(_roomId),
                            initialValue: _roomId,
                            decoration: const InputDecoration(
                              labelText: 'Ruangan',
                            ),
                            items: _rooms
                                .map(
                                  (room) => DropdownMenuItem(
                                    value: room.id,
                                    child: Text(
                                      '${room.name} (${room.building})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              setState(() => _roomId = value);
                              await _loadSchedule();
                            },
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tanggal'),
                            subtitle: Text(_dateLabel()),
                            trailing: const Icon(Icons.calendar_today_rounded),
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loadingSchedule
                          ? const LoadingWidget(message: 'Memuat jadwal...')
                          : _error != null
                              ? ErrorStateWidget(
                                  message: _error!,
                                  onRetry: _loadSchedule,
                                )
                              : _bookings.isEmpty
                                  ? const EmptyStateWidget(
                                      icon: Icons.event_available_rounded,
                                      title: 'Tidak Ada Jadwal',
                                      subtitle:
                                          'Belum ada booking aktif pada ruangan dan tanggal ini.',
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: _bookings.length,
                                      itemBuilder: (context, index) {
                                        final booking = _bookings[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.schedule_rounded,
                                            ),
                                            title: Text(booking.activityName),
                                            subtitle: Text(
                                              '${booking.startTime} – ${booking.endTime}\n'
                                              '${booking.purpose}',
                                            ),
                                            isThreeLine: true,
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
    );
  }
}
