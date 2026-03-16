import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
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
  int _sentCount = 0;
  DateTime? _lastSentTime;

  // FIX: Sabit 5 saniyə — seçim yoxdur, intervalOptions silinib
  static const _sendInterval = Duration(seconds: 5);
  static const _intervalSeconds = 5;

  final _battery = Battery();
  double _batteryLevel = 1.0;

  @override
  void dispose() {
    // FIX: dispose-da tracking-i DAYANDIRMIRIQ — istifadəçi manual bağlamalıdır.
    // Sadəcə timer/stream-i widget-dən ayırırıq.
    _sendTimer?.cancel();
    _gpsSub?.cancel();
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

    // Firestore-da isTracking = true
    // ignore: use_build_context_synchronously
    context.read<AnimalBloc>().add(StartTrackingEvent(widget.animal.id));

    // GPS stream — anlıq mövqe yeniləmə üçün
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 0),
    ).listen(
      (pos) {
        if (mounted) setState(() => _lastPosition = pos);
      },
      onError: (e) =>
          AppLogger.xeta('DETAIL TRACKING', 'GPS xəta', xetaObyekti: e),
    );

    // İlk mövqe
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _lastPosition = pos);
    } catch (_) {}

    // Hər 5 saniyədən bir Firestore-a göndər
    _sendTimer = Timer.periodic(_sendInterval, (_) => _sendPosition());

    setState(() {
      _isTracking = true;
      _sentCount = 0;
    });
    _sendPosition(); // ilk göndərmə dərhal
    AppLogger.ugur(
        'DETAIL TRACKING', '${widget.animal.name} başladı — 5s interval');
  }

  Future<void> _sendPosition() async {
    if (!_isTracking || !mounted) return;
    final pos = _lastPosition;
    if (pos == null) return;

    // Batareyani oxu
    try {
      final level = await _battery.batteryLevel;
      _batteryLevel = level / 100.0;
    } catch (_) {
      _batteryLevel = 1.0;
    }

    if (!mounted) return;
    context.read<AnimalBloc>().add(UpdateLocationEvent(
          animalId: widget.animal.id,
          lat: pos.latitude,
          lng: pos.longitude,
          speed: pos.speed < 0 ? 0 : pos.speed,
          battery: _batteryLevel,
        ));
    setState(() {
      _sentCount++;
      _lastSentTime = DateTime.now();
    });
  }

  Future<void> _stopTracking() async {
    _sendTimer?.cancel();
    _sendTimer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    if (mounted) {
      context.read<AnimalBloc>().add(StopTrackingEvent(widget.animal.id));
      setState(() => _isTracking = false);
    }
    AppLogger.xeberdarliq(
        'DETAIL TRACKING', '${widget.animal.name} dayandırıldı');
  }

  // Toggle — açıq qalır, sadəcə düymə ilə bağlanır
  void _toggleTracking() => _isTracking ? _stopTracking() : _startTracking();

  // Interval picker artıq yoxdur (5s sabit), ama panel hələ onIntervalTap istəyir
  void _onIntervalTap() {
    _snack('Göndərmə intervalı: 5 saniyə (sabit)');
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
                          onIntervalTap: _onIntervalTap,
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

// ── Section Title ─────────────────────────────────────────────────────────────
class AnimalDetailSectionTitle extends StatelessWidget {
  final String title;
  const AnimalDetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E)));
  }
}

// ── Delete Button ─────────────────────────────────────────────────────────────
class AnimalDetailDeleteButton extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailDeleteButton({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${animal.typeEmoji} ${animal.name} silinsin?',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: const Text('Bu əməliyyat geri alına bilməz.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İmtina')),
            TextButton(
              onPressed: () {
                context.read<AnimalBloc>().add(DeleteAnimalEvent(animal.id));
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child:
                  const Text('Sil', style: TextStyle(color: Color(0xFFE24B4A))),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE24B4A).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.2),
              width: 0.5),
        ),
        child: const Center(
          child: Text('Heyvanı Sil',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE24B4A))),
        ),
      ),
    );
  }
}
