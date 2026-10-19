import 'package:flutter/material.dart';
import '../../data/repositories/room_repository.dart';
import '../../models/room.dart';
import '../../services/preference_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/loading_widget.dart';
import 'room_detail_screen.dart';

/// Daftar ruangan dengan filter gedung & kapasitas (disimpan SharedPreferences).
class RoomListScreen extends StatefulWidget {
  final PreferenceService preferenceService;

  const RoomListScreen({super.key, required this.preferenceService});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final RoomRepository _roomRepo = RoomRepository();

  bool _isLoading = true;
  String? _error;
  List<Room> _rooms = [];
  List<String> _buildings = [];
  String _building = '';
  int _minCapacity = 0;
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreFiltersAndLoad();
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  /// Membaca filter terakhir dari SharedPreferences lalu memuat SQLite.
  Future<void> _restoreFiltersAndLoad() async {
    final savedBuilding = widget.preferenceService.getLastFilterBuilding();
    final savedCapacity = widget.preferenceService.getLastFilterMinCapacity();
    _building = savedBuilding;
    _minCapacity = savedCapacity;
    _capacityController.text = savedCapacity > 0 ? '$savedCapacity' : '';
    await _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _roomRepo.getAllRooms(),
        _roomRepo.getBuildings(),
      ]);
      if (!mounted) return;
      setState(() {
        _rooms = results[0] as List<Room>;
        _buildings = results[1] as List<String>;
        if (_building.isNotEmpty && !_buildings.contains(_building)) {
          _building = '';
        }
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

  List<Room> get _filteredRooms {
    return _rooms.where((room) {
      final matchBuilding =
          _building.isEmpty || room.building == _building;
      final matchCapacity = room.capacity >= _minCapacity;
      return matchBuilding && matchCapacity;
    }).toList();
  }

  /// Menyimpan filter ke SharedPreferences agar pulih saat app dibuka lagi.
  Future<void> _persistFilters() async {
    await widget.preferenceService.setLastFilterBuilding(_building);
    await widget.preferenceService.setLastFilterMinCapacity(_minCapacity);
  }

  Future<void> _onBuildingChanged(String? value) async {
    setState(() => _building = value ?? '');
    await _persistFilters();
  }

  Future<void> _onCapacityChanged(String value) async {
    final parsed = int.tryParse(value.trim()) ?? 0;
    setState(() => _minCapacity = parsed < 0 ? 0 : parsed);
    await _persistFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Ruangan')),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat daftar ruangan...')
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _loadRooms)
              : _rooms.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.meeting_room_outlined,
                      title: 'Belum Ada Ruangan',
                      subtitle: 'Data ruangan belum tersedia.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRooms,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('building_$_building'),
                                    initialValue: _building,
                                    decoration: const InputDecoration(
                                      labelText: 'Gedung',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('Semua gedung'),
                                      ),
                                      ..._buildings.map(
                                        (b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(b),
                                        ),
                                      ),
                                    ],
                                    onChanged: _onBuildingChanged,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _capacityController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Kapasitas min.',
                                      hintText: '0',
                                    ),
                                    onChanged: _onCapacityChanged,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _filteredRooms.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.filter_alt_off_rounded,
                                    title: 'Tidak Ditemukan',
                                    subtitle:
                                        'Tidak ada ruangan yang sesuai filter.',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: _filteredRooms.length,
                                    itemBuilder: (context, index) {
                                      return _buildRoomCard(
                                        _filteredRooms[index],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(roomId: room.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: room.isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.meeting_room_rounded,
                  color: room.isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!room.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nonaktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          room.building,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.capacity} orang',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
