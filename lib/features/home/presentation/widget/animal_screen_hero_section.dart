import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class AnimalDetailHeroSection extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailHeroSection({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isAlert = animal.zoneStatus == AnimalZoneStatus.alert;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: top + 10, left: 20, right: 20, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(children: [
            Icon(Icons.chevron_left_rounded, color: Color(0xFF1D9E75), size: 22),
            Text('Geri',
                style: TextStyle(
                    color: Color(0xFF1D9E75), fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _typeColor(animal.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: isAlert
                  ? Border.all(
                      color: const Color(0xFFE24B4A).withValues(alpha: 0.4),
                      width: 1.5)
                  : null,
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(animal.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 3),
              Text(
                  '${animal.typeName} · ${_formatCreated(animal.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                AnimalDetailBadge(
                    label: animal.isTracking ? 'Canlı izləmə' : 'Offline',
                    color: animal.isTracking
                        ? const Color(0xFF185FA5)
                        : Colors.grey,
                    icon: Iconsax.radar),
                if (animal.zoneName != null)
                  AnimalDetailBadge(
                      label: animal.zoneName!,
                      color: Colors.grey,
                      icon: Iconsax.home),
                if ((animal.batteryLevel ?? 1) < 0.3)
                  const AnimalDetailBadge(
                      label: 'Pil az',
                      color: Color(0xFFBA7517),
                      icon: Iconsax.battery_disable),
                if (isAlert)
                  const AnimalDetailBadge(
                      label: 'ALERT',
                      color: Color(0xFFE24B4A),
                      icon: Iconsax.warning_2),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Color _typeColor(AnimalType t) {
    switch (t) {
      case AnimalType.cattle: return const Color(0xFF8B5E3C);
      case AnimalType.sheep:  return const Color(0xFF9B9B9B);
      case AnimalType.horse:  return const Color(0xFF185FA5);
      case AnimalType.goat:   return const Color(0xFF7B9E5E);
      case AnimalType.pig:    return const Color(0xFFFF8FAB);
      case AnimalType.other:  return const Color(0xFF6C63FF);
    }
  }

  String _formatCreated(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    return diff < 30 ? '$diff gün əvvəl' : '${(diff / 30).floor()} ay əvvəl';
  }
}

class AnimalDetailBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const AnimalDetailBadge(
      {super.key,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}