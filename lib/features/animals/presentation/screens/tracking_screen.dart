import 'package:flutter/material.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/zones/presentation/screens/map_screen.dart';

enum AnimalType { cattle, sheep, horse, goat, pig, other }

enum AnimalZoneStatus { inside, outside, alert }

class AnimalEntity {
  final String id;
  final String name;
  final AnimalType type;
  final bool isTracking;
  final double lastLatitude;
  final double lastLongitude;
  final DateTime lastUpdate;
  final AnimalZoneStatus zoneStatus;
  final String? zoneName;
  final double? batteryLevel;
  final double? speed;

  AnimalEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.isTracking,
    required this.lastLatitude,
    required this.lastLongitude,
    required this.lastUpdate,
    this.zoneStatus = AnimalZoneStatus.outside,
    this.zoneName,
    this.batteryLevel,
    this.speed,
  });
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final List<AnimalEntity> _animals = [
    AnimalEntity(
      id: '1',
      name: 'Alabaş-1',
      type: AnimalType.cattle,
      isTracking: true,
      lastLatitude: 40.3686,
      lastLongitude: 49.8671,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 1)),
      zoneStatus: AnimalZoneStatus.inside,
      zoneName: 'Otlaq-1',
      batteryLevel: 0.81,
      speed: 2.4,
    ),
    AnimalEntity(
      id: '2',
      name: 'Qoç-2',
      type: AnimalType.sheep,
      isTracking: true,
      lastLatitude: 40.3700,
      lastLongitude: 49.8680,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      zoneStatus: AnimalZoneStatus.alert,
      zoneName: 'Otlaq-1',
      batteryLevel: 0.45,
      speed: 8.1,
    ),
    AnimalEntity(
      id: '3',
      name: 'Küheylan',
      type: AnimalType.horse,
      isTracking: true,
      lastLatitude: 40.3720,
      lastLongitude: 49.8690,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 3)),
      zoneStatus: AnimalZoneStatus.outside,
      zoneName: 'Otlaq-2',
      batteryLevel: 0.92,
      speed: 0.0,
    ),
    AnimalEntity(
      id: '4',
      name: 'Keçim-1',
      type: AnimalType.goat,
      isTracking: false,
      lastLatitude: 40.3710,
      lastLongitude: 49.8660,
      lastUpdate: DateTime.now().subtract(const Duration(hours: 2)),
      zoneStatus: AnimalZoneStatus.outside,
      batteryLevel: 0.12,
      speed: 0.0,
    ),
  ];

  String _filterStatus = 'all';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  List<AnimalEntity> get _filtered {
    switch (_filterStatus) {
      case 'active':
        return _animals.where((a) => a.isTracking).toList();
      case 'alert':
        return _animals
            .where((a) => a.zoneStatus == AnimalZoneStatus.alert)
            .toList();
      default:
        return _animals;
    }
  }

  int get _alertCount =>
      _animals.where((a) => a.zoneStatus == AnimalZoneStatus.alert).length;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Tracking Screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSummaryCards(),
                _buildFilterRow(),
                Expanded(
                  child: _filtered.isEmpty ? _buildEmpty() : _buildList(),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: _selectedIds.isNotEmpty
                  ? FloatingActionButton.extended(
                      heroTag: 'fab_group',
                      onPressed: _showGroupActions,
                      backgroundColor: const Color(0xFF2ECC71),
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: Text(
                        '${_selectedIds.length} seçildi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : FloatingActionButton(
                      heroTag: 'fab_add',
                      onPressed: _showAddAnimal,
                      backgroundColor: const Color(0xFF2ECC71),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Heyvanlarım',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${_animals.length} heyvan • $_alertCount xəbərdarlıq',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (_alertCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF4444),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_alertCount alert',
                    style: const TextStyle(
                      color: Color(0xFFFF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_list_rounded,
                size: 20,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final active = _animals.where((a) => a.isTracking).length;
    final inside = _animals
        .where((a) => a.zoneStatus == AnimalZoneStatus.inside)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _summaryCard(
            'Ümumi',
            '${_animals.length}',
            const Color(0xFF6C63FF),
            Icons.pets_rounded,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            'Aktiv',
            '$active',
            const Color(0xFF2ECC71),
            Icons.gps_fixed,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            'İçərdə',
            '$inside',
            const Color(0xFF3498DB),
            Icons.home_rounded,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            'Alert',
            '$_alertCount',
            const Color(0xFFFF4444),
            Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          _filterChip('Hamısı', 'all'),
          const SizedBox(width: 8),
          _filterChip('Aktiv', 'active'),
          const SizedBox(width: 8),
          _filterChip('Alert', 'alert'),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selectedIds.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectMode
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectMode
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                _selectMode ? 'Bitir' : 'Seç',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selectMode
                      ? const Color(0xFF2ECC71)
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2ECC71) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _animalListCard(_filtered[i]),
    );
  }

  Widget _animalListCard(AnimalEntity animal) {
    final isSelected = _selectedIds.contains(animal.id);
    final statusColor = _statusColor(animal.zoneStatus);
    final statusLabel = _statusLabel(animal.zoneStatus);

    return GestureDetector(
      onLongPress: () => setState(() {
        _selectMode = true;
        _selectedIds.add(animal.id);
      }),
      onTap: () {
        if (_selectMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(animal.id);
            } else {
              _selectedIds.add(animal.id);
            }
          });
        } else {
          AppLogger.heyvanEmeliyyati('Detala keçid', animal.name);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : animal.zoneStatus == AnimalZoneStatus.alert
                ? const Color(0xFFFF4444).withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_selectMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2ECC71)
                        : Colors.grey.shade300,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _typeColor(animal.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _typeEmoji(animal.type),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        animal.zoneName ?? 'Zona yoxdur',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatTime(animal.lastUpdate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (animal.batteryLevel != null) ...[
                        Icon(
                          animal.batteryLevel! > 0.2
                              ? Icons.battery_4_bar
                              : Icons.battery_alert,
                          size: 13,
                          color: animal.batteryLevel! > 0.2
                              ? const Color(0xFF2ECC71)
                              : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${(animal.batteryLevel! * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: animal.batteryLevel! > 0.2
                                ? const Color(0xFF2ECC71)
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (animal.speed != null && animal.speed! > 0) ...[
                        Icon(Icons.speed, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(
                          '${animal.speed!.toStringAsFixed(1)} km/s',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: animal.isTracking
                              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: animal.isTracking
                                    ? const Color(0xFF2ECC71)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              animal.isTracking ? 'Canlı' : 'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: animal.isTracking
                                    ? const Color(0xFF2ECC71)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Text('🐄', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          Text(
            'Heyvan tapılmadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAnimal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni heyvan əlavə etmə — hazırlanır'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGroupActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_selectedIds.length} heyvan seçildi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            _actionBtn(
              Icons.map_outlined,
              'Xəritədə göstər',
              const Color(0xFF3498DB),
              () {
                Navigator.pop(context);
                _navigateToMapWithSelected();
              },
            ),
            const SizedBox(height: 10),
            _actionBtn(
              Icons.notifications_outlined,
              'Xəbərdarlıqlar',
              const Color(0xFFFF9800),
              () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            _actionBtn(Icons.clear_rounded, 'Seçimi təmizlə', Colors.grey, () {
              setState(() {
                _selectedIds.clear();
                _selectMode = false;
              });
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToMapWithSelected() {
    final selectedAnimals = _animals
        .where((a) => _selectedIds.contains(a.id))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          highlightedAnimalIds: _selectedIds.toList(),
          animalEntities: selectedAnimals,
        ),
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return const Color(0xFF2ECC71);
      case AnimalZoneStatus.outside:
        return const Color(0xFF3498DB);
      case AnimalZoneStatus.alert:
        return const Color(0xFFFF4444);
    }
  }

  String _statusLabel(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return 'İçərdə';
      case AnimalZoneStatus.outside:
        return 'Xaricdə';
      case AnimalZoneStatus.alert:
        return 'ALERT';
    }
  }

  String _typeEmoji(AnimalType t) {
    switch (t) {
      case AnimalType.cattle:
        return '🐄';
      case AnimalType.sheep:
        return '🐑';
      case AnimalType.horse:
        return '🐎';
      case AnimalType.goat:
        return '🐐';
      case AnimalType.pig:
        return '🐖';
      case AnimalType.other:
        return '🐾';
    }
  }

  Color _typeColor(AnimalType t) {
    switch (t) {
      case AnimalType.cattle:
        return const Color(0xFF8B5E3C);
      case AnimalType.sheep:
        return const Color(0xFF9B9B9B);
      case AnimalType.horse:
        return const Color(0xFF8B4513);
      case AnimalType.goat:
        return const Color(0xFF7B9E5E);
      case AnimalType.pig:
        return const Color(0xFFFF8FAB);
      case AnimalType.other:
        return const Color(0xFF6C63FF);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dq';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }
}
