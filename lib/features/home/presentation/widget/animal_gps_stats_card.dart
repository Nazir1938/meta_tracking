import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';

class AnimalDetailGpsStatsCard extends StatelessWidget {
  final AnimalEntity animal;
  final Position? livePosition;
  final ZoneEntity? assignedZone;

  const AnimalDetailGpsStatsCard({
    super.key,
    required this.animal,
    required this.livePosition,
    required this.assignedZone,
  });

  _ZoneDistResult? _calcZone() {
    if (assignedZone == null) return null;
    final lat = animal.lastLatitude;
    final lng = animal.lastLongitude;
    if (lat == null || lng == null) return null;

    final distToCenter = GeofencingService.calculateDistance(
        lat, lng, assignedZone!.latitude, assignedZone!.longitude);
    final distFromBorder = (distToCenter - assignedZone!.radiusInMeters).abs();

    return _ZoneDistResult(
      distToCenter: distToCenter,
      distFromBorder: distFromBorder,
      inside: animal.zoneStatus == AnimalZoneStatus.inside,
      zoneName: assignedZone!.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Sürət ────────────────────────────────────────────────────────────
    final rawSpeed = animal.speed ?? 0.0;
    final speedMs = rawSpeed < 0 ? 0.0 : rawSpeed;
    final speedKmh = speedMs * 3.6;
    final isMoving = speedKmh > 0.5;

    // ── Batareya — FIX ───────────────────────────────────────────────────
    // batteryLevel:
    //   null   → heç vaxt məlumat gəlməyib        → "Bilinmir"
    //   -1.0   → platform channel xəta verdi      → "Bilinmir"
    //   0..1   → real dəyər (0.0 da ola bilər)    → faiz göstər
    final rawBattery = animal.batteryLevel;
    final batteryKnown = rawBattery != null && rawBattery >= 0.0;
    final battery = batteryKnown ? rawBattery.clamp(0.0, 1.0) : 0.0;
    final batteryPct = (battery * 100).round();

    final batteryColor = !batteryKnown
        ? Colors.grey
        : battery > 0.5
            ? const Color(0xFF1D9E75)
            : battery > 0.2
                ? const Color(0xFFBA7517)
                : const Color(0xFFE24B4A);

    final batteryIcon = !batteryKnown
        ? Icons.battery_unknown_rounded
        : battery > 0.7
            ? Iconsax.battery_full
            : battery > 0.3
                ? Iconsax.battery_charging
                : Iconsax.battery_disable;

    final batteryText = !batteryKnown
        ? 'Bilinmir'
        : battery >= 0.99
            ? '$batteryPct% (Tam)'
            : battery > 0.5
                ? '$batteryPct% (Yaxşı)'
                : battery > 0.2
                    ? '$batteryPct% (Az)'
                    : '$batteryPct% (Kritik!)';

    // ── Koordinat ─────────────────────────────────────────────────────────
    final lat = animal.lastLatitude;
    final lng = animal.lastLongitude;
    final hasCoord = lat != null && lng != null;
    final coordText = hasCoord
        ? '${lat.toStringAsFixed(6)},  ${lng.toStringAsFixed(6)}'
        : 'GPS məlumatı yoxdur';

    final zoneResult = _calcZone();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(children: [
        // ── Sürət + Batareya ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            // Sürət dairəsi
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMoving
                    ? const Color(0xFF185FA5).withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                border: Border.all(
                  color: isMoving
                      ? const Color(0xFF185FA5).withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      speedKmh.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isMoving
                              ? const Color(0xFF185FA5)
                              : Colors.grey[400],
                          height: 1.1),
                    ),
                    Text('km/s',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500)),
                  ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hərəkət statusu
                    Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMoving
                              ? const Color(0xFF185FA5)
                              : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMoving ? 'Hərəkətdədir' : 'Dayanıb',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isMoving
                                ? const Color(0xFF185FA5)
                                : Colors.grey[500]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    // Batareya sırası
                    Row(children: [
                      Icon(batteryIcon, size: 14, color: batteryColor),
                      const SizedBox(width: 6),
                      if (batteryKnown)
                        SizedBox(
                          width: 52,
                          height: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: battery,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation(batteryColor),
                            ),
                          ),
                        ),
                      if (batteryKnown) const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          batteryText,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: batteryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ]),
            ),
          ]),
        ),

        Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),

        // ── Koordinat ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            if (!hasCoord) return;
            Clipboard.setData(ClipboardData(text: coordText));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Koordinat kopyalandı 📋'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Icon(Iconsax.location, size: 14, color: Color(0xFF1D9E75)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Canlı koordinatlar',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        coordText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasCoord
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey[400]),
                      ),
                    ]),
              ),
              if (hasCoord)
                Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
            ]),
          ),
        ),

        // ── Zona məsafəsi ─────────────────────────────────────────────────
        if (zoneResult != null) ...[
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _ZoneDistRow(result: zoneResult),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              Icon(Iconsax.location_cross, size: 13, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text('Zona təyin edilməyib',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
          ),
      ]),
    );
  }
}

// ─── Zona məsafəsi data class ─────────────────────────────────────────────────

class _ZoneDistResult {
  final double distToCenter, distFromBorder;
  final bool inside;
  final String zoneName;
  const _ZoneDistResult({
    required this.distToCenter,
    required this.distFromBorder,
    required this.inside,
    required this.zoneName,
  });
  String get borderLabel => distFromBorder < 1000
      ? '${distFromBorder.toStringAsFixed(0)} m'
      : '${(distFromBorder / 1000).toStringAsFixed(2)} km';
  String get centerLabel => distToCenter < 1000
      ? '${distToCenter.toStringAsFixed(0)} m'
      : '${(distToCenter / 1000).toStringAsFixed(2)} km';
}

class _ZoneDistRow extends StatelessWidget {
  final _ZoneDistResult result;
  const _ZoneDistRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final color =
        result.inside ? const Color(0xFF1D9E75) : const Color(0xFFE24B4A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(result.inside ? Iconsax.location_tick : Iconsax.location_cross,
            size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            result.inside
                ? '"${result.zoneName}" içindədir'
                : '"${result.zoneName}" xaricindədir',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            result.inside
                ? '${result.centerLabel} mərkəzdən'
                : '${result.borderLabel} kənara',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 5,
          child: LinearProgressIndicator(
            value: result.inside
                ? (1.0 -
                    (result.distToCenter /
                            (result.distToCenter + result.distFromBorder + 1))
                        .clamp(0.0, 1.0))
                : 0.0,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    ]);
  }
}
