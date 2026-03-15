import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_animal_no_zone_sheet.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_draw_panel.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_overlay_mixin.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_ui_widgets.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_zone_list_panel.dart';
import 'package:meta_tracking/features/map/presentation/widget/zone_animal_sheet.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class MapScreen extends StatefulWidget {
  final List<String>? highlightedAnimalIds;
  final List<AnimalEntity>? animalEntities;
  final ZoneEntity? focusZone;

  const MapScreen({
    super.key,
    this.highlightedAnimalIds,
    this.animalEntities,
    this.focusZone,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with MapOverlayMixin {
  // ── Yeni zona çizmə ───────────────────────────────────────────────────────
  DrawMode _drawMode = DrawMode.none;
  LatLng? _radiusCenter;
  double _radius = 500;
  final List<LatLng> _freehandPoints = [];

  // ── Mövcud polygon redaktəsi ──────────────────────────────────────────────
  bool _editingPolygon = false;
  ZoneEntity? _editingZone;
  final List<LatLng> _editPoints = [];

  bool _showZoneList = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<AnimalEntity> get _currentAnimals {
    final s = context.read<AnimalBloc>().state;
    return s is AnimalLoaded ? s.animals : (widget.animalEntities ?? []);
  }

  bool get _isAnyActive => _drawMode != DrawMode.none || _editingPolygon;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı');
    initLocation(skipCameraMove: widget.focusZone != null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
      if (widget.focusZone != null) {
        Future.delayed(const Duration(milliseconds: 900),
            () { if (mounted) _focusOnZone(widget.focusZone!); });
      }
    });
  }

  @override
  void dispose() {
    locationSub?.cancel();
    mapController?.dispose();
    AppLogger.ekranBaglandi('Xəritə Ekranı');
    super.dispose();
  }

  // ── Zone yüklə ────────────────────────────────────────────────────────────

  void _loadZones() {
    final auth = context.read<AuthBloc>().state;
    final ownerId = auth is AuthAuthenticated ? auth.user.id : null;
    context.read<ZoneBloc>().add(LoadZonesEvent(ownerId: ownerId));
  }

  void _focusOnZone(ZoneEntity zone) {
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(zone.latitude, zone.longitude),
      zone.zoneType == ZoneType.polygon ? 14 : 15,
    ));
    Future.delayed(const Duration(milliseconds: 700),
        () { if (mounted) _showZoneAnimalSheet(zone); });
  }

  // ── Sheet-lər ─────────────────────────────────────────────────────────────

  void _showZoneAnimalSheet(ZoneEntity zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AnimalBloc>(),
        child: BlocBuilder<AnimalBloc, AnimalState>(
          builder: (_, animalState) {
            final animals = animalState is AnimalLoaded
                ? animalState.animals
                : (widget.animalEntities ?? <AnimalEntity>[]);
            return ZoneAnimalSheet(
              zone: zone,
              allAnimals: animals,
              onEdit: () { Navigator.pop(context); _openEditDialog(zone); },
              onToggle: () {
                Navigator.pop(context);
                context.read<ZoneBloc>().add(ToggleZoneActiveEvent(
                    zoneId: zone.id, isActive: !zone.isActive));
              },
              onDelete: () { Navigator.pop(context); _confirmDelete(zone); },
              onFocus: () {
                Navigator.pop(context);
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(zone.latitude, zone.longitude), 15));
              },
            );
          },
        ),
      ),
    );
  }

  void _showAnimalZoneSheet(AnimalEntity animal) {
    final zoneState = context.read<ZoneBloc>().state;
    final zones = zoneState is ZonesLoaded ? zoneState.zones : <ZoneEntity>[];
    if (animal.zoneId != null) {
      ZoneEntity? zone;
      try { zone = zones.firstWhere((z) => z.id == animal.zoneId); } catch (_) {}
      if (zone != null) { _showZoneAnimalSheet(zone); return; }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalNoZoneSheet(animal: animal),
    );
  }

  // ── Zona redaktəsi ────────────────────────────────────────────────────────

  void _openEditDialog(ZoneEntity zone) {
    final params = ZoneEditParams(
      name: zone.name,
      description: zone.description,
      radiusInMeters: zone.radiusInMeters.clamp(100.0, 5000.0),
      isCircle: zone.zoneType == ZoneType.circle,
    );

    if (zone.zoneType == ZoneType.circle) {
      showZoneEditDialog(context, params, (name, desc, radius) {
        context.read<ZoneBloc>().add(UpdateZoneEvent(
            zone.copyWith(name: name, description: desc, radiusInMeters: radius)));
      });
    } else {
      showPolygonEditChoiceDialog(context, params, (name, desc) {
        context.read<ZoneBloc>().add(UpdateZoneEvent(
            zone.copyWith(name: name, description: desc)));
      }).then((choice) {
        if (choice == PolygonEditChoice.redraw) _startPolygonEdit(zone);
      });
    }
  }

  void _startPolygonEdit(ZoneEntity zone) {
    polygons.removeWhere((p) => p.polygonId.value == 'zone-poly-${zone.id}');
    markers.removeWhere((m) => m.markerId.value == 'zone-label-${zone.id}');
    setState(() {
      _editingPolygon = true;
      _editingZone = zone;
      _editPoints.clear();
    });
    _snack('Xəritəyə toxunaraq yeni nöqtələri əlavə edin');
  }

  void _cancelPolygonEdit() {
    polygons.removeWhere((p) => p.polygonId.value == '__edit_preview__');
    final zoneState = context.read<ZoneBloc>().state;
    if (zoneState is ZonesLoaded) {
      rebuildOverlays(zoneState.zones, _currentAnimals,
          widget.highlightedAnimalIds, _showZoneAnimalSheet, _showAnimalZoneSheet);
    }
    setState(() {
      _editingPolygon = false;
      _editingZone = null;
      _editPoints.clear();
    });
  }

  void _confirmPolygonEdit() {
    if (_editPoints.length < 3) {
      _snack('Ən az 3 nöqtə lazımdır', isError: true);
      return;
    }
    final zone = _editingZone!;
    final zonePoints = _editPoints
        .map((p) => ZoneLatLng(latitude: p.latitude, longitude: p.longitude))
        .toList();
    final lat = _editPoints.map((p) => p.latitude).reduce((a, b) => a + b) / _editPoints.length;
    final lon = _editPoints.map((p) => p.longitude).reduce((a, b) => a + b) / _editPoints.length;
    final areaKm2 = GeofencingService.calculatePolygonAreaKm2(zonePoints);
    double maxDist = 50;
    for (final p in _editPoints) {
      final d = GeofencingService.calculateDistance(lat, lon, p.latitude, p.longitude);
      if (d > maxDist) maxDist = d;
    }
    context.read<ZoneBloc>().add(UpdateZoneEvent(zone.copyWith(
        latitude: lat, longitude: lon, radiusInMeters: maxDist,
        zoneType: ZoneType.polygon, polygonPoints: zonePoints, areaKm2: areaKm2)));
    polygons.removeWhere((p) => p.polygonId.value == '__edit_preview__');
    setState(() { _editingPolygon = false; _editingZone = null; _editPoints.clear(); });
    _snack('Zona yeniləndi');
  }

  void _confirmDelete(ZoneEntity zone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Zonayı Sil',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('"${zone.name}" silinsin?\nBu əməliyyat geri qaytarıla bilməz.',
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
                style: TextStyle(color: Color(0xFFE24B4A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Xəritə tap ────────────────────────────────────────────────────────────

  void _onMapTap(LatLng loc) {
    if (_editingPolygon) {
      setState(() => _editPoints.add(loc));
      _redrawEditPreview();
      return;
    }
    if (_drawMode == DrawMode.none) return;
    if (_drawMode == DrawMode.radius) {
      setState(() => _radiusCenter = loc);
      redrawRadiusPreview(_radiusCenter, _radius);
    } else {
      setState(() => _freehandPoints.add(loc));
      redrawFreehandPreview(_freehandPoints);
    }
  }

  void _redrawEditPreview() {
    polygons.removeWhere((p) => p.polygonId.value == '__edit_preview__');
    if (_editPoints.length >= 2) {
      polygons.add(Polygon(
        polygonId: const PolygonId('__edit_preview__'),
        points: _editPoints,
        fillColor: const Color(0xFF9B59B6).withValues(alpha: 0.15),
        strokeColor: const Color(0xFF9B59B6).withValues(alpha: 0.85),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void _cancelDraw() {
    circles.removeWhere((c) => c.circleId.value == '__preview__');
    polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    setState(() {
      _drawMode = DrawMode.none;
      _radiusCenter = null;
      _freehandPoints.clear();
    });
  }

  void _confirmDraw() {
    if (_drawMode == DrawMode.radius) {
      if (_radiusCenter == null) {
        _snack('Lütfən xəritəyə toxunaraq mərkəz seçin', isError: true);
        return;
      }
      showZoneNameDialog(context, (name, desc) {
        circles.removeWhere((c) => c.circleId.value == '__preview__');
        final auth = context.read<AuthBloc>().state;
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: _radiusCenter!.latitude,
              longitude: _radiusCenter!.longitude,
              radiusInMeters: _radius,
              description: desc,
              ownerId: auth is AuthAuthenticated ? auth.user.id : null,
              zoneType: ZoneType.circle,
            ));
        setState(() { _drawMode = DrawMode.none; _radiusCenter = null; });
      });
    } else {
      if (_freehandPoints.length < 3) {
        _snack('Ən az 3 nöqtə seçin', isError: true);
        return;
      }
      showZoneNameDialog(context, (name, desc) {
        polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
        final zonePoints = _freehandPoints
            .map((p) => ZoneLatLng(latitude: p.latitude, longitude: p.longitude))
            .toList();
        final lat = _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
            _freehandPoints.length;
        final lon = _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
            _freehandPoints.length;
        final areaKm2 = GeofencingService.calculatePolygonAreaKm2(zonePoints);
        double maxDist = 50;
        for (final p in _freehandPoints) {
          final d = GeofencingService.calculateDistance(lat, lon, p.latitude, p.longitude);
          if (d > maxDist) maxDist = d;
        }
        addFinalPolygon(_freehandPoints, '${DateTime.now().millisecondsSinceEpoch}');
        final auth = context.read<AuthBloc>().state;
        context.read<ZoneBloc>().add(CreateZoneEvent(
              name: name,
              latitude: lat,
              longitude: lon,
              radiusInMeters: maxDist,
              description: desc,
              ownerId: auth is AuthAuthenticated ? auth.user.id : null,
              zoneType: ZoneType.polygon,
              polygonPoints: zonePoints,
              areaKm2: areaKm2,
            ));
        setState(() { _drawMode = DrawMode.none; _freehandPoints.clear(); });
      });
    }
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

  // ── BUILD ──────────────────────────────────────────────────────────────────

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
            curr is ZonesLoaded || curr is ZoneOperationSuccess || curr is ZoneError,
        listener: (_, state) {
          if (state is ZonesLoaded) {
            rebuildOverlays(state.zones, _currentAnimals,
                widget.highlightedAnimalIds, _showZoneAnimalSheet, _showAnimalZoneSheet);
          }
          if (state is ZoneOperationSuccess) _snack(state.message);
          if (state is ZoneError) _snack(state.message, isError: true);
        },
        buildWhen: (_, curr) => curr is ZonesLoaded || curr is ZoneLoading,
        builder: (_, zoneState) {
          return BlocListener<AnimalBloc, AnimalState>(
            listener: (_, animalState) {
              if (animalState is AnimalLoaded && zoneState is ZonesLoaded) {
                rebuildOverlays(zoneState.zones, animalState.animals,
                    widget.highlightedAnimalIds, _showZoneAnimalSheet, _showAnimalZoneSheet);
              }
            },
            child: Builder(builder: (_) {
              final zones = zoneState is ZonesLoaded ? zoneState.zones : <ZoneEntity>[];
              final isDrawing = _drawMode != DrawMode.none;

              return Scaffold(
                body: Stack(children: [

                  // ── Google Maps ─────────────────────────────────────
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.focusZone != null
                          ? LatLng(widget.focusZone!.latitude, widget.focusZone!.longitude)
                          : (currentLocation ?? MapOverlayMixin.defaultLocation),
                      zoom: 14,
                    ),
                    mapType: mapType,
                    onMapCreated: (c) {
                      mapController = c;
                      rebuildOverlays(zones, _currentAnimals, widget.highlightedAnimalIds,
                          _showZoneAnimalSheet, _showAnimalZoneSheet);
                      final target = widget.focusZone != null
                          ? LatLng(widget.focusZone!.latitude, widget.focusZone!.longitude)
                          : currentLocation;
                      if (target != null) {
                        c.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
                      }
                    },
                    circles: Set.from(circles),
                    markers: Set.from(markers),
                    polygons: Set.from(polygons),
                    onTap: _onMapTap,
                    myLocationEnabled: locationReady,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    tiltGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                  ),

                  // ── AppBar ─────────────────────────────────────────
                  MapAppBar(
                    isDrawing: _isAnyActive,
                    zoneCount: zones.length,
                    highlightCount: widget.highlightedAnimalIds?.length ?? 0,
                    locationReady: locationReady,
                    title: _editingPolygon
                        ? '${_editingZone?.name ?? "Zona"} — Redaktə'
                        : 'Heyvan Xəritəsi',
                    onCancel: _editingPolygon ? _cancelPolygonEdit : _cancelDraw,
                  ),

                  // ── GPS yüklənir ───────────────────────────────────
                  if (!locationReady)
                    MapInfoBanner(
                      top: MediaQuery.of(context).padding.top + 68,
                      child: const Row(children: [
                        SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1D9E75))),
                        SizedBox(width: 10),
                        Text('GPS tapılır...',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),

                  // ── Yeni zona çizmə banneri ────────────────────────
                  if (isDrawing && !_editingPolygon)
                    MapInfoBanner(
                      top: MediaQuery.of(context).padding.top + 68,
                      child: Row(children: [
                        const Icon(Iconsax.location_add,
                            color: Color(0xFF1D9E75), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _drawMode == DrawMode.radius
                              ? (_radiusCenter == null
                                  ? 'Xəritəyə toxunun — mərkəz seçin'
                                  : '✓ Mərkəz seçildi. Radiusu tənzimləyin.')
                              : 'Nöqtə əlavə edin (${_freehandPoints.length} seçildi)',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        )),
                      ]),
                    ),

                  // ── Polygon redaktə banneri ────────────────────────
                  if (_editingPolygon)
                    MapInfoBanner(
                      top: MediaQuery.of(context).padding.top + 68,
                      child: Row(children: [
                        const Icon(Iconsax.edit,
                            color: Color(0xFF9B59B6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Yeni polygon nöqtələrini əlavə edin (${_editPoints.length} seçildi)',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        )),
                      ]),
                    ),

                  // ── Sağ kontrol düymələri ──────────────────────────
                  MapControls(
                    top: MediaQuery.of(context).padding.top + (_isAnyActive ? 120 : 70),
                    mapType: mapType,
                    locationReady: locationReady,
                    showZoneList: _showZoneList,
                    isDrawing: _isAnyActive,
                    onZoomIn: () => mapController?.animateCamera(CameraUpdate.zoomIn()),
                    onZoomOut: () => mapController?.animateCamera(CameraUpdate.zoomOut()),
                    onMyLocation: goToMyLocation,
                    onToggleMapType: () => setState(() => mapType =
                        mapType == MapType.hybrid ? MapType.normal : MapType.hybrid),
                    onToggleZoneList: () =>
                        setState(() => _showZoneList = !_showZoneList),
                  ),

                  // ── Zona siyahısı paneli ───────────────────────────
                  if (_showZoneList && !_isAnyActive)
                    MapZoneListPanel(
                      zones: zones,
                      onZoneTap: (zone) {
                        setState(() => _showZoneList = false);
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                            LatLng(zone.latitude, zone.longitude), 15));
                        Future.delayed(const Duration(milliseconds: 500),
                            () => _showZoneAnimalSheet(zone));
                      },
                      onToggle: (zone) => context.read<ZoneBloc>().add(
                          ToggleZoneActiveEvent(zoneId: zone.id, isActive: !zone.isActive)),
                      onEdit: _openEditDialog,
                      onDelete: _confirmDelete,
                    ),

                  // ── Yeni zona çizmə paneli ─────────────────────────
                  if (isDrawing && !_editingPolygon)
                    MapDrawPanel(
                      drawMode: _drawMode,
                      radius: _radius,
                      freehandPointCount: _freehandPoints.length,
                      onModeChanged: (m) {
                        _cancelDraw();
                        setState(() => _drawMode = m);
                      },
                      onRadiusChanged: (v) {
                        setState(() => _radius = v);
                        redrawRadiusPreview(_radiusCenter, v);
                      },
                      onCancel: _cancelDraw,
                      onConfirm: _confirmDraw,
                    ),

                  // ── Polygon redaktə paneli ─────────────────────────
                  if (_editingPolygon)
                    MapEditPolygonPanel(
                      pointCount: _editPoints.length,
                      zoneName: _editingZone?.name ?? '',
                      onCancel: _cancelPolygonEdit,
                      onConfirm: _confirmPolygonEdit,
                    ),

                  // ── FAB-lar ────────────────────────────────────────
                  if (!_isAnyActive && !_showZoneList)
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FloatingActionButton.small(
                          heroTag: 'fab_fh',
                          onPressed: () => setState(() => _drawMode = DrawMode.freehand),
                          backgroundColor: const Color(0xFF9B59B6),
                          foregroundColor: Colors.white,
                          tooltip: 'Azad Zona Çiz',
                          child: const Icon(Iconsax.edit, size: 18),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'fab_radius',
                          onPressed: () => setState(() => _drawMode = DrawMode.radius),
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          tooltip: 'Radius Zona',
                          child: const Icon(Iconsax.location_add),
                        ),
                      ]),
                    ),

                ]),
              );
            }),
          );
        },
      ),
    );
  }
}