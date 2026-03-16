import 'package:flutter/material.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class AnimalDetailActivityCard extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailActivityCard({super.key, required this.animal});

  static const _hours = [
    6, 5, 5, 5, 6, 8, 12, 22, 68, 82, 95, 88,
    38, 24, 28, 72, 100, 78, 48, 42, 24, 16, 10, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final rawSpeed = animal.speed ?? 0.0;
    final speedMs = rawSpeed < 0 ? 0.0 : rawSpeed;

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.grey.shade200, width: 0.5)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('${(speedMs * 3.5).toStringAsFixed(1)} km',
                    'Məsafə', const Color(0xFF1D9E75)),
                _stat('3.5 s', 'Hərəkət', const Color(0xFF185FA5)),
                _stat('4.5 s', 'Dinləmə', const Color(0xFFBA7517)),
                _stat('2 s', 'Otlama', const Color(0xFF0F6E56)),
              ]),
        ),
        const Divider(height: 1, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                _hours.length,
                (i) => Expanded(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 1),
                    height:
                        (_hours[i] / 100.0 * 46).clamp(4.0, 46.0),
                    decoration: BoxDecoration(
                      color: _hours[i] > 30
                          ? const Color(0xFF185FA5)
                          : const Color(0xFFE6F1FB),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['00', '06', '12', '18', '23']
                .map((t) => Text(t,
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey[400])))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String val, String label, Color color) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(fontSize: 9, color: Colors.grey[500])),
      ]);
}