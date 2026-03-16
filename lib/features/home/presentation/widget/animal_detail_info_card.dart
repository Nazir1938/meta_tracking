import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Info Card — ümumi məlumat kartı
// ─────────────────────────────────────────────────────────────────────────────

class AnimalDetailInfoCard extends StatelessWidget {
  final List<AnimalInfoRow> rows;
  const AnimalDetailInfoCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.grey.shade200, width: 0.5)),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 0.5))),
            child: Row(children: [
              Text(e.value.label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              e.value.customValue ??
                  Text(
                    e.value.value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: e.value.valueColor ??
                            const Color(0xFF1A1A2E)),
                    textAlign: TextAlign.right,
                  ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class AnimalInfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? customValue;
  const AnimalInfoRow(this.label, this.value,
      {this.valueColor, this.customValue});
}

// ─────────────────────────────────────────────────────────────────────────────
// Battery Widget — FIX: null / -1.0 → "Bilinmir"
// ─────────────────────────────────────────────────────────────────────────────

class AnimalBatteryWidget extends StatelessWidget {
  /// batteryLevel dəyərləri:
  ///   null veya -1.0  → "Bilinmir" (platform channel cavab verməyib)
  ///   0.0 .. 1.0      → real faiz
  final double? level;

  const AnimalBatteryWidget({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final known = level != null && level! >= 0.0;
    final pct = known ? (level! * 100).toInt() : 0;
    final val = known ? level!.clamp(0.0, 1.0) : 0.0;
    final color = !known
        ? Colors.grey
        : val > 0.5
            ? const Color(0xFF1D9E75)
            : val > 0.2
                ? const Color(0xFFBA7517)
                : const Color(0xFFE24B4A);

    if (!known) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.battery_unknown_rounded, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text('Bilinmir',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400])),
      ]);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 56, height: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('$pct%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class AnimalDetailSectionTitle extends StatelessWidget {
  final String title;
  const AnimalDetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Button
// ─────────────────────────────────────────────────────────────────────────────

class AnimalDetailDeleteButton extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailDeleteButton({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Iconsax.trash,
            size: 16, color: Color(0xFFE24B4A)),
        label: const Text('Heyvanı sil',
            style: TextStyle(
                color: Color(0xFFE24B4A),
                fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
              color: Color(0xFFE24B4A), width: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('${animal.typeEmoji} ${animal.name} silinsin?',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Bu əməliyyat geri alına bilməz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AnimalBloc>()
                  .add(DeleteAnimalEvent(animal.id));
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}