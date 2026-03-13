import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/presentation/screens/tracking_screen.dart';
import '../../domain/entities/zone.dart';

class MapScreen extends StatefulWidget {
  final List<ZoneEntity>? initialZones;
  final VoidCallback? onZoneCreated;
  final List<String>? highlightedAnimalIds;
  final List<AnimalEntity>? animalEntities;

  const MapScreen({
    super.key,
    this.initialZones,
    this.onZoneCreated,
    this.highlightedAnimalIds,
    this.animalEntities,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  LatLng? _selectedLocation;
  double _radius = 500;
  bool _isCreatingZone = false;
  bool _isFreehandMode = false;
  List<LatLng> _freehandPoints = [];
  String _newZoneName = '';

  final LatLng _defaultLocation = const LatLng(40.3686, 49.8671);

  // Mock animal positions
  static const Map<String, LatLng> _animalPositions = {
    '1': LatLng(40.3686, 49.8671),
    '2': LatLng(40.3700, 49.8680),
    '3': LatLng(40.3720, 49.8690),
    '4': LatLng(40.3710, 49.8660),
  };

  static const Map<String, String> _animalEmojis = {
    '1': '🐄',
    '2': '🐑',
    '3': '🐎',
    '4': '🐐',
  };

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı (MapScreen)');
    _loadInitialZones();
  }

  @override
  void dispose() {
    AppLogger.ekranBaglandi('Xəritə Ekranı (MapScreen)');
    super.dispose();
  }

  void _loadInitialZones() {
    // Default zones
    _addZoneCircle(
      id: 'default-z1',
      name: 'Otlaq-1',
      center: const LatLng(40.3695, 49.8675),
      radius: 400,
      color: Colors.blue,
    );
    _addZoneCircle(
      id: 'default-z2',
      name: 'Otlaq-2',
      center: const LatLng(40.3715, 49.8685),
      radius: 300,
      color: Colors.purple,
    );
    if (widget.initialZones != null) {
      for (final zone in widget.initialZones!) {
        _addZoneFromEntity(zone);
      }
    }
    _addAnimalMarkers();
  }

  void _addZoneCircle({
    required String id,
    required String name,
    required LatLng center,
    required double radius,
    required Color color,
  }) {
    _circles.add(
      Circle(
        circleId: CircleId(id),
        center: center,
        radius: radius,
        fillColor: color.withValues(alpha: 0.15),
        strokeColor: color.withValues(alpha: 0.7),
        strokeWidth: 2,
      ),
    );
    _markers.add(
      Marker(
        markerId: MarkerId('zone-$id'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '📍 $name',
          snippet: 'Radius: ${(radius / 1000).toStringAsFixed(2)} km',
        ),
      ),
    );
  }

  void _addZoneFromEntity(ZoneEntity zone) {
    AppLogger.xeriteEmeliyyati('"${zone.name}" xəritəyə əlavə edilir');
    _addZoneCircle(
      id: zone.id,
      name: zone.name,
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radiusInMeters,
      color: zone.isActive ? Colors.blue : Colors.grey,
    );
  }

  void _addAnimalMarkers() {
    final toShow = widget.highlightedAnimalIds != null
        ? _animalPositions.entries
              .where((e) => widget.highlightedAnimalIds!.contains(e.key))
              .toList()
        : _animalPositions.entries.toList();

    for (final entry in toShow) {
      final animal = widget.animalEntities
          ?.where((a) => a.id == entry.key)
          .firstOrNull;
      final emoji = _animalEmojis[entry.key] ?? '🐾';
      final isHighlighted =
          widget.highlightedAnimalIds?.contains(entry.key) ?? false;

      _markers.add(
        Marker(
          markerId: MarkerId('animal-${entry.key}'),
          position: entry.value,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isHighlighted
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '$emoji ${animal?.name ?? 'Heyvan ${entry.key}'}',
            snippet: [
              if (animal?.zoneName != null) '📍 ${animal!.zoneName}',
              if (animal?.batteryLevel != null)
                '🔋 ${(animal!.batteryLevel! * 100).toInt()}%',
              if (animal?.speed != null && animal!.speed! > 0)
                '⚡ ${animal.speed!.toStringAsFixed(1)} km/s',
            ].join(' | '),
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void _onMapTap(LatLng location) {
    if (_isFreehandMode) return;
    if (!_isCreatingZone) {
      AppLogger.debug(
        'XƏRİTƏ',
        'Xəritəyə toxunuldu (zona yaratma rejimi aktiv deyil)',
      );
      return;
    }

    AppLogger.xeriteEmeliyyati(
      'Zona üçün mövqe seçildi',
      data:
          'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}',
    );

    setState(() {
      _selectedLocation = location;
    });
    _updatePreviewCircle();
  }

  void _updatePreviewCircle() {
    _circles.removeWhere((c) => c.circleId.value == 'preview');
    if (_selectedLocation != null) {
      _circles.add(
        Circle(
          circleId: const CircleId('preview'),
          center: _selectedLocation!,
          radius: _radius,
          fillColor: Colors.red.withValues(alpha: 0.1),
          strokeColor: Colors.red.withValues(alpha: 0.6),
          strokeWidth: 2,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void _onMapLongPress(LatLng location) {
    if (_isFreehandMode) {
      setState(() {
        _freehandPoints = [location];
      });
    }
  }

  void _createZone() {
    if (_selectedLocation == null) {
      AppLogger.xeberdarliq('XƏRİTƏ', 'Zona yaratma cəhdi: mövqe seçilməyib');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfən xəritə üzərində ərazini seçin')),
      );
      return;
    }
    _showZoneNameDialog(isRadius: true);
  }

  void _createFreehandZone() {
    if (_freehandPoints.length < 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ən az 3 nöqtə seçin')));
      return;
    }
    _showZoneNameDialog(isRadius: false);
  }

  void _showZoneNameDialog({required bool isRadius}) {
    final controller = TextEditingController(
      text: 'Zona ${DateTime.now().millisecondsSinceEpoch % 1000}',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Zona Adı',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Otlaq-3',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İmtina', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _newZoneName = controller.text.trim().isEmpty
                  ? 'Yeni Zona'
                  : controller.text.trim();
              if (isRadius) {
                _finalizeRadiusZone();
              } else {
                _finalizeFreehandZone();
              }
            },
            child: const Text(
              'Yarat',
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finalizeRadiusZone() {
    AppLogger.zonaEmeliyyati(
      'Yeni radius zonası yaradıldı',
      _newZoneName,
      data: 'Radius: ${(_radius / 1000).toStringAsFixed(2)}km',
    );

    _circles.removeWhere((c) => c.circleId.value == 'preview');
    _addZoneCircle(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: _newZoneName,
      center: _selectedLocation!,
      radius: _radius,
      color: Colors.green,
    );
    widget.onZoneCreated?.call();
    setState(() {
      _selectedLocation = null;
      _isCreatingZone = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$_newZoneName" zonası uğurla yaradıldı'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2ECC71),
      ),
    );
  }

  void _finalizeFreehandZone() {
    AppLogger.zonaEmeliyyati(
      'Əl ilə zona yaradıldı',
      _newZoneName,
      data: '${_freehandPoints.length} nöqtə',
    );

    final polygonId = PolygonId(
      'freehand-${DateTime.now().millisecondsSinceEpoch}',
    );
    _polygons.add(
      Polygon(
        polygonId: polygonId,
        points: _freehandPoints,
        fillColor: Colors.green.withValues(alpha: 0.15),
        strokeColor: Colors.green.withValues(alpha: 0.7),
        strokeWidth: 2,
      ),
    );

    // Center marker
    final centerLat =
        _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        _freehandPoints.length;
    final centerLon =
        _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        _freehandPoints.length;
    _markers.add(
      Marker(
        markerId: MarkerId(
          'zone-freehand-${DateTime.now().millisecondsSinceEpoch}',
        ),
        position: LatLng(centerLat, centerLon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '✏ $_newZoneName',
          snippet: 'Azad çəkilmiş zona',
        ),
      ),
    );

    setState(() {
      _freehandPoints = [];
      _isFreehandMode = false;
      _isCreatingZone = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$_newZoneName" zonası uğurla yaradıldı'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2ECC71),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Heyvan İzləmə Xəritəsi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (widget.highlightedAnimalIds != null &&
                widget.highlightedAnimalIds!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.highlightedAnimalIds!.length} seçildi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isCreatingZone || _isFreehandMode)
            TextButton(
              onPressed: _cancelDraw,
              child: const Text(
                'İmtina',
                style: TextStyle(color: Color(0xFFFF4444)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              AppLogger.ugur('XƏRİTƏ', 'Google Maps kontroler hazır');
            },
            circles: _circles,
            markers: _markers,
            polygons: _polygons,
            onTap: _onMapTap,
            onLongPress: _onMapLongPress,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top info banner when creating
          if (_isCreatingZone && !_isFreehandMode)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedLocation == null
                          ? 'Xəritəyə toxunun — mərkəz seçin'
                          : 'Mövqe seçildi. Radiusu tənzimləyin.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          if (_isFreehandMode)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.draw, color: Color(0xFF4CAF50), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Xəritə üzərindən nöqtələri seçin (ən az 3)',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${_freehandPoints.length} nöqtə',
                      style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right controls
          Positioned(
            top: 70,
            right: 12,
            child: Column(
              children: [
                _mapControlBtn(Icons.add, () {
                  mapController?.animateCamera(CameraUpdate.zoomIn());
                }),
                const SizedBox(height: 8),
                _mapControlBtn(Icons.remove, () {
                  mapController?.animateCamera(CameraUpdate.zoomOut());
                }),
                const SizedBox(height: 8),
                _mapControlBtn(Icons.my_location, () {
                  mapController?.animateCamera(
                    CameraUpdate.newLatLng(_defaultLocation),
                  );
                }),
              ],
            ),
          ),

          // Bottom panel
          if (_isCreatingZone || _isFreehandMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    const SizedBox(height: 12),
                    // Mode tabs
                    Row(
                      children: [
                        _drawModeTab(
                          '⊙ Radius',
                          !_isFreehandMode,
                          () => setState(() {
                            _isFreehandMode = false;
                            _isCreatingZone = true;
                          }),
                        ),
                        const SizedBox(width: 10),
                        _drawModeTab(
                          '✏ Azad Çiz',
                          _isFreehandMode,
                          () => setState(() {
                            _isFreehandMode = true;
                            _isCreatingZone = false;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_isFreehandMode) ...[
                      Row(
                        children: [
                          const Text(
                            'Radius:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: _radius,
                              min: 100,
                              max: 5000,
                              divisions: 49,
                              activeColor: const Color(0xFF2ECC71),
                              label:
                                  '${(_radius / 1000).toStringAsFixed(2)} km',
                              onChanged: (value) {
                                setState(() => _radius = value);
                                _updatePreviewCircle();
                              },
                            ),
                          ),
                          Text(
                            '${(_radius / 1000).toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2ECC71),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Xəritəyə toxunaraq zona nöqtələrini seçin',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cancelDraw,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('İmtina'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isFreehandMode
                                ? _createFreehandZone
                                : _createZone,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Təsdiq Et'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // FAB to start creating zone (shown when not in draw mode)
          if (!_isCreatingZone && !_isFreehandMode)
            Positioned(
              bottom: 20,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'fab_freehand',
                    onPressed: () {
                      AppLogger.melumat(
                        'XƏRİTƏ',
                        'Azad çizmə rejimi aktivləşdi',
                      );
                      setState(() {
                        _isFreehandMode = true;
                        _isCreatingZone = false;
                      });
                    },
                    backgroundColor: const Color(0xFF9B59B6),
                    foregroundColor: Colors.white,
                    tooltip: 'Azad Zona Çiz',
                    child: const Icon(Icons.draw, size: 18),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'fab_radius',
                    onPressed: () {
                      AppLogger.melumat(
                        'XƏRİTƏ',
                        'Radius zona yaratma rejimi aktivləşdi',
                      );
                      setState(() {
                        _isCreatingZone = true;
                        _isFreehandMode = false;
                      });
                    },
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    tooltip: 'Radius Zona Əlavə Et',
                    child: const Icon(Icons.add_location_alt),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapControlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _drawModeTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFF2ECC71) : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF2ECC71) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  void _cancelDraw() {
    AppLogger.melumat('XƏRİTƏ', 'Zona yaratma ləğv edildi');
    _circles.removeWhere((c) => c.circleId.value == 'preview');
    setState(() {
      _selectedLocation = null;
      _isCreatingZone = false;
      _isFreehandMode = false;
      _freehandPoints = [];
    });
  }
}
