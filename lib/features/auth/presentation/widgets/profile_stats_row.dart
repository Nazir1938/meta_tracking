import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class ProfileStatsRow extends StatelessWidget {
  final List<AnimalEntity> animals;

  const ProfileStatsRow({super.key, required this.animals});

  @override
  Widget build(BuildContext context) {
    final activeCount = animals.where((a) => a.isTracking).length;
    final alertCount =
        animals.where((a) => a.zoneStatus == AnimalZoneStatus.alert).length;
    final avgBattery = animals.isEmpty
        ? 0
        : (animals
                    .where((a) => a.batteryLevel != null)
                    .fold(0.0, (s, a) => s + (a.batteryLevel ?? 0)) /
                animals.length *
                100)
            .toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        _statItem('${animals.length}', 'Heyvan',
            Iconsax.pet, const Color(0xFF2ECC71)),
        _vDivider(),
        _statItem('$activeCount', 'Aktiv',
            Iconsax.location, const Color(0xFF3498DB)),
        _vDivider(),
        _statItem('$alertCount', 'Alert',
            Iconsax.warning_2, const Color(0xFFFF4444)),
        _vDivider(),
        _statItem('$avgBattery%', 'Batareya',
            Iconsax.battery_charging, const Color(0xFF9B59B6)),
      ]),
    );
  }

  Widget _statItem(
      String val, String lbl, IconData icon, Color color) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(val,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        Text(lbl,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 44, color: const Color(0xFFF0F2F5));
}