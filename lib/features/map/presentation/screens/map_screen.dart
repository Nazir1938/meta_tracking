import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

enum _DrawMode { none, radius, freehand }

class MapScreen extends StatefulWidget {
  final List<String>? highlightedAnimalIds;
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
  // ── Google Maps ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  MapType _mapType = MapType.hybrid; // Google Earth görünüşü
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  // ── Çizmə rejimi ────────────────────────────────────────────────────────
  _DrawMode _drawMode = _DrawMode.none;
  LatLng? _radiusCenter;
  double _radius = 500;
  final List<LatLng> _freehandPoints = [];

  // ── GPS ──────────────────────────────────────────────────────────────────
  LatLng? _currentLocation;
  StreamSubscription<Position>? _locationSub;
  bool _locationReady = false;

  static const LatLng _defaultLocation = LatLng(40.3686, 49.8671);

  // ── Zone panel ───────────────────────────────────────────────────────────
  bool _showZoneList = false;

  // ── Seçilmiş zona (info sheet üçün) ─────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı');
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadZones());
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    AppLogger.ekranBaglandi('Xəritə Ekranı');
    super.dispose();
  }

  // ── Zonaları Firestore-dan yüklə ─────────────────────────────────────────
  void _loadZones() {
    final auth = context.read<AuthBloc>().state;
    final ownerId = auth is AuthAuthenticated ? auth.user.id : null;
    context.read<ZoneBloc>().add(LoadZonesEvent(ownerId: ownerId));
  }

  // ── GPS ──────────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied)
        p = await Geolocator.requestPermission();
      if (p == LocationPermission.whileInUse ||
          p == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high));
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _locationReady = true;
        });
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 15));

        _locationSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, distanceFilter: 15),
        ).listen((p) {
          if (mounted)
            setState(() => _currentLocation = LatLng(p.latitude, p.longitude));
        });
      }
    } catch (e) {
      AppLogger.xeta('MAP GPS', 'Xəta', xetaObyekti: e);
    }
  }

  // ── Zona overlay-ları ────────────────────────────────────────────────────
  void _rebuildOverlays(List<ZoneEntity> zones) {
    _circles.clear();
    _markers.removeWhere((m) =>
        m.markerId.value.startsWith('zone-') ||
        m.markerId.value.startsWith('animal-'));

    for (final z in zones) {
      _addZoneOverlay(z);
    }
    _rebuildAnimalMarkers();
    if (mounted) setState(() {});
  }

  void _addZoneOverlay(ZoneEntity zone) {
    final color = zone.isActive ? const Color(0xFF1D9E75) : Colors.grey;

    _circles.add(Circle(
      circleId: CircleId('zone-circle-${zone.id}'),
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radiusInMeters,
      fillColor: color.withValues(alpha: 0.18),
      strokeColor: color.withValues(alpha: 0.85),
      strokeWidth: 2,
      onTap: () => _onZoneTap(zone),
    ));

    // Zona marker-ı — tıklandıqda info sheet açır
    _markers.add(Marker(
      markerId: MarkerId('zone-label-${zone.id}'),
      position: LatLng(zone.latitude, zone.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        zone.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
      ),
      onTap: () => _onZoneTap(zone),
      infoWindow: InfoWindow.noText,
    ));
  }

  void _rebuildAnimalMarkers() {
    if (widget.animalEntities == null) return;
    for (final a in widget.animalEntities!) {
      if (a.lastLatitude == null || a.lastLongitude == null) continue;
      final hl = widget.highlightedAnimalIds?.contains(a.id) ?? false;
      _markers.add(Marker(
        markerId: MarkerId('animal-${a.id}'),
        position: LatLng(a.lastLatitude!, a.lastLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            hl ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '${a.typeEmoji} ${a.name}',
          snippet: [
            if (a.zoneName != null) '📍 ${a.zoneName}',
            if (a.batteryLevel != null)
              '🔋 ${(a.batteryLevel! * 100).toInt()}%',
          ].join(' · '),
        ),
      ));
    }
  }

  // ── Zona tap → info bottom sheet ─────────────────────────────────────────
  void _onZoneTap(ZoneEntity zone) {
    _showZoneInfoSheet(zone);
  }

  void _showZoneInfoSheet(ZoneEntity zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZoneInfoSheet(
        zone: zone,
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(zone);
        },
        onToggle: () {
          Navigator.pop(context);
          _toggleZone(zone);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(zone);
        },
        onFocus: () {
          Navigator.pop(context);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(zone.latitude, zone.longitude), 15),
          );
        },
      ),
    );
  }

  void _toggleZone(ZoneEntity zone) {
    context.read<ZoneBloc>().add(
          ToggleZoneActiveEvent(zoneId: zone.id, isActive: !zone.isActive),
        );
  }

  // ── Çizmə ────────────────────────────────────────────────────────────────
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
        fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.7),
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
        fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.75),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void _confirmDraw() {
    if (_drawMode == _DrawMode.radius) {
      if (_radiusCenter == null) {
        _snack('Lütfən xəritəyə toxunaraq mərkəz seçin', isError: true);
        return;
      }
      _promptZoneName((name, desc) {
        _circles.removeWhere((c) => c.circleId.value == '__preview__');
        final auth = context.read<AuthBloc>().state;
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: _radiusCenter!.latitude,
              longitude: _radiusCenter!.longitude,
              radiusInMeters: _radius,
              description: desc,
              ownerId: auth is AuthAuthenticated ? auth.user.id : null,
            ));
        _resetDraw();
      });
    } else if (_drawMode == _DrawMode.freehand) {
      if (_freehandPoints.length < 3) {
        _snack('Ən az 3 nöqtə seçin', isError: true);
        return;
      }
      _promptZoneName((name, desc) {
        _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');

        final lat =
            _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        final lon =
            _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                _freehandPoints.length;

        double maxDist = 0;
        for (final p in _freehandPoints) {
          final d = ((p.latitude - lat) * (p.latitude - lat) +
                  (p.longitude - lon) * (p.longitude - lon)) *
              111000;
          if (d > maxDist) maxDist = d;
        }

        _polygons.add(Polygon(
          polygonId: PolygonId('fh-${DateTime.now().millisecondsSinceEpoch}'),
          points: List.from(_freehandPoints),
          fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
          strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.8),
          strokeWidth: 2,
        ));

        final auth = context.read<AuthBloc>().state;
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: lat,
              longitude: lon,
              radiusInMeters: maxDist > 0 ? maxDist : 300,
              description: desc,
              ownerId: auth is AuthAuthenticated ? auth.user.id : null,
            ));
        _resetDraw();
      });
    }
  }

  void _cancelDraw() {
    _circles.removeWhere((c) => c.circleId.value == '__preview__');
    _polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    _resetDraw();
  }

  void _resetDraw() => setState(() {
        _drawMode = _DrawMode.none;
        _radiusCenter = null;
        _freehandPoints.clear();
      });

  void _goToMyLocation() {
    final t = _currentLocation ?? _defaultLocation;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(t, 15));
  }

  // ── Dialoqular ────────────────────────────────────────────────────────────
  void _promptZoneName(void Function(String, String?) cb) {
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
          _dialogField(nameCtrl, 'Ad *', 'Otlaq-1', autofocus: true),
          const SizedBox(height: 10),
          _dialogField(descCtrl, 'Açıqlama (ixtiyari)', ''),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final name = nameCtrl.text.trim().isEmpty
                  ? 'Yeni Zona'
                  : nameCtrl.text.trim();
              cb(name,
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
            },
            child: const Text('Yarat',
                style: TextStyle(
                    color: Color(0xFF1D9E75), fontWeight: FontWeight.w700)),
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
        builder: (ctx, set) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Zonayı Redaktə Et',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(nameCtrl, 'Ad *', ''),
            const SizedBox(height: 10),
            _dialogField(descCtrl, 'Açıqlama (ixtiyari)', ''),
            const SizedBox(height: 12),
            Row(children: [
              Text('${(radius / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D9E75))),
              Expanded(
                child: Slider(
                  value: radius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: const Color(0xFF1D9E75),
                  label: '${(radius / 1000).toStringAsFixed(2)} km',
                  onChanged: (v) => set(() => radius = v),
                ),
              ),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ZoneBloc>().add(UpdateZoneEvent(zone.copyWith(
                      name: nameCtrl.text.trim().isEmpty
                          ? zone.name
                          : nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      radiusInMeters: radius,
                    )));
              },
              child: const Text('Yadda Saxla',
                  style: TextStyle(
                      color: Color(0xFF1D9E75), fontWeight: FontWeight.w700)),
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
            '"${zone.name}" silinsin?\nBu əməliyyat geri qaytarıla bilməz.',
            style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ZoneBloc>().add(DeleteZoneEvent(zone.id));
            },
            child: const Text('Sil',
                style: TextStyle(
                    color: Color(0xFFE24B4A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  TextField _dialogField(TextEditingController ctrl, String label, String hint,
      {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF1D9E75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A1628),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: BlocConsumer<ZoneBloc, ZoneState>(
        listenWhen: (_, curr) =>
            curr is ZonesLoaded ||
            curr is ZoneOperationSuccess ||
            curr is ZoneError,
        listener: (ctx, state) {
          if (state is ZonesLoaded) _rebuildOverlays(state.zones);
          if (state is ZoneOperationSuccess) _snack(state.message);
          if (state is ZoneError) _snack(state.message, isError: true);
        },
        buildWhen: (_, curr) => curr is ZonesLoaded || curr is ZoneLoading,
        builder: (ctx, state) {
          final zones = state is ZonesLoaded ? state.zones : <ZoneEntity>[];
          final isDrawing = _drawMode != _DrawMode.none;

          return Scaffold(
            body: Stack(children: [
              // ── Google Maps — Hybrid (Google Earth görünüşü) ──────────
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? _defaultLocation,
                  zoom: 14,
                ),
                mapType: _mapType,
                onMapCreated: (c) {
                  _mapController = c;
                  _rebuildOverlays(zones);
                  if (_currentLocation != null) {
                    c.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 15));
                  }
                },
                circles: Set.from(_circles),
                markers: Set.from(_markers),
                polygons: Set.from(_polygons),
                onTap: _onMapTap,
                myLocationEnabled: _locationReady,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
              ),

              // ── AppBar ───────────────────────────────────────────────
              _buildAppBar(isDrawing, zones.length),

              // ── GPS yüklənir ─────────────────────────────────────────
              if (!_locationReady)
                _infoBanner(
                  top: MediaQuery.of(context).padding.top + 68,
                  child: const Row(children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1D9E75)),
                    ),
                    SizedBox(width: 10),
                    Text('GPS tapılır...',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),

              // ── Çizmə banneri ────────────────────────────────────────
              if (isDrawing)
                _infoBanner(
                  top: MediaQuery.of(context).padding.top + 68,
                  child: Row(children: [
                    const Icon(Iconsax.location_add,
                        color: Color(0xFF1D9E75), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _drawMode == _DrawMode.radius
                            ? (_radiusCenter == null
                                ? 'Xəritəyə toxunun — mərkəz seçin'
                                : '✓ Mərkəz seçildi. Radiusu tənzimləyin.')
                            : 'Nöqtə əlavə edin (${_freehandPoints.length} seçildi)',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ]),
                ),

              // ── Sağ kontrol düymələri ────────────────────────────────
              Positioned(
                top:
                    MediaQuery.of(context).padding.top + (isDrawing ? 120 : 70),
                right: 12,
                child: Column(children: [
                  _ctrlBtn(
                      Iconsax.add_square,
                      () =>
                          _mapController?.animateCamera(CameraUpdate.zoomIn())),
                  const SizedBox(height: 8),
                  _ctrlBtn(
                      Icons.remove_rounded,
                      () => _mapController
                          ?.animateCamera(CameraUpdate.zoomOut())),
                  const SizedBox(height: 8),
                  _ctrlBtn(Iconsax.location, _goToMyLocation,
                      color: _locationReady
                          ? const Color(0xFF1D9E75)
                          : Colors.grey),
                  const SizedBox(height: 8),
                  // Xəritə tipi toggle
                  _ctrlBtn(
                    _mapType == MapType.hybrid
                        ? Icons.map_outlined
                        : Icons.satellite_alt_outlined,
                    () => setState(() => _mapType = _mapType == MapType.hybrid
                        ? MapType.normal
                        : MapType.hybrid),
                    color: _mapType == MapType.hybrid
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF1A1A2E),
                  ),
                  if (!isDrawing) ...[
                    const SizedBox(height: 8),
                    _ctrlBtn(
                      _showZoneList ? Iconsax.close_circle : Iconsax.location,
                      () => setState(() => _showZoneList = !_showZoneList),
                      color: _showZoneList
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF1A1A2E),
                    ),
                  ],
                ]),
              ),

              // ── Zona siyahısı paneli ─────────────────────────────────
              if (_showZoneList && !isDrawing) _buildZoneListPanel(zones),

              // ── Alt çizmə paneli ─────────────────────────────────────
              if (isDrawing) _buildDrawPanel(),

              // ── FAB-lar ──────────────────────────────────────────────
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
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      tooltip: 'Radius Zona',
                      child: const Icon(Iconsax.location_add),
                    ),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }

  // ── Widget hissələri ──────────────────────────────────────────────────────

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
          if (widget.highlightedAnimalIds?.isNotEmpty == true)
            _appBarBadge('${widget.highlightedAnimalIds!.length} heyvan',
                const Color(0xFF4CAF50)),
          _appBarBadge('$zoneCount zona', const Color(0xFF1D9E75)),
          if (_locationReady) ...[
            const SizedBox(width: 4),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF1D9E75), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('GPS',
                  style: TextStyle(
                      color: Color(0xFF1D9E75),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ],
          if (isDrawing) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: _cancelDraw,
              child: const Text('İmtina',
                  style: TextStyle(
                      color: Color(0xFFE24B4A), fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _appBarBadge(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _infoBanner({required double top, required Widget child}) =>
      Positioned(
        top: top,
        left: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      );

  Widget _buildZoneListPanel(List<ZoneEntity> zones) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      right: 58,
      child: Container(
        width: 230,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1628),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Iconsax.location, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text('Zonalar (${zones.length})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          if (zones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hələ zona yoxdur.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: zones.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (_, i) => _zoneTile(zones[i]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _zoneTile(ZoneEntity zone) {
    return GestureDetector(
      onTap: () {
        setState(() => _showZoneList = false);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(zone.latitude, zone.longitude), 15));
        Future.delayed(
            const Duration(milliseconds: 500), () => _showZoneInfoSheet(zone));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(children: [
          GestureDetector(
            onTap: () => _toggleZone(zone),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: zone.isActive
                    ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                    color: zone.isActive
                        ? const Color(0xFF1D9E75)
                        : Colors.grey.shade300,
                    width: 0.5),
              ),
              child: Icon(
                zone.isActive ? Icons.circle : Icons.circle_outlined,
                size: 10,
                color: zone.isActive ? const Color(0xFF1D9E75) : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          GestureDetector(
            onTap: () => _showEditDialog(zone),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Iconsax.edit_2, size: 14, color: Colors.grey[500]),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(zone),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Iconsax.trash, size: 14, color: Color(0xFFE24B4A)),
            ),
          ),
        ]),
      ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12), blurRadius: 16)
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
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
          if (_drawMode == _DrawMode.radius)
            Row(children: [
              const Text('Radius:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: const Color(0xFF1D9E75),
                  label: '${(_radius / 1000).toStringAsFixed(2)} km',
                  onChanged: (v) {
                    setState(() => _radius = v);
                    _redrawRadiusPreview();
                  },
                ),
              ),
              Text('${(_radius / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D9E75))),
            ]),
          if (_drawMode == _DrawMode.freehand)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Xəritəyə toxunaraq nöqtələri əlavə edin.\n'
                'Ən az 3 nöqtə lazımdır. (${_freehandPoints.length} seçildi)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
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
                  backgroundColor: const Color(0xFF1D9E75),
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

  Widget _ctrlBtn(IconData icon, VoidCallback fn, {Color? color}) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14), blurRadius: 6)
            ],
          ),
          child: Icon(icon, size: 18, color: color ?? const Color(0xFF1A1A2E)),
        ),
      );

  Widget _modeTab(String label, bool active, VoidCallback fn) => Expanded(
        child: GestureDetector(
          onTap: fn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.10)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? const Color(0xFF1D9E75) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? const Color(0xFF1D9E75) : Colors.grey[600])),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone Info Bottom Sheet — gözəl UI
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneInfoSheet extends StatelessWidget {
  final ZoneEntity zone;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onFocus;

  const _ZoneInfoSheet({
    required this.zone,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final color = zone.isActive ? const Color(0xFF1D9E75) : Colors.grey;
    final kmRadius = (zone.radiusInMeters / 1000).toStringAsFixed(2);
    final areaKm2 =
        (3.14159 * (zone.radiusInMeters / 1000) * (zone.radiusInMeters / 1000))
            .toStringAsFixed(3);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
        ),

        // Header — rəngli zona banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(_zoneEmoji(zone.name),
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    if (zone.description != null)
                      Text(zone.description!,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        zone.isActive ? 'Aktiv' : 'Deaktiv',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ]),
            ),
            // Xəritədə fokus
            GestureDetector(
              onTap: onFocus,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.location, color: color, size: 18),
              ),
            ),
          ]),
        ),

        // Stat satırları
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _statRow(Iconsax.radar, 'Radius', '$kmRadius km'),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(Iconsax.chart, 'Sahə', '$areaKm2 km²'),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(
                Iconsax.calendar,
                'Yaradılıb',
                _formatDate(zone.createdAt),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(
                Iconsax.location,
                'Koordinat',
                '${zone.latitude.toStringAsFixed(4)}, '
                    '${zone.longitude.toStringAsFixed(4)}',
              ),
            ]),
          ),
        ),

        // Əməliyyat düymələri
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            // Redaktə
            Expanded(
              child: _actionBtn(
                icon: Iconsax.edit,
                label: 'Redaktə',
                color: const Color(0xFF185FA5),
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 8),
            // Toggle
            Expanded(
              child: _actionBtn(
                icon:
                    zone.isActive ? Iconsax.pause_circle : Iconsax.play_circle,
                label: zone.isActive ? 'Deaktiv et' : 'Aktiv et',
                color: zone.isActive ? Colors.grey : const Color(0xFF1D9E75),
                onTap: onToggle,
              ),
            ),
            const SizedBox(width: 8),
            // Sil
            Expanded(
              child: _actionBtn(
                icon: Iconsax.trash,
                label: 'Sil',
                color: const Color(0xFFE24B4A),
                onTap: onDelete,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
        ]),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  String _zoneEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('otlaq') || n.contains('çəmən')) return '🌿';
    if (n.contains('orman') || n.contains('meşə')) return '🌳';
    if (n.contains('ahır') || n.contains('bina')) return '🏠';
    if (n.contains('su')) return '💧';
    if (n.contains('qarantina') || n.contains('qadağa')) return '🔒';
    return '📍';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
