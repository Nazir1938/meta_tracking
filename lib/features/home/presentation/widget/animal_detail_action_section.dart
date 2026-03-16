import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/add_animal_sheet.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class AnimalDetailActionButtons extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailActionButtons({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.map,
            label: 'Xəritədə bax',
            color: const Color(0xFF1D9E75),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MapScreen(
                    highlightedAnimalIds: [animal.id],
                    animalEntities: [animal]))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.edit,
            label: 'Redaktə et',
            color: const Color(0xFF185FA5),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddAnimalSheet(
                ownerId: animal.ownerId,
                existingAnimal: animal,
                onSubmit: (name, type, chipId, notes, zoneId, zoneName) {
                  context.read<AnimalBloc>().add(EditAnimalEvent(
                        animalId: animal.id,
                        name: name,
                        type: type,
                        chipId: chipId.isNotEmpty ? chipId : null,
                        notes: notes.isNotEmpty ? notes : null,
                        zoneId: zoneId,
                        zoneName: zoneName,
                      ));
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.radar,
            label: 'Kayıb modu',
            color: const Color(0xFFE24B4A),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Kayıb modu',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                content:
                    Text('"${animal.name}" üçün kayıb modu aktiv edilsin?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İmtina',
                          style: TextStyle(color: Colors.grey[500]))),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('Aktiv et',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}