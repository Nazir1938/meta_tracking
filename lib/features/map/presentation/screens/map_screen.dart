import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_draw_panel.dart';
import 'package:meta_tracking/features/map/presentation/widget/map_overlay_mixin.dart';
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
  ZoneEntity? _editingZone; // Redaktə olunan zona
  final List<LatLng> _editPoints = [];

  bool _showZoneList = false;

  List<AnimalEntity> get _currentAnimals {
    final s = context.read<AnimalBloc>().state;
    return s is AnimalLoaded ? s.animals : (widget.animalEntities ?? []);
  }

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı');
    initLocation(skipCameraMove: widget.focusZone != null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
      if (widget.focusZone != null) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _focusOnZone(widget.focusZone!);
        });
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
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _showZoneAnimalSheet(zone);
    });
  }

  // ── Zona tap → ZoneAnimalSheet ────────────────────────────────────────────
  void _showZoneAnimalSheet(ZoneEntity zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AnimalBloc>(),
        child: BlocBuilder<AnimalBloc, AnimalState>(
          builder: (ctx, animalState) {
            final animals = animalState is AnimalLoaded
                ? animalState.animals
                : (widget.animalEntities ?? <AnimalEntity>[]);
            return ZoneAnimalSheet(
              zone: zone,
              allAnimals: animals,
              onEdit: () {
                Navigator.pop(context);
                _openEditDialog(zone);
              },
              onToggle: () {
                Navigator.pop(context);
                context.read<ZoneBloc>().add(ToggleZoneActiveEvent(
                    zoneId: zone.id, isActive: !zone.isActive));
              },
              onDelete: () {
                Navigator.pop(context);
                _confirmDelete(zone);
              },
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

  // ── Heyvan marker tap ─────────────────────────────────────────────────────
  void _showAnimalZoneSheet(AnimalEntity animal) {
    final zoneState = context.read<ZoneBloc>().state;
    final zones = zoneState is ZonesLoaded ? zoneState.zones : <ZoneEntity>[];

    if (animal.zoneId != null) {
      ZoneEntity? zone;
      try {
        zone = zones.firstWhere((z) => z.id == animal.zoneId);
      } catch (_) {}
      if (zone != null) {
        _showZoneAnimalSheet(zone);
        return;
      }
    }
    _showAnimalNoZoneSheet(animal);
  }

  void _showAnimalNoZoneSheet(AnimalEntity animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnimalNoZoneSheet(animal: animal),
    );
  }

  // ── Redaktə ───────────────────────────────────────────────────────────────
  void _openEditDialog(ZoneEntity zone) {
    final params = ZoneEditParams(
      name: zone.name,
      description: zone.description,
      radiusInMeters: zone.radiusInMeters.clamp(100.0, 5000.0),
      isCircle: zone.zoneType == ZoneType.circle,
    );

    if (zone.zoneType == ZoneType.circle) {
      // Dairə zona: sadə dialog + radius slider
      showZoneEditDialog(context, params, (name, desc, radius) {
        context.read<ZoneBloc>().add(UpdateZoneEvent(zone.copyWith(
              name: name,
              description: desc,
              radiusInMeters: radius,
            )));
      });
    } else {
      // Polygon zona: ad dəyiş və ya xəritədə yenidən çək
      showPolygonEditChoiceDialog(
        context,
        params,
        (name, desc) {
          // Yalnız ad/açıqlama dəyişdi — polygon nöqtələri eyni qalır
          context.read<ZoneBloc>().add(UpdateZoneEvent(zone.copyWith(
                name: name,
                description: desc,
              )));
        },
      ).then((choice) {
        if (choice == PolygonEditChoice.redraw) {
          // Xəritədə yenidən çəkmə rejiminə keç
          _startPolygonEdit(zone);
        }
      });
    }
  }

  // ── Polygon redaktə rejimini başlat ───────────────────────────────────────
  void _startPolygonEdit(ZoneEntity zone) {
    // Köhnə polygon overlay-ını sil (yeni çəkmə görünsün)
    polygons.removeWhere((p) => p.polygonId.value == 'zone-poly-${zone.id}');
    markers.removeWhere((m) => m.markerId.value == 'zone-label-${zone.id}');

    setState(() {
      _editingPolygon = true;
      _editingZone = zone;
      _editPoints.clear();
    });

    _snack('Xəritəyə toxunaraq yeni nöqtələri əlavə edin', isError: false);
  }

  // ── Polygon redaktəni ləğv et ─────────────────────────────────────────────
  void _cancelPolygonEdit() {
    polygons.removeWhere((p) => p.polygonId.value == '__edit_preview__');
    // Overlay-ları yenidən qur
    final zoneState = context.read<ZoneBloc>().state;
    if (zoneState is ZonesLoaded) {
      rebuildOverlays(
          zoneState.zones,
          _currentAnimals,
          widget.highlightedAnimalIds,
          _showZoneAnimalSheet,
          _showAnimalZoneSheet);
    }
    setState(() {
      _editingPolygon = false;
      _editingZone = null;
      _editPoints.clear();
    });
  }

  // ── Polygon redaktəni təsdiqlə ────────────────────────────────────────────
  void _confirmPolygonEdit() {
    if (_editPoints.length < 3) {
      _snack('Ən az 3 nöqtə lazımdır', isError: true);
      return;
    }
    final zone = _editingZone!;

    final zonePoints = _editPoints
        .map((p) => ZoneLatLng(latitude: p.latitude, longitude: p.longitude))
        .toList();

    final lat = _editPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        _editPoints.length;
    final lon = _editPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        _editPoints.length;

    final areaKm2 = GeofencingService.calculatePolygonAreaKm2(zonePoints);

    double maxDist = 50;
    for (final p in _editPoints) {
      final d = GeofencingService.calculateDistance(
          lat, lon, p.latitude, p.longitude);
      if (d > maxDist) maxDist = d;
    }

    context.read<ZoneBloc>().add(UpdateZoneEvent(zone.copyWith(
          latitude: lat,
          longitude: lon,
          radiusInMeters: maxDist,
          zoneType: ZoneType.polygon,
          polygonPoints: zonePoints,
          areaKm2: areaKm2,
        )));

    polygons.removeWhere((p) => p.polygonId.value == '__edit_preview__');
    setState(() {
      _editingPolygon = false;
      _editingZone = null;
      _editPoints.clear();
    });
    _snack('Zona yeniləndi');
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

  // ── Xəritə tap ────────────────────────────────────────────────────────────
  void _onMapTap(LatLng loc) {
    // Polygon redaktə rejimi
    if (_editingPolygon) {
      setState(() => _editPoints.add(loc));
      _redrawEditPreview();
      return;
    }

    // Yeni zona çizmə
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
        setState(() {
          _drawMode = DrawMode.none;
          _radiusCenter = null;
        });
      });
    } else {
      if (_freehandPoints.length < 3) {
        _snack('Ən az 3 nöqtə seçin', isError: true);
        return;
      }
      showZoneNameDialog(context, (name, desc) {
        polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');

        final zonePoints = _freehandPoints
            .map(
                (p) => ZoneLatLng(latitude: p.latitude, longitude: p.longitude))
            .toList();
        final lat =
            _freehandPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        final lon =
            _freehandPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
                _freehandPoints.length;
        final areaKm2 = GeofencingService.calculatePolygonAreaKm2(zonePoints);
        double maxDist = 50;
        for (final p in _freehandPoints) {
          final d = GeofencingService.calculateDistance(
              lat, lon, p.latitude, p.longitude);
          if (d > maxDist) maxDist = d;
        }

        addFinalPolygon(
            _freehandPoints, '${DateTime.now().millisecondsSinceEpoch}');
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
        setState(() {
          _drawMode = DrawMode.none;
          _freehandPoints.clear();
        });
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
            curr is ZonesLoaded ||
            curr is ZoneOperationSuccess ||
            curr is ZoneError,
        listener: (_, state) {
          if (state is ZonesLoaded) {
            rebuildOverlays(
                state.zones,
                _currentAnimals,
                widget.highlightedAnimalIds,
                _showZoneAnimalSheet,
                _showAnimalZoneSheet);
          }
          if (state is ZoneOperationSuccess) _snack(state.message);
          if (state is ZoneError) _snack(state.message, isError: true);
        },
        buildWhen: (_, curr) => curr is ZonesLoaded || curr is ZoneLoading,
        builder: (_, zoneState) {
          return BlocListener<AnimalBloc, AnimalState>(
            listener: (_, animalState) {
              if (animalState is AnimalLoaded && zoneState is ZonesLoaded) {
                rebuildOverlays(
                  zoneState.zones,
                  animalState.animals,
                  widget.highlightedAnimalIds,
                  _showZoneAnimalSheet,
                  _showAnimalZoneSheet,
                );
              }
            },
            child: Builder(builder: (ctx) {
              final zones =
                  zoneState is ZonesLoaded ? zoneState.zones : <ZoneEntity>[];
              final isDrawing = _drawMode != DrawMode.none;
              final isAnyActive = isDrawing || _editingPolygon;

              return Scaffold(
                body: Stack(children: [
                  // ── Google Maps ─────────────────────────────────────
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.focusZone != null
                          ? LatLng(widget.focusZone!.latitude,
                              widget.focusZone!.longitude)
                          : (currentLocation ??
                              MapOverlayMixin.defaultLocation),
                      zoom: 14,
                    ),
                    mapType: mapType,
                    onMapCreated: (c) {
                      mapController = c;
                      rebuildOverlays(
                          zones,
                          _currentAnimals,
                          widget.highlightedAnimalIds,
                          _showZoneAnimalSheet,
                          _showAnimalZoneSheet);
                      final target = widget.focusZone != null
                          ? LatLng(widget.focusZone!.latitude,
                              widget.focusZone!.longitude)
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
                  _MapAppBar(
                    isDrawing: isAnyActive,
                    zoneCount: zones.length,
                    highlightCount: widget.highlightedAnimalIds?.length ?? 0,
                    locationReady: locationReady,
                    title: _editingPolygon
                        ? '${_editingZone?.name ?? "Zona"} — Redaktə'
                        : 'Heyvan Xəritəsi',
                    onCancel:
                        _editingPolygon ? _cancelPolygonEdit : _cancelDraw,
                  ),

                  // ── GPS yüklənir ───────────────────────────────────
                  if (!locationReady)
                    _InfoBanner(
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
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),

                  // ── Çizmə banneri ──────────────────────────────────
                  if (isDrawing && !_editingPolygon)
                    _InfoBanner(
                      top: MediaQuery.of(context).padding.top + 68,
                      child: Row(children: [
                        const Icon(Iconsax.location_add,
                            color: Color(0xFF1D9E75), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _drawMode == DrawMode.radius
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

                  // ── Polygon redaktə banneri ────────────────────────
                  if (_editingPolygon)
                    _InfoBanner(
                      top: MediaQuery.of(context).padding.top + 68,
                      child: Row(children: [
                        const Icon(Iconsax.edit,
                            color: Color(0xFF9B59B6), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yeni polygon nöqtələrini əlavə edin (${_editPoints.length} seçildi)',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ]),
                    ),

                  // ── Sağ kontrol ────────────────────────────────────
                  _MapControls(
                    top: MediaQuery.of(context).padding.top +
                        (isAnyActive ? 120 : 70),
                    mapType: mapType,
                    locationReady: locationReady,
                    showZoneList: _showZoneList,
                    isDrawing: isAnyActive,
                    onZoomIn: () =>
                        mapController?.animateCamera(CameraUpdate.zoomIn()),
                    onZoomOut: () =>
                        mapController?.animateCamera(CameraUpdate.zoomOut()),
                    onMyLocation: goToMyLocation,
                    onToggleMapType: () => setState(() => mapType =
                        mapType == MapType.hybrid
                            ? MapType.normal
                            : MapType.hybrid),
                    onToggleZoneList: () =>
                        setState(() => _showZoneList = !_showZoneList),
                  ),

                  // ── Zona siyahısı ──────────────────────────────────
                  if (_showZoneList && !isAnyActive)
                    _ZoneListPanel(
                      zones: zones,
                      onZoneTap: (zone) {
                        setState(() => _showZoneList = false);
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
                            LatLng(zone.latitude, zone.longitude), 15));
                        Future.delayed(const Duration(milliseconds: 500),
                            () => _showZoneAnimalSheet(zone));
                      },
                      onToggle: (zone) => context.read<ZoneBloc>().add(
                          ToggleZoneActiveEvent(
                              zoneId: zone.id, isActive: !zone.isActive)),
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
                  if (!isAnyActive && !_showZoneList)
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FloatingActionButton.small(
                          heroTag: 'fab_fh',
                          onPressed: () =>
                              setState(() => _drawMode = DrawMode.freehand),
                          backgroundColor: const Color(0xFF9B59B6),
                          foregroundColor: Colors.white,
                          tooltip: 'Azad Zona Çiz',
                          child: const Icon(Iconsax.edit, size: 18),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'fab_radius',
                          onPressed: () =>
                              setState(() => _drawMode = DrawMode.radius),
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

// ─────────────────────────────────────────────────────────────────────────────
// Heyvanın zonası yoxdursa göstərilən sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AnimalNoZoneSheet extends StatelessWidget {
  final AnimalEntity animal;
  const _AnimalNoZoneSheet({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text(animal.typeEmoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(animal.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE24B4A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Hər hansı bir eraziyə təyin edilməyib',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE24B4A),
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text(
          'Heyvana erazi təyin etmək üçün xəritədə bir eraziyə toxunun '
          'və "Əlavə et" tabından bu heyvanı seçin.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bağla'),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget {
  final bool isDrawing, locationReady;
  final int zoneCount, highlightCount;
  final String title;
  final VoidCallback onCancel;

  const _MapAppBar({
    required this.isDrawing,
    required this.zoneCount,
    required this.highlightCount,
    required this.locationReady,
    required this.title,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          if (highlightCount > 0)
            _badge('$highlightCount heyvan', const Color(0xFF4CAF50)),
          _badge('$zoneCount zona', const Color(0xFF1D9E75)),
          if (locationReady) ...[
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
              onPressed: onCancel,
              child: const Text('İmtina',
                  style: TextStyle(
                      color: Color(0xFFE24B4A), fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Info banner
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final double top;
  final Widget child;
  const _InfoBanner({required this.top, required this.child});

  @override
  Widget build(BuildContext context) => Positioned(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Sağ kontrol düymələri
// ─────────────────────────────────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  final double top;
  final MapType mapType;
  final bool locationReady, showZoneList, isDrawing;
  final VoidCallback onZoomIn,
      onZoomOut,
      onMyLocation,
      onToggleMapType,
      onToggleZoneList;

  const _MapControls({
    required this.top,
    required this.mapType,
    required this.locationReady,
    required this.showZoneList,
    required this.isDrawing,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleMapType,
    required this.onToggleZoneList,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        right: 12,
        child: Column(children: [
          _btn(Iconsax.add_square, onZoomIn),
          const SizedBox(height: 8),
          _btn(Icons.remove_rounded, onZoomOut),
          const SizedBox(height: 8),
          _btn(Iconsax.location, onMyLocation,
              color: locationReady ? const Color(0xFF1D9E75) : Colors.grey),
          const SizedBox(height: 8),
          _btn(
            mapType == MapType.hybrid
                ? Icons.map_outlined
                : Icons.satellite_alt_outlined,
            onToggleMapType,
            color: mapType == MapType.hybrid
                ? const Color(0xFF1D9E75)
                : const Color(0xFF1A1A2E),
          ),
          if (!isDrawing) ...[
            const SizedBox(height: 8),
            _btn(
              showZoneList ? Iconsax.close_circle : Iconsax.location,
              onToggleZoneList,
              color: showZoneList
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF1A1A2E),
            ),
          ],
        ]),
      );

  Widget _btn(IconData icon, VoidCallback fn, {Color? color}) =>
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Zona siyahısı paneli
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneListPanel extends StatelessWidget {
  final List<ZoneEntity> zones;
  final void Function(ZoneEntity) onZoneTap;
  final void Function(ZoneEntity) onToggle;
  final void Function(ZoneEntity) onEdit;
  final void Function(ZoneEntity) onDelete;

  const _ZoneListPanel({
    required this.zones,
    required this.onZoneTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        right: 58,
        child: Container(
          width: 230,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
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
                  itemBuilder: (_, i) => _ZoneTileRow(
                    zone: zones[i],
                    onTap: () => onZoneTap(zones[i]),
                    onToggle: () => onToggle(zones[i]),
                    onEdit: () => onEdit(zones[i]),
                    onDelete: () => onDelete(zones[i]),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _ZoneTileRow extends StatelessWidget {
  final ZoneEntity zone;
  final VoidCallback onTap, onToggle, onEdit, onDelete;

  const _ZoneTileRow({
    required this.zone,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(children: [
            GestureDetector(
              onTap: onToggle,
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
                    Text(zone.displayRadius,
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ]),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Iconsax.edit_2, size: 14, color: Colors.grey[500]),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Iconsax.trash, size: 14, color: Color(0xFFE24B4A)),
              ),
            ),
          ]),
        ),
      );
}
