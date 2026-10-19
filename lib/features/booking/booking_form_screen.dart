import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/room_repository.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';

/// Form pemesanan ruangan: validasi, cek bentrok, simpan ke SQLite.
class BookingFormScreen extends StatefulWidget {
  final int? preselectedRoomId;
  final Booking? existing;

  const BookingFormScreen({
    super.key,
    this.preselectedRoomId,
    this.existing,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final RoomRepository _roomRepo = RoomRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final _activityController = TextEditingController();
  final _purposeController = TextEditingController();

  bool _loadingRooms = true;
  bool _saving = false;
  String? _error;
  List<Room> _rooms = [];
  int? _roomId;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _roomId = existing.roomId;
      _date = AppDateUtils.tryParseDate(existing.date);
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
      _activityController.text = existing.activityName;
      _purposeController.text = existing.purpose;
    } else {
      _roomId = widget.preselectedRoomId;
    }
    _loadRooms();
  }

  @override
  void dispose() {
    _activityController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _roomRepo.getAllRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loadingRooms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingRooms = false;
      });
    }
  }

  Room? get _selectedRoom {
    if (_roomId == null) return null;
    for (final room in _rooms) {
      if (room.id == _roomId) return room;
    }
    return null;
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return 'Pilih jam';
    return AppDateUtils.formatTime(time.hour, time.minute);
  }

  String _dateLabel() {
    if (_date == null) return 'Pilih tanggal';
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date!);
    } catch (_) {
      return AppDateUtils.formatDate(_date!);
    }
  }

  /// Menunggu DatePicker (dialog asinkron sistem).
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal pemesanan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      helpText: 'Pilih jam mulai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          (_startTime != null
              ? TimeOfDay(
                  hour: (_startTime!.hour + 1) % 24,
                  minute: _startTime!.minute,
                )
              : TimeOfDay.now()),
      helpText: 'Pilih jam selesai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submit() async {
    final room = _selectedRoom;
    final dateStr = _date == null ? '' : AppDateUtils.formatDate(_date!);
    final start = _startTime == null ? '' : _timeLabel(_startTime);
    final end = _endTime == null ? '' : _timeLabel(_endTime);

    final validationError = AppDateUtils.validateBooking(
      roomId: _roomId,
      isRoomActive: room?.isActive,
      date: dateStr,
      startTime: start,
      endTime: end,
      activityName: _activityController.text,
      purpose: _purposeController.text,
    );

    if (validationError != null) {
      _showSnack(validationError, success: false);
      return;
    }

    setState(() => _saving = true);

    try {
      final conflict = await _bookingRepo.hasScheduleConflict(
        roomId: _roomId!,
        date: dateStr,
        startTime: start,
        endTime: end,
        excludeBookingId: widget.existing?.id,
      );
      if (conflict) {
        throw Exception(
          'Jadwal bentrok dengan booking lain pada ruangan dan tanggal yang sama.',
        );
      }

      final booking = Booking(
        id: widget.existing?.id,
        roomId: _roomId!,
        date: dateStr,
        startTime: start,
        endTime: end,
        activityName: _activityController.text.trim(),
        purpose: _purposeController.text.trim(),
        status: widget.existing?.status ?? AppConstants.statusBooked,
        createdAt: widget.existing?.createdAt,
      );

      if (_isEdit) {
        await _bookingRepo.updateBooking(booking);
      } else {
        await _bookingRepo.createBooking(booking);
      }

      if (!mounted) return;
      _showSnack(
        _isEdit ? 'Booking berhasil diperbarui.' : 'Booking berhasil disimpan.',
        success: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    }
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Booking' : 'Pesan Ruangan'),
      ),
      body: _loadingRooms
          ? const LoadingWidget(message: 'Memuat ruangan...')
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _loadRooms)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey(_roomId),
                      initialValue: _roomId,
                      decoration: const InputDecoration(
                        labelText: 'Ruangan',
                      ),
                      items: _rooms.map((room) {
                        final label = room.isActive
                            ? '${room.name} (${room.building})'
                            : '${room.name} — Nonaktif';
                        return DropdownMenuItem(
                          value: room.id,
                          enabled: room.isActive,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _roomId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal'),
                      subtitle: Text(_dateLabel()),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: _pickDate,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Jam mulai'),
                      subtitle: Text(_timeLabel(_startTime)),
                      trailing: const Icon(Icons.schedule_rounded),
                      onTap: _pickStartTime,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Jam selesai'),
                      subtitle: Text(_timeLabel(_endTime)),
                      trailing: const Icon(Icons.schedule_rounded),
                      onTap: _pickEndTime,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _activityController,
                      decoration: const InputDecoration(
                        labelText: 'Nama kegiatan',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Tujuan',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan Booking'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
