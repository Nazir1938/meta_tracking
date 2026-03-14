import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

enum _DrawMode { none, radius, freehand }

class MapScreen extends StatefulWidget {
  /// Xəritədə vurğulanacaq heyvan ID-ləri
  final List<String>? highlightedAnimalIds;

  /// Xəritədə marker kimi göstəriləcək heyvanlar
  final List<AnimalEntity>? animalEntities;

  const MapScreen({
    super.key,
    this.highlightedAnimalIds,
    this.animalEntities,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Xəritə ──────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  // ── Çizmə rejimi ────────────────────────────────────────────────────────────
  _DrawMode _drawMode = _DrawMode.none;
  LatLng? _radiusCenter;
  double _radius = 500;
  final List<LatLng> _freehandPoints = [];

  // ── GPS ──────────────────────────────────────────────────────────────────────
  LatLng? _currentLocation;
  StreamSubscription<Position>? _locationSub;
  bool _locationReady = false;

  static const LatLng _defaultLocation = LatLng(40.3686, 49.8671); // Bakı

  // ── Zone panel state ─────────────────────────────────────────────────────────
  bool _showZoneList = false;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı');
    _initLocation();
    // Zonaları BLoC-dan yüklə
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneBloc>().add(const LoadZonesEvent());
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    AppLogger.ekranBaglandi('Xəritə Ekranı');
    super.dispose();
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _locationReady = true;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
        AppLogger.ugur('XƏRİTƏ GPS',
            'Mövqe alındı: ${pos.latitude}, ${pos.longitude}');

        _locationSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(
              () => _currentLocation = LatLng(pos.latitude, pos.longitude));
        });
      } else {
        AppLogger.xeberdarliq('XƏRİTƏ GPS', 'GPS icazəsi yoxdur');
      }
    } catch (e) {
      AppLogger.xeta('XƏRİTƏ GPS', 'GPS xətası', xetaObyekti: e);
    }
  }

  // ── Zona dairələrini BLoC state-dən yenilə ──────────────────────────────────

  void _rebuildZoneOverlays(List<ZoneEntity> zones) {
    // Yalnız zona overlay-larını təmizlə, heyvan markerlarını saxla
    _circles.clear();
    _markers.removeWhere((m) => m.markerId.value.startsWith('zone-'));

    for (final zone in zones) {
      _addZoneOverlay(zone);
    }

    // Heyvan markerlərini yenidən əlavə et
    _rebuildAnimalMarkers();

    if (mounted) setState(() {});
    AppLogger.melumat('XƏRİTƏ', 'Zona overlay-ları yeniləndi: ${zones.length}');
  }

  void _addZoneOverlay(ZoneEntity zone) {
    final color =
        zone.isActive ? const Color(0xFF2ECC71) : Colors.grey;

    _circles.add(Circle(
      circleId: CircleId('zone-circle-${zone.id}'),
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radiusInMeters,
      fillColor: color.withValues(alpha: 0.15),
      strokeColor: color.withValues(alpha: 0.75),
      strokeWidth: 2,
    ));

    _markers.add(Marker(
      markerId: MarkerId('zone-label-${zone.id}'),
      position: LatLng(zone.latitude, zone.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        zone.isActive
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueAzure,
      ),
      infoWindow: InfoWindow(
        title: '📍 ${zone.name}',
        snippet:
            'Radius: ${(zone.radiusInMeters / 1000).toStringAsFixed(2)} km'
            '${zone.isActive ? '' : ' • Deaktiv'}',
      ),
    ));
  }

  void _rebuildAnimalMarkers() {
    if (widget.animalEntities == null) return;
    for (final animal in widget.animalEntities!) {
      if (animal.lastLatitude == null || animal.lastLongitude == null) continue;
      final isHL =
          widget.highlightedAnimalIds?.contains(animal.id) ?? false;

      _markers.add(Marker(
        markerId: MarkerId('animal-${animal.id}'),
        position: LatLng(animal.lastLatitude!, animal.lastLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isHL ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: '${animal.typeEmoji} ${animal.name}',
          snippet: [
            if (animal.zoneName != null) '📍 ${animal.zoneName}',
            if (animal.batteryLevel != null)
              '🔋 ${(animal.batteryLevel! * 100).toInt()}%',
          ].join(' | '),
        ),
      ));
    }
  }

  // ── Çizmə ───────────────────────────────────────────────────────────────────

  void _onMapTap(LatLng loc) {
    if (_drawMode == _DrawMode.none) return;

    if (_drawMode == _DrawMode.radius) {
      setState(() => _radiusCenter = loc);
      _redrawRadiusPreview();
    } else {
      setState(() => _freehandPoints.add(loc));
      _redrawFreehandPreview();
    }
  }

  void _redrawRadiusPreview() {
    _circles.removeWhere((c) => c.circleId.value == '__preview__');
    if (_radiusCenter != null) {
      _circles.add(Circle(
        circleId: const CircleId('__preview__'),
        center: _radiusCenter!,
        radius: _radius,
        fillColor: Colors.red.withValues(alpha: 0.10),
        strokeColor: Colors.red.withValues(alpha: 0.65),
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
        fillColor: Colors.green.withValues(alpha: 0.12),
        strokeColor: Colors.green.withValues(alpha: 0.75),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void _confirmDraw() {
    if (_drawMode == _DrawMode.radius) {
      if (_radiusCenter == null) {
        _showSnack('Lütfən xəritəyə toxunaraq mərkəz seçin', isError: true);
        return;
      }
      _promptZoneName((name, desc) {
        _circles.removeWhere((c) => c.circleId.value == '__preview__');
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: _radiusCenter!.latitude,
              longitude: _radiusCenter!.longitude,
              radiusInMeters: _radius,
              description: desc,
            ));
        AppLogger.zonaEmeliyyati('Radius zona BLoC-a göndərildi', name);
        _resetDraw();
      });
    } else if (_drawMode == _DrawMode.freehand) {
      if (_freehandPoints.length < 3) {
        _showSnack('Ən az 3 nöqtə seçin', isError: true);
        return;
      }
      _promptZoneName((name, desc) {
        _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');

        // Azad zona üçün mərkəzi hesabla
        final lat =
            _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        final lon =
            _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                _freehandPoints.length;

        // Ortalama "radius" hesabla
        double maxDist = 0;
        for (final p in _freehandPoints) {
          final d =
              ((p.latitude - lat) * (p.latitude - lat) +
                      (p.longitude - lon) * (p.longitude - lon)) *
                  111000; // approximate meters
          if (d > maxDist) maxDist = d;
        }

        // Polygon-u xəritəyə əlavə et (vizual)
        final polyId =
            'fh-${DateTime.now().millisecondsSinceEpoch}';
        _polygons.add(Polygon(
          polygonId: PolygonId(polyId),
          points: List.from(_freehandPoints),
          fillColor: const Color(0xFF2ECC71).withValues(alpha: 0.15),
          strokeColor: const Color(0xFF2ECC71).withValues(alpha: 0.8),
          strokeWidth: 2,
        ));

        // BLoC-a göndər (mərkəz + hesablanmış radius)
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: lat,
              longitude: lon,
              radiusInMeters: maxDist > 0 ? maxDist : 300,
              description: desc,
            ));

        AppLogger.zonaEmeliyyati('Azad zona BLoC-a göndərildi', name,
            data: '${_freehandPoints.length} nöqtə');
        _resetDraw();
      });
    }
  }

  void _cancelDraw() {
    _circles.removeWhere((c) => c.circleId.value == '__preview__');
    _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    _resetDraw();
    AppLogger.melumat('XƏRİTƏ', 'Zona yaratma ləğv edildi');
  }

  void _resetDraw() => setState(() {
        _drawMode = _DrawMode.none;
        _radiusCenter = null;
        _freehandPoints.clear();
      });

  void _goToMyLocation() {
    final target = _currentLocation ?? _defaultLocation;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    AppLogger.xeriteEmeliyyati('Mənim mövqeyimə getdi');
  }

  // ── Dialoqular ───────────────────────────────────────────────────────────────

  void _promptZoneName(void Function(String name, String? desc) onConfirm) {
    final nameCtrl = TextEditingController(
        text: 'Zona-${DateTime.now().millisecondsSinceEpoch % 1000}');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Zona adı',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Ad *',
              hintText: 'Otlaq-1',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF2ECC71), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl,
            decoration: InputDecoration(
              labelText: 'Açıqlama (ixtiyari)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF2ECC71), width: 1.5),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İmtina', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final name = nameCtrl.text.trim().isEmpty
                  ? 'Yeni Zona'
                  : nameCtrl.text.trim();
              final desc = descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim();
              onConfirm(name, desc);
            },
            child: const Text('Yarat',
                style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ZoneEntity zone) {
    final nameCtrl = TextEditingController(text: zone.name);
    final descCtrl = TextEditingController(text: zone.description ?? '');
    double radius = zone.radiusInMeters;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Zonayı Redaktə Et',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Ad *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2ECC71), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Açıqlama (ixtiyari)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2ECC71), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Radius:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: radius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: const Color(0xFF2ECC71),
                  label: '${(radius / 1000).toStringAsFixed(2)} km',
                  onChanged: (v) => setDlg(() => radius = v),
                ),
              ),
              Text('${(radius / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2ECC71))),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('İmtina', style: TextStyle(color: Colors.grey[500])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ZoneBloc>().add(UpdateZoneEvent(
                      zone.copyWith(
                        name: nameCtrl.text.trim().isEmpty
                            ? zone.name
                            : nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        radiusInMeters: radius,
                      ),
                    ));
              },
              child: const Text('Yadda Saxla',
                  style: TextStyle(
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ZoneEntity zone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Zonayı Sil',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          '"${zone.name}" zonasını silmək istədiyinizdən əminsiniz?\nBu əməliyyat geri qaytarıla bilməz.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İmtina', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ZoneBloc>()
                  .add(DeleteZoneEvent(zone.id));
            },
            child: const Text('Sil',
                style: TextStyle(
                    color: Color(0xFFFF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          isError ? Colors.red[700] : const Color(0xFF2ECC71),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ZoneBloc, ZoneState>(
      // ZonesLoaded gəldikdə overlay-ları yenilə
      listenWhen: (prev, curr) =>
          curr is ZonesLoaded ||
          curr is ZoneOperationSuccess ||
          curr is ZoneError,
      listener: (context, state) {
        if (state is ZonesLoaded) {
          _rebuildZoneOverlays(state.zones);
        }
        if (state is ZoneOperationSuccess) {
          _showSnack(state.message);
        }
        if (state is ZoneError) {
          _showSnack(state.message, isError: true);
        }
      },
      buildWhen: (prev, curr) => curr is ZonesLoaded || curr is ZoneLoading,
      builder: (context, state) {
        final zones = state is ZonesLoaded ? state.zones : <ZoneEntity>[];
        final isDrawing = _drawMode != _DrawMode.none;

        return Scaffold(
          body: Stack(children: [
            // ── Google Xəritə ──────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? _defaultLocation,
                zoom: 14,
              ),
              onMapCreated: (c) {
                _mapController = c;
                AppLogger.ugur('XƏRİTƏ', 'Google Maps hazır');
                if (_currentLocation != null) {
                  c.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation!, 15));
                }
                // İlkin overlay
                _rebuildZoneOverlays(zones);
              },
              circles: Set.from(_circles),
              markers: Set.from(_markers),
              polygons: Set.from(_polygons),
              onTap: _onMapTap,
              myLocationEnabled: _locationReady,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ── AppBar ─────────────────────────────────────────────────────
            _buildAppBar(isDrawing, zones.length),

            // ── GPS yüklənir ───────────────────────────────────────────────
            if (!_locationReady)
              _buildInfoBanner(
                top: MediaQuery.of(context).padding.top + 68,
                child: const Row(children: [
                  SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2ECC71))),
                  SizedBox(width: 10),
                  Text('GPS mövqeyi tapılır...',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),

            // ── Çizmə rejimi banneri ───────────────────────────────────────
            if (isDrawing)
              _buildInfoBanner(
                top: MediaQuery.of(context).padding.top + 68,
                child: Row(children: [
                  const Icon(Iconsax.location_add,
                      color: Color(0xFF2ECC71), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _drawMode == _DrawMode.radius
                          ? (_radiusCenter == null
                              ? 'Xəritəyə toxunun — mərkəz seçin'
                              : '✓ Mərkəz seçildi. Radiusu tənzimləyin.')
                          : 'Nöqtə əlavə edin (${_freehandPoints.length} seçildi)',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ]),
              ),

            // ── Sağ tərəf kontrol düymələri ────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  (isDrawing ? 120 : 70),
              right: 12,
              child: Column(children: [
                _mapCtrlBtn(Iconsax.add_square,
                    () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 8),
                _mapCtrlBtn(Icons.remove_rounded,
                    () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                const SizedBox(height: 8),
                _mapCtrlBtn(
                  Iconsax.location,
                  _goToMyLocation,
                  color: _locationReady
                      ? const Color(0xFF2ECC71)
                      : Colors.grey,
                ),
                if (!isDrawing) ...[
                  const SizedBox(height: 8),
                  _mapCtrlBtn(
                    _showZoneList ? Iconsax.close_circle : Iconsax.map,
                    () => setState(() => _showZoneList = !_showZoneList),
                    color: _showZoneList
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFF1A1A2E),
                  ),
                ],
              ]),
            ),

            // ── Zona siyahısı paneli ───────────────────────────────────────
            if (_showZoneList && !isDrawing) _buildZoneListPanel(zones),

            // ── Alt çizmə paneli ───────────────────────────────────────────
            if (isDrawing) _buildDrawPanel(),

            // ── FAB-lar (normal rejim) ─────────────────────────────────────
            if (!isDrawing && !_showZoneList)
              Positioned(
                bottom: 20,
                right: 16,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FloatingActionButton.small(
                    heroTag: 'fab_fh',
                    onPressed: () =>
                        setState(() => _drawMode = _DrawMode.freehand),
                    backgroundColor: const Color(0xFF9B59B6),
                    foregroundColor: Colors.white,
                    tooltip: 'Azad Zona Çiz',
                    child: const Icon(Iconsax.edit, size: 18),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'fab_radius',
                    onPressed: () =>
                        setState(() => _drawMode = _DrawMode.radius),
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    tooltip: 'Radius Zona',
                    child: const Icon(Iconsax.location_add),
                  ),
                ]),
              ),
          ]),
        );
      },
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDrawing, int zoneCount) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF0A1628),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 8,
          bottom: 10,
        ),
        child: Row(children: [
          const Icon(Iconsax.map, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Heyvan Xəritəsi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          // Seçilmiş heyvan sayı
          if (widget.highlightedAnimalIds != null &&
              widget.highlightedAnimalIds!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF4CAF50).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.highlightedAnimalIds!.length} heyvan',
                style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          // Zona sayı badge
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$zoneCount zona',
              style: const TextStyle(
                  color: Color(0xFF2ECC71),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          // GPS indicator
          if (_locationReady)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                const Text('GPS',
                    style: TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          if (isDrawing) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: _cancelDraw,
              child: const Text('İmtina',
                  style: TextStyle(
                      color: Color(0xFFFF4444),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildInfoBanner({required double top, required Widget child}) {
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  /// Sağ tərəfdəki zona siyahısı paneli
  Widget _buildZoneListPanel(List<ZoneEntity> zones) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      right: 58,
      child: Container(
        width: 220,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1628),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Iconsax.location, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                'Zonalar (${zones.length})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          if (zones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hələ zona yoxdur.\nAşağıdakı düymədən əlavə edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: zones.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (_, i) => _buildZoneListTile(zones[i]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildZoneListTile(ZoneEntity zone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(children: [
        // Aktiv toggle
        GestureDetector(
          onTap: () => context.read<ZoneBloc>().add(
                ToggleZoneActiveEvent(
                    zoneId: zone.id, isActive: !zone.isActive),
              ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: zone.isActive
                  ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: zone.isActive
                    ? const Color(0xFF2ECC71)
                    : Colors.grey.shade300,
              ),
            ),
            child: Icon(
              zone.isActive ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: zone.isActive
                  ? const Color(0xFF2ECC71)
                  : Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Xəritədə fokusla
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(zone.latitude, zone.longitude),
                  15,
                ),
              );
            },
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${(zone.radiusInMeters / 1000).toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ]),
          ),
        ),
        // Redaktə
        GestureDetector(
          onTap: () => _showEditDialog(zone),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Iconsax.edit_2, size: 14, color: Colors.grey[600]),
          ),
        ),
        // Sil
        GestureDetector(
          onTap: () => _confirmDelete(zone),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Iconsax.trash, size: 14, color: Color(0xFFFF4444)),
          ),
        ),
      ]),
    );
  }

  Widget _buildDrawPanel() {
    return Positioned(
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
                blurRadius: 16),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          // Rejim tabları
          Row(children: [
            _modeTab('⊙  Radius', _drawMode == _DrawMode.radius, () {
              _cancelDraw();
              setState(() => _drawMode = _DrawMode.radius);
            }),
            const SizedBox(width: 10),
            _modeTab('✏  Azad Çiz', _drawMode == _DrawMode.freehand, () {
              _cancelDraw();
              setState(() => _drawMode = _DrawMode.freehand);
            }),
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
                    _redrawRadiusPreview();
                  },
                ),
              ),
              Text(
                '${(_radius / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2ECC71)),
              ),
            ]),
          // Azad çizmə hint
          if (_drawMode == _DrawMode.freehand)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Xəritəyə toxunaraq köşə nöqtələrini əlavə edin.\n'
                'Ən az 3 nöqtə lazımdır. (${_freehandPoints.length} seçildi)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
          // Düymələr
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelDraw,
                icon: const Icon(Iconsax.close_circle, size: 16),
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
                icon: const Icon(Iconsax.tick_circle, size: 16),
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
    );
  }

  Widget _mapCtrlBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6),
          ],
        ),
        child: Icon(icon,
            size: 18, color: color ?? const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF2ECC71).withValues(alpha: 0.10)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(0xFF2ECC71)
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? const Color(0xFF2ECC71)
                    : Colors.grey[600],
              )),
        ),
      ),
    );
  }
}