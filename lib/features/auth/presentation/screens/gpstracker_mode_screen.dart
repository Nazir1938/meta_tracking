import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GPS Yayıcı Rejimi — v2
//
// Düzəltmələr:
// 1. Hər 5 saniyədən bir Timer.periodic ilə göndərmə — distanceFilter sıfır
// 2. battery_plus ilə real batareya oxunur
// 3. GPS stream bağlansa belə timer işləyir — sabit aktiv qalır
// 4. Ekrandan çıxsaq belə _isRunning true qalır (dispose-da stop yoxdur)
// ─────────────────────────────────────────────────────────────────────────────

class GpsTrackerModeScreen extends StatefulWidget {
  const GpsTrackerModeScreen({super.key});

  @override
  State<GpsTrackerModeScreen> createState() => _GpsTrackerModeScreenState();
}

class _GpsTrackerModeScreenState extends State<GpsTrackerModeScreen> {
  AnimalEntity? _selectedAnimal;
  StreamSubscription<Position>? _gpsSub;
  Timer? _sendTimer;
  bool _isRunning = false;
  Position? _lastPosition;
  int _updateCount = 0;
  String? _currentZoneName;
  DateTime? _lastUpdateTime;
  double _batteryLevel = 1.0;

  static const _sendInterval = Duration(seconds: 5);
  final _battery = Battery();

  // ── GPS başlat ────────────────────────────────────────────────────────────
  Future<void> _start() async {
    if (_selectedAnimal == null) {
      _snack('Əvvəlcə heyvan seçin', isError: true);
      return;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied)
      p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever ||
        (p != LocationPermission.whileInUse &&
            p != LocationPermission.always)) {
      _snack('GPS icazəsi verilmədi', isError: true);
      return;
    }

    setState(() {
      _isRunning = true;
      _updateCount = 0;
    });
    AppLogger.ugur('GPS TRACKER MODE', 'Başladı: ${_selectedAnimal!.name}');

    // GPS stream — distanceFilter: 0 → hər yeniləmə
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (pos) {
        if (mounted) setState(() => _lastPosition = pos);
        _updateZoneName(pos);
      },
      onError: (e) =>
          AppLogger.xeta('GPS TRACKER MODE', 'GPS xətası', xetaObyekti: e),
    );

    // İlk mövqeyi dərhal al
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _lastPosition = pos);
      _updateZoneName(pos);
    } catch (_) {}

    // Hər 5 saniyədən bir göndər
    _sendTimer = Timer.periodic(_sendInterval, (_) => _sendPosition());
    _sendPosition(); // ilk göndərmə dərhal
  }

  void _updateZoneName(Position pos) {
    final zoneState = context.read<ZoneBloc>().state;
    if (zoneState is! ZonesLoaded) return;
    String? zoneName;
    for (final zone in zoneState.zones) {
      if (_isInsideZone(pos.latitude, pos.longitude, zone)) {
        zoneName = zone.name;
        break;
      }
    }
    if (mounted) setState(() => _currentZoneName = zoneName);
  }

  Future<void> _sendPosition() async {
    if (!_isRunning || !mounted) return;
    final pos = _lastPosition;
    if (pos == null) return;

    // Batareyani oxu
    try {
      final level = await _battery.batteryLevel;
      _batteryLevel = level / 100.0;
    } catch (_) {}

    if (!mounted) return;
    context.read<AnimalBloc>().add(UpdateLocationEvent(
          animalId: _selectedAnimal!.id,
          lat: pos.latitude,
          lng: pos.longitude,
          speed: pos.speed < 0 ? 0 : pos.speed,
          battery: _batteryLevel,
        ));

    setState(() {
      _updateCount++;
      _lastUpdateTime = DateTime.now();
    });

    AppLogger.melumat(
        'GPS TRACKER MODE',
        '${_selectedAnimal!.name} → (${pos.latitude.toStringAsFixed(5)}, '
            '${pos.longitude.toStringAsFixed(5)}) bat:${(_batteryLevel * 100).round()}%');
  }

  bool _isInsideZone(double lat, double lng, ZoneEntity zone) {
    if (zone.zoneType == ZoneType.polygon && zone.polygonPoints.length >= 3) {
      return _pointInPolygon(lat, lng, zone.polygonPoints);
    }
    final dist =
        Geolocator.distanceBetween(lat, lng, zone.latitude, zone.longitude);
    return dist <= zone.radiusInMeters;
  }

  bool _pointInPolygon(double lat, double lng, List<ZoneLatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  Future<void> _stop() async {
    _sendTimer?.cancel();
    _sendTimer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    if (mounted) setState(() => _isRunning = false);
    AppLogger.xeberdarliq('GPS TRACKER MODE', 'Dayandırıldı');
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
  void dispose() {
    // Ekrandan çıxanda GPS davam edir istəyirsə — burada stop etmirik.
    // İstifadəçi "Dayandır" düyməsinə basmalıdır.
    // Ancaq widget unmount olduqda timer/stream-i silmək lazımdır ki leak olmasın:
    _sendTimer?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, size: 20),
            onPressed: () async {
              if (_isRunning) await _stop();
              if (mounted) Navigator.pop(context);
            },
          ),
          title: const Text('GPS Yayıcı Rejimi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          centerTitle: true,
        ),
        body: BlocBuilder<AnimalBloc, AnimalState>(
          builder: (context, state) {
            final animals =
                state is AnimalLoaded ? state.animals : <AnimalEntity>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBanner(),
                  const SizedBox(height: 20),
                  _sectionTitle('Heyvan seçin'),
                  const SizedBox(height: 8),
                  _AnimalSelector(
                    animals: animals,
                    selected: _selectedAnimal,
                    isRunning: _isRunning,
                    onSelect: (a) => setState(() => _selectedAnimal = a),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedAnimal != null) ...[
                    _sectionTitle('Canlı Status'),
                    const SizedBox(height: 8),
                    _LiveStatusCard(
                      isRunning: _isRunning,
                      position: _lastPosition,
                      updateCount: _updateCount,
                      zoneName: _currentZoneName,
                      lastUpdateTime: _lastUpdateTime,
                      batteryLevel: _batteryLevel,
                      animalName: _selectedAnimal!.name,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _StartStopButton(
                    isRunning: _isRunning,
                    hasAnimal: _selectedAnimal != null,
                    onStart: _start,
                    onStop: _stop,
                  ),
                  const SizedBox(height: 24),
                  _TestInstructions(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)));
}

// ── Info Banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF185FA5).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF185FA5).withValues(alpha: 0.2), width: 0.5),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Iconsax.info_circle, color: Color(0xFF185FA5), size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Bu rejim ikinci telefonla GPS testini asanlaşdırır.\n'
            'Hər 5 saniyədən bir koordinat, batareya və sürət göndərilir.\n'
            'Birinci telefonunuzda bildiriş gəlməsini izləyin.',
            style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: Color(0xFF185FA5),
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

// ── Animal Selector ───────────────────────────────────────────────────────────
class _AnimalSelector extends StatelessWidget {
  final List<AnimalEntity> animals;
  final AnimalEntity? selected;
  final bool isRunning;
  final ValueChanged<AnimalEntity> onSelect;

  const _AnimalSelector(
      {required this.animals,
      required this.selected,
      required this.isRunning,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (animals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200)),
        child: const Center(
            child: Text('Heyvan tapılmadı',
                style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: animals.map((animal) {
          final isSelected = selected?.id == animal.id;
          final isLast = animals.last.id == animal.id;
          return GestureDetector(
            onTap: isRunning ? null : () => onSelect(animal),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1D9E75).withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(14))
                    : BorderRadius.zero,
                border: !isLast
                    ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                    : null,
              ),
              child: Row(children: [
                Text(animal.typeEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(animal.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      if (animal.chipId != null)
                        Text('Çip: ${animal.chipId}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                    ])),
                if (isSelected)
                  const Icon(Iconsax.tick_circle,
                      color: Color(0xFF1D9E75), size: 20)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: Colors.grey[300], size: 20),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Live Status Card ──────────────────────────────────────────────────────────
class _LiveStatusCard extends StatelessWidget {
  final bool isRunning;
  final Position? position;
  final int updateCount;
  final String? zoneName;
  final DateTime? lastUpdateTime;
  final double batteryLevel;
  final String animalName;

  const _LiveStatusCard(
      {required this.isRunning,
      required this.position,
      required this.updateCount,
      required this.zoneName,
      required this.lastUpdateTime,
      required this.batteryLevel,
      required this.animalName});

  @override
  Widget build(BuildContext context) {
    final batPct = (batteryLevel * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? const Color(0xFF1D9E75) : Colors.grey)),
          const SizedBox(width: 8),
          Text(isRunning ? '● Yayım aktiv — hər 5s' : '○ Yayım dayandırılıb',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isRunning ? const Color(0xFF1D9E75) : Colors.grey)),
          const Spacer(),
          if (updateCount > 0)
            Text('$updateCount yeniləmə',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ]),
        const SizedBox(height: 14),
        _row(
            Iconsax.location,
            'Koordinat',
            position != null
                ? '${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}'
                : 'GPS gözlənilir...',
            const Color(0xFF185FA5)),
        const SizedBox(height: 10),
        _row(
            Iconsax.speedometer,
            'Sürət',
            position != null
                ? '${((position!.speed < 0 ? 0 : position!.speed) * 3.6).toStringAsFixed(1)} km/h'
                : '—',
            const Color(0xFFBA7517)),
        const SizedBox(height: 10),
        _row(
            Iconsax.battery_charging,
            'Batareya',
            '$batPct%',
            batPct > 50
                ? const Color(0xFF1D9E75)
                : batPct > 20
                    ? const Color(0xFFBA7517)
                    : const Color(0xFFE24B4A)),
        const SizedBox(height: 10),
        _row(
            Iconsax.location_tick,
            'Zona',
            zoneName != null ? '✓ $zoneName' : '✗ Zona xaricindədir',
            zoneName != null
                ? const Color(0xFF1D9E75)
                : const Color(0xFFE24B4A)),
        if (lastUpdateTime != null) ...[
          const SizedBox(height: 10),
          _row(
              Iconsax.clock,
              'Son göndərmə',
              '${lastUpdateTime!.hour.toString().padLeft(2, '0')}:'
                  '${lastUpdateTime!.minute.toString().padLeft(2, '0')}:'
                  '${lastUpdateTime!.second.toString().padLeft(2, '0')}',
              Colors.grey),
        ],
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text('$label:', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      const SizedBox(width: 6),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis)),
    ]);
  }
}

// ── Start / Stop Button ───────────────────────────────────────────────────────
class _StartStopButton extends StatelessWidget {
  final bool isRunning, hasAnimal;
  final VoidCallback onStart, onStop;
  const _StartStopButton(
      {required this.isRunning,
      required this.hasAnimal,
      required this.onStart,
      required this.onStop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: hasAnimal ? (isRunning ? onStop : onStart) : null,
        icon: Icon(isRunning ? Iconsax.pause : Iconsax.play, size: 20),
        label: Text(isRunning ? 'Dayandır' : 'GPS Yayımını Başlat',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isRunning ? const Color(0xFFE24B4A) : const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ── Test Instructions ─────────────────────────────────────────────────────────
class _TestInstructions extends StatelessWidget {
  static const _steps = [
    'Birinci telefonda (ana tətbiq): Xəritə tabını açın, bir zona çəkin və onu aktivləşdirin.',
    'Bu telefonda (ikinci telefon): Yuxarıdan bir heyvan seçin.',
    '"GPS Yayımını Başlat" düyməsinə basın.',
    'Bu telefonu çizilib zona daxilindəyisə, çölə çıxarın.',
    'Birinci telefonda zona çıxış bildirişi gəlməlidir.',
    'Zona içinə qayıdanda isə zona giriş bildirişi gəlir.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Iconsax.document_text, color: Colors.grey, size: 16),
          SizedBox(width: 8),
          Text('Test Təlimatları',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 10),
        ..._steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.key + 1}. ',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75))),
                Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.grey[600]))),
              ]),
            )),
      ]),
    );
  }
}
