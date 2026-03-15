import 'package:flutter/material.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

/// Heyvanın heç bir zonaya təyin edilmədiyini göstərən sheet.
class AnimalNoZoneSheet extends StatelessWidget {
  final AnimalEntity animal;

  const AnimalNoZoneSheet({super.key, required this.animal});

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
        // Handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        // Emoji
        Text(animal.typeEmoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),

        // Ad
        Text(animal.name,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),

        // Zona yoxdur badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE24B4A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Hər hansı bir eraziyə təyin edilməyib',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFFE24B4A),
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),

        // İzahat
        Text(
          'Heyvana erazi təyin etmək üçün xəritədə bir eraziyə toxunun '
          'və "Əlavə et" tabından bu heyvanı seçin.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Bağla düyməsi
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
