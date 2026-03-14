import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TrackingSummaryCards extends StatelessWidget {
  final int total;
  final int active;
  final int inside;
  final int alert;

  const TrackingSummaryCards({
    super.key,
    required this.total,
    required this.active,
    required this.inside,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        _card('Ümumi', '$total', const Color(0xFF6C63FF), Iconsax.pet),
        const SizedBox(width: 8),
        _card('Aktiv', '$active', const Color(0xFF2ECC71), Iconsax.location),
        const SizedBox(width: 8),
        _card('İçərdə', '$inside', const Color(0xFF3498DB), Iconsax.home),
        const SizedBox(width: 8),
        _card('Alert', '$alert', const Color(0xFFFF4444), Iconsax.warning_2),
      ]),
    );
  }

  Widget _card(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
