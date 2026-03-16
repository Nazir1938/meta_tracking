import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_detail_action_section.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_detail_activity_card.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_detail_info_card.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_detail_livetracking_panel.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_detail_location_card.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_gps_stats_card.dart';
import 'package:meta_tracking/features/home/presentation/widget/animal_screen_hero_section.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class AnimalDetailScreen extends StatefulWidget {
  final AnimalEntity animal;
  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  StreamSubscription<Position>? _gpsSub;
  Timer? _sendTimer;
  Position? _lastPosition;
  bool _isTracking = false;
  int _intervalSeconds = 30;
  int _sentCount = 0;
  DateTime? _lastSentTime;

  static const _intervalOptions = [10, 30, 60, 120];

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _startTracking() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied)
      p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever ||
        (p != LocationPermission.whileInUse &&
            p != LocationPermission.always)) {
      _snack('GPS icazəsi verilmədi', isError: true);
      return;
    }
    // ignore: use_build_context_synchronously
    context.read<AnimalBloc>().add(StartTrackingEvent(widget.animal.id));
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 0),
    ).listen(
      (pos) => setState(() => _lastPosition = pos),
      onError: (e) =>
          AppLogger.xeta('DETAIL TRACKING', 'GPS xəta', xetaObyekti: e),
    );
    _sendTimer = Timer.periodic(
        Duration(seconds: _intervalSeconds), (_) => _sendPosition());
    final firstPos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    if (!mounted) return;
    setState(() {
      _lastPosition = firstPos;
      _isTracking = true;
    });
    _sendPosition();
    AppLogger.ugur('DETAIL TRACKING',
        '${widget.animal.name} başladı — ${_intervalSeconds}s');
  }

  void _sendPosition() {
    if (_lastPosition == null || !mounted) return;
    context.read<AnimalBloc>().add(UpdateLocationEvent(
          animalId: widget.animal.id,
          lat: _lastPosition!.latitude,
          lng: _lastPosition!.longitude,
          speed: _lastPosition!.speed < 0 ? 0 : _lastPosition!.speed,
          battery: 1.0,
        ));
    setState(() {
      _sentCount++;
      _lastSentTime = DateTime.now();
    });
  }

  Future<void> _stopTracking() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    _sendTimer?.cancel();
    _sendTimer = null;
    if (mounted) {
      context.read<AnimalBloc>().add(StopTrackingEvent(widget.animal.id));
      setState(() => _isTracking = false);
    }
    AppLogger.xeberdarliq(
        'DETAIL TRACKING', '${widget.animal.name} dayandırıldı');
  }

  void _toggleTracking() => _isTracking ? _stopTracking() : _startTracking();

  void _showIntervalPicker() {
    if (_isTracking) {
      _snack('İzləməni dayandırıb intervalı dəyişin');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalDetailIntervalSheet(
        selected: _intervalSeconds,
        options: _intervalOptions,
        onSelect: (v) {
          setState(() => _intervalSeconds = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: BlocBuilder<ZoneBloc, ZoneState>(
        builder: (context, zoneState) {
          ZoneEntity? assignedZone;
          if (zoneState is ZonesLoaded && widget.animal.zoneId != null) {
            try {
              assignedZone = zoneState.zones
                  .firstWhere((z) => z.id == widget.animal.zoneId);
            } catch (_) {}
          }

          return BlocBuilder<AnimalBloc, AnimalState>(
            builder: (context, state) {
              AnimalEntity animal = widget.animal;
              if (state is AnimalLoaded) {
                try {
                  animal =
                      state.animals.firstWhere((a) => a.id == widget.animal.id);
                } catch (_) {}
              }

              return Scaffold(
                backgroundColor: const Color(0xFFF4F6F9),
                body: CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: AnimalDetailHeroSection(animal: animal)),
                  SliverToBoxAdapter(
                      child: AnimalDetailActionButtons(animal: animal)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const AnimalDetailSectionTitle(title: 'Canlı İzləmə'),
                        const SizedBox(height: 8),
                        AnimalDetailLiveTrackingPanel(
                          isTracking: _isTracking,
                          intervalSeconds: _intervalSeconds,
                          lastPosition: _lastPosition,
                          sentCount: _sentCount,
                          lastSentTime: _lastSentTime,
                          animal: animal,
                          onToggle: _toggleTracking,
                          onIntervalTap: _showIntervalPicker,
                        ),
                        const SizedBox(height: 16),
                        const AnimalDetailSectionTitle(
                            title: 'GPS Statistikası'),
                        const SizedBox(height: 8),
                        AnimalDetailGpsStatsCard(
                          animal: animal,
                          livePosition: _lastPosition,
                          assignedZone: assignedZone,
                        ),
                        const SizedBox(height: 16),
                        const AnimalDetailSectionTitle(title: 'Canlı mövqe'),
                        const SizedBox(height: 8),
                        AnimalDetailLocationCard(animal: animal),
                        const SizedBox(height: 16),
                        const AnimalDetailSectionTitle(title: 'GPS cihazı'),
                        const SizedBox(height: 8),
                        AnimalDetailInfoCard(rows: [
                          AnimalInfoRow(
                              'Çip ID', animal.chipId ?? 'Təyin edilməyib'),
                          AnimalInfoRow(
                              'Son yeniləmə', _formatTime(animal.lastUpdate),
                              valueColor: const Color(0xFF185FA5)),
                          // FIX: batteryLevel null və ya -1 → "Bilinmir"
                          AnimalInfoRow('Batareya', '',
                              customValue: AnimalBatteryWidget(
                                  level: animal.batteryLevel)),
                          AnimalInfoRow('Status',
                              animal.isTracking ? 'Onlayn' : 'Offline',
                              valueColor: animal.isTracking
                                  ? const Color(0xFF1D9E75)
                                  : Colors.grey),
                        ]),
                        const SizedBox(height: 16),
                        const AnimalDetailSectionTitle(
                            title: 'Bu günkü aktivlik'),
                        const SizedBox(height: 8),
                        AnimalDetailActivityCard(animal: animal),
                        const SizedBox(height: 16),
                        const AnimalDetailSectionTitle(
                            title: 'Heyvan məlumatları'),
                        const SizedBox(height: 8),
                        AnimalDetailInfoCard(rows: [
                          AnimalInfoRow('Növ', animal.typeName),
                          AnimalInfoRow(
                              'Zona', animal.zoneName ?? 'Təyin edilməyib'),
                          AnimalInfoRow(
                              'Sürət',
                              animal.speed != null
                                  ? '${((animal.speed! < 0 ? 0 : animal.speed!) * 3.6).toStringAsFixed(1)} km/s'
                                  : '—'),
                          AnimalInfoRow(
                              'Son mövqe',
                              animal.lastLatitude != null
                                  ? '${animal.lastLatitude!.toStringAsFixed(5)}, ${animal.lastLongitude!.toStringAsFixed(5)}'
                                  : 'Məlumat yoxdur'),
                          if (animal.notes != null && animal.notes!.isNotEmpty)
                            AnimalInfoRow('Qeyd', animal.notes!),
                        ]),
                        const SizedBox(height: 16),
                        AnimalDetailDeleteButton(animal: animal),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Naməlum';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq əvvəl';
    if (diff.inHours < 24) return '${diff.inHours} saat əvvəl';
    return '${diff.inDays} gün əvvəl';
  }
}
