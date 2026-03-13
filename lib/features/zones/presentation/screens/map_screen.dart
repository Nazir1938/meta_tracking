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

// Draw modes
enum _DrawMode { none, radius, freehand }

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  // Zone drawing state
  _DrawMode _drawMode = _DrawMode.none;
  LatLng? _radiusCenter;
  double _radius = 500;
  final List<LatLng> _freehandPoints = [];

  final LatLng _defaultLocation = const LatLng(40.3686, 49.8671);

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
    AppLogger.ekranAcildi('Xəritə Ekranı');
    _loadDefaults();
  }

  @override
  void dispose() {
    AppLogger.ekranBaglandi('Xəritə Ekranı');
    super.dispose();
  }

  // ── Default zones + animals ───────────────────────────────────────────────

  void _loadDefaults() {
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
    for (final zone in (widget.initialZones ?? [])) {
      _addZoneCircle(
        id: zone.id,
        name: zone.name,
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radiusInMeters,
        color: zone.isActive ? Colors.blue : Colors.grey,
      );
    }
    _refreshAnimalMarkers();
  }

  void _addZoneCircle({
    required String id,
    required String name,
    required LatLng center,
    required double radius,
    required Color color,
  }) {
    _circles.add(Circle(
      circleId: CircleId(id),
      center: center,
      radius: radius,
      fillColor: color.withValues(alpha: 0.18),
      strokeColor: color.withValues(alpha: 0.8),
      strokeWidth: 2,
    ));
    _markers.add(Marker(
      markerId: MarkerId('zone-lbl-$id'),
      position: center,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        color == Colors.blue
            ? BitmapDescriptor.hueBlue
            : color == Colors.purple
                ? BitmapDescriptor.hueViolet
                : color == Colors.green
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueCyan,
      ),
      infoWindow: InfoWindow(
        title: '📍 $name',
        snippet: 'Radius: ${(radius / 1000).toStringAsFixed(2)} km',
      ),
    ));
  }

  void _refreshAnimalMarkers() {
    _markers.removeWhere((m) => m.markerId.value.startsWith('animal-'));
    final showAll = widget.highlightedAnimalIds == null ||
        widget.highlightedAnimalIds!.isEmpty;
    for (final entry in _animalPositions.entries) {
      if (!showAll && !widget.highlightedAnimalIds!.contains(entry.key))
        continue;
      final animal =
          widget.animalEntities?.where((a) => a.id == entry.key).firstOrNull;
      final isHL = widget.highlightedAnimalIds?.contains(entry.key) ?? false;
      _markers.add(Marker(
        markerId: MarkerId('animal-${entry.key}'),
        position: entry.value,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isHL ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title:
              '${_animalEmojis[entry.key] ?? '🐾'} ${animal?.name ?? 'Heyvan ${entry.key}'}',
          snippet: [
            if (animal?.zoneName != null) '📍 ${animal!.zoneName}',
            if (animal?.batteryLevel != null)
              '🔋 ${(animal!.batteryLevel! * 100).toInt()}%',
            if (animal?.speed != null && (animal?.speed ?? 0) > 0)
              '⚡ ${animal?.speed!.toStringAsFixed(1)} km/s',
          ].join(' | '),
        ),
      ));
    }
    if (mounted) setState(() {});
  }

  // ── Map interactions ──────────────────────────────────────────────────────

  void _onMapTap(LatLng loc) {
    switch (_drawMode) {
      case _DrawMode.none:
        return;
      case _DrawMode.radius:
        // Every tap sets the centre and redraws preview
        setState(() => _radiusCenter = loc);
        _redrawPreview();
        AppLogger.xeriteEmeliyyati('Radius mərkəzi seçildi',
            data:
                'Lat: ${loc.latitude.toStringAsFixed(4)}, Lon: ${loc.longitude.toStringAsFixed(4)}');
      case _DrawMode.freehand:
        // Each tap adds a polygon vertex
        setState(() => _freehandPoints.add(loc));
        _redrawFreehandPreview();
        AppLogger.xeriteEmeliyyati(
            'Nöqtə əlavə edildi: ${_freehandPoints.length}');
    }
  }

  void _redrawPreview() {
    _circles.removeWhere((c) => c.circleId.value == '__preview__');
    if (_radiusCenter != null) {
      _circles.add(Circle(
        circleId: const CircleId('__preview__'),
        center: _radiusCenter!,
        radius: _radius,
        fillColor: Colors.red.withValues(alpha: 0.12),
        strokeColor: Colors.red.withValues(alpha: 0.7),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void _redrawFreehandPreview() {
    _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    if (_freehandPoints.length >= 2) {
      _polygons.add(Polygon(
        polygonId: const PolygonId('__fh_preview__'),
        points: _freehandPoints,
        fillColor: Colors.green.withValues(alpha: 0.15),
        strokeColor: Colors.green.withValues(alpha: 0.8),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  // ── Confirm / cancel draw ─────────────────────────────────────────────────

  void _confirmDraw() {
    if (_drawMode == _DrawMode.radius) {
      if (_radiusCenter == null) {
        _showSnack('Lütfən xəritəyə toxunaraq mərkəz seçin', isError: true);
        return;
      }
      _promptZoneName((name) {
        _circles.removeWhere((c) => c.circleId.value == '__preview__');
        _addZoneCircle(
          id: 'z-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          center: _radiusCenter!,
          radius: _radius,
          color: Colors.green,
        );
        AppLogger.zonaEmeliyyati('Radius zona yaradıldı', name,
            data: 'R=${(_radius / 1000).toStringAsFixed(2)}km');
        widget.onZoneCreated?.call();
        _resetDraw();
        _showSnack('"$name" uğurla yaradıldı');
      });
    } else if (_drawMode == _DrawMode.freehand) {
      if (_freehandPoints.length < 3) {
        _showSnack('Ən az 3 nöqtə seçin', isError: true);
        return;
      }
      _promptZoneName((name) {
        _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
        _polygons.add(Polygon(
          polygonId: PolygonId('fh-${DateTime.now().millisecondsSinceEpoch}'),
          points: List.from(_freehandPoints),
          fillColor: Colors.green.withValues(alpha: 0.18),
          strokeColor: Colors.green.withValues(alpha: 0.8),
          strokeWidth: 2,
        ));
        // Centre marker
        final lat =
            _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        final lon =
            _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        _markers.add(Marker(
          markerId:
              MarkerId('zone-lbl-fh-${DateTime.now().millisecondsSinceEpoch}'),
          position: LatLng(lat, lon),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: '✏ $name', snippet: 'Azad zona'),
        ));
        AppLogger.zonaEmeliyyati('Azad zona yaradıldı', name,
            data: '${_freehandPoints.length} nöqtə');
        widget.onZoneCreated?.call();
        _resetDraw();
        _showSnack('"$name" uğurla yaradıldı');
      });
    }
  }

  void _cancelDraw() {
    AppLogger.melumat('XƏRİTƏ', 'Zona yaratma ləğv edildi');
    _circles.removeWhere((c) => c.circleId.value == '__preview__');
    _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    _resetDraw();
  }

  void _resetDraw() {
    setState(() {
      _drawMode = _DrawMode.none;
      _radiusCenter = null;
      _freehandPoints.clear();
    });
  }

  void _promptZoneName(void Function(String name) onConfirm) {
    final ctrl = TextEditingController(
        text: 'Zona-${DateTime.now().millisecondsSinceEpoch % 1000}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Zona adı',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
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
              final name =
                  ctrl.text.trim().isEmpty ? 'Yeni Zona' : ctrl.text.trim();
              onConfirm(name);
            },
            child: const Text('Yarat',
                style: TextStyle(
                    color: Color(0xFF2ECC71), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF2ECC71),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDrawing = _drawMode != _DrawMode.none;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Heyvan İzləmə Xəritəsi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (widget.highlightedAnimalIds != null &&
              widget.highlightedAnimalIds!.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${widget.highlightedAnimalIds!.length} seçildi',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50))),
            ),
          ],
        ]),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isDrawing)
            TextButton(
              onPressed: _cancelDraw,
              child: const Text('İmtina',
                  style: TextStyle(color: Color(0xFFFF4444))),
            ),
        ],
      ),
      body: Stack(children: [
        // ── Google Map ────────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: _defaultLocation, zoom: 14),
          onMapCreated: (c) {
            _mapController = c;
            AppLogger.ugur('XƏRİTƏ', 'Google Maps kontroler hazır');
          },
          circles: Set.from(_circles),
          markers: Set.from(_markers),
          polygons: Set.from(_polygons),
          onTap: _onMapTap,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        // ── Info banner (drawing mode) ────────────────────────────────────
        if (isDrawing)
          Positioned(
            top: 12,
            left: 12,
            right: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                  _drawMode == _DrawMode.radius
                      ? Icons.touch_app
                      : Icons.touch_app,
                  color: const Color(0xFF4CAF50),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  _drawMode == _DrawMode.radius
                      ? (_radiusCenter == null
                          ? 'Xəritəyə toxunun — mərkəz seçin'
                          : '✓ Mərkəz seçildi. Radiusu tənzimləyin, sonra Təsdiq et.')
                      : 'Hər toxunuşda nöqtə əlavə edilir  (${_freehandPoints.length} nöqtə)',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                )),
              ]),
            ),
          ),

        // ── Zoom + locate controls ────────────────────────────────────────
        Positioned(
          top: isDrawing ? 70 : 12,
          right: 12,
          child: Column(children: [
            _ctrl(Icons.add,
                () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
            const SizedBox(height: 8),
            _ctrl(Icons.remove,
                () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
            const SizedBox(height: 8),
            _ctrl(
                Icons.my_location,
                () => _mapController
                    ?.animateCamera(CameraUpdate.newLatLng(_defaultLocation))),
          ]),
        ),

        // ── Bottom draw panel ─────────────────────────────────────────────
        if (isDrawing)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16)
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 12),

                // Mode tabs
                Row(children: [
                  _modeTab(
                      '⊙  Radius',
                      _drawMode == _DrawMode.radius,
                      () => setState(() {
                            _cancelDraw();
                            _drawMode = _DrawMode.radius;
                          })),
                  const SizedBox(width: 10),
                  _modeTab(
                      '✏  Azad Çiz',
                      _drawMode == _DrawMode.freehand,
                      () => setState(() {
                            _cancelDraw();
                            _drawMode = _DrawMode.freehand;
                          })),
                ]),
                const SizedBox(height: 14),

                // Radius slider
                if (_drawMode == _DrawMode.radius)
                  Row(children: [
                    const Text('Radius:',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 100,
                        max: 5000,
                        divisions: 49,
                        activeColor: const Color(0xFF2ECC71),
                        label: '${(_radius / 1000).toStringAsFixed(2)} km',
                        onChanged: (v) {
                          setState(() => _radius = v);
                          _redrawPreview();
                        },
                      ),
                    ),
                    Text('${(_radius / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2ECC71))),
                  ]),

                // Freehand hint
                if (_drawMode == _DrawMode.freehand)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Xəritəyə toxunaraq köşə nöqtələrini əlavə edin.\n'
                      'Ən az 3 nöqtə lazımdır. (Seçilmiş: ${_freehandPoints.length})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 10),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelDraw,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('İmtina'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmDraw,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Təsdiq Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),

        // ── FABs (idle mode) ──────────────────────────────────────────────
        if (!isDrawing)
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FloatingActionButton.small(
                heroTag: 'fab_fh',
                onPressed: () {
                  AppLogger.melumat('XƏRİTƏ', 'Azad çizmə rejimi aktivləşdi');
                  setState(() => _drawMode = _DrawMode.freehand);
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
                      'XƏRİTƏ', 'Radius zona yaratma rejimi aktivləşdi');
                  setState(() => _drawMode = _DrawMode.radius);
                },
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                tooltip: 'Radius Zona',
                child: const Icon(Icons.add_location_alt),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _ctrl(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
        ),
      );

  Widget _modeTab(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? const Color(0xFF2ECC71) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? const Color(0xFF2ECC71) : Colors.grey[600])),
          ),
        ),
      );
}
