import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class AnimalDetailLiveTrackingPanel extends StatelessWidget {
  final bool isTracking;
  final int intervalSeconds;
  final Position? lastPosition;
  final int sentCount;
  final DateTime? lastSentTime;
  final AnimalEntity animal;
  final VoidCallback onToggle;
  final VoidCallback onIntervalTap;

  const AnimalDetailLiveTrackingPanel({
    super.key,
    required this.isTracking,
    required this.intervalSeconds,
    required this.lastPosition,
    required this.sentCount,
    required this.lastSentTime,
    required this.animal,
    required this.onToggle,
    required this.onIntervalTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1D9E75);
    final color = isTracking ? activeColor : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTracking
              ? activeColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isTracking ? 1 : 0.5,
        ),
      ),
      child: Column(children: [
        // ── Başlıq + Toggle ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTracking ? activeColor : Colors.grey.shade300,
                boxShadow: isTracking
                    ? [
                        BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTracking ? 'Yayım Aktiv' : 'Yayım Deaktiv',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isTracking
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey),
                    ),
                    if (isTracking && lastSentTime != null)
                      Text(
                          'Son: ${_fmt(lastSentTime!)} · $sentCount dəfə',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500]))
                    else
                      Text(
                          'Hər ${_intervalLabel(intervalSeconds)} göndərilir',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ]),
            ),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52, height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color:
                      isTracking ? activeColor : Colors.grey.shade300,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: isTracking
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Icon(
                          isTracking ? Iconsax.pause : Iconsax.play,
                          size: 12,
                          color:
                              isTracking ? activeColor : Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Divider(height: 1, thickness: 0.5),
        ),

        // ── İnterval + Koordinat ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onIntervalTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.timer, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(_intervalLabel(intervalSeconds),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color)),
                        if (!isTracking) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded,
                              size: 11,
                              color: color.withValues(alpha: 0.6)),
                        ],
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.grey.shade200, width: 0.5),
                ),
                child: Row(children: [
                  Icon(Iconsax.location,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastPosition != null
                          ? '${lastPosition!.latitude.toStringAsFixed(5)}\n'
                              '${lastPosition!.longitude.toStringAsFixed(5)}'
                          : isTracking
                              ? 'GPS gözlənilir...'
                              : '—',
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: lastPosition != null
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey[400],
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),

        // ── Zona statusu (yalnız aktiv izləmədə) ────────────────────────
        if (isTracking)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _zoneColor(animal.zoneStatus).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _zoneColor(animal.zoneStatus)
                      .withValues(alpha: 0.25),
                  width: 0.5),
            ),
            child: Row(children: [
              Icon(
                animal.zoneStatus == AnimalZoneStatus.inside
                    ? Iconsax.location_tick
                    : Iconsax.location_cross,
                size: 14,
                color: _zoneColor(animal.zoneStatus),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  animal.zoneStatus == AnimalZoneStatus.inside
                      ? '${animal.name} "${animal.zoneName ?? "zona"}" içindədir'
                      : '${animal.name} zona xaricindədir',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _zoneColor(animal.zoneStatus)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Color _zoneColor(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:  return const Color(0xFF1D9E75);
      case AnimalZoneStatus.outside: return const Color(0xFF185FA5);
      case AnimalZoneStatus.alert:   return const Color(0xFFE24B4A);
    }
  }

  String _intervalLabel(int s) => s < 60 ? '${s}s' : '${s ~/ 60}dəq';

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// İnterval Seçim Sheet
// ─────────────────────────────────────────────────────────────────────────────

class AnimalDetailIntervalSheet extends StatelessWidget {
  final int selected;
  final List<int> options;
  final ValueChanged<int> onSelect;

  const AnimalDetailIntervalSheet({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Row(children: [
          Icon(Iconsax.timer, color: Color(0xFF1D9E75), size: 18),
          SizedBox(width: 8),
          Text('GPS Göndərmə İntervalı',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(
            'Heyvanın mövqeyi neçə saniyədən bir Firestore-a yazılsın?',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 16),
        ...options.map((s) {
          final isSelected = s == selected;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1D9E75).withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1D9E75).withValues(alpha: 0.4)
                      : Colors.grey.shade200,
                  width: isSelected ? 1 : 0.5,
                ),
              ),
              child: Row(children: [
                Icon(
                    isSelected
                        ? Iconsax.tick_circle
                        : Iconsax.timer_1,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF1D9E75)
                        : Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_label(s),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF1A1A2E)
                                    : Colors.grey[600])),
                        Text(_desc(s),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400])),
                      ]),
                ),
                if (isSelected)
                  const Text('Seçili',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  String _label(int s) {
    switch (s) {
      case 10:  return 'Hər 10 saniyə';
      case 30:  return 'Hər 30 saniyə';
      case 60:  return 'Hər 1 dəqiqə';
      case 120: return 'Hər 2 dəqiqə';
      default:  return 'Hər ${s}s';
    }
  }

  String _desc(int s) {
    switch (s) {
      case 10:  return 'Yüksək dəqiqlik · Batareya tez tükənir';
      case 30:  return 'Tövsiyə olunan · Test üçün ideal';
      case 60:  return 'Orta dəqiqlik · Batareya uzun davam edir';
      case 120: return 'Az tezlik · Uzun müddətli izləmə üçün';
      default:  return '';
    }
  }
}