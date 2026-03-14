import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/add_animal_sheet.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class AnimalListCard extends StatelessWidget {
  final AnimalEntity animal;
  final bool isSelected;
  final bool selectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimalListCard({
    super.key,
    required this.animal,
    required this.isSelected,
    required this.selectMode,
    required this.onTap,
    required this.onLongPress,
  });

  void _openOnMap(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MapScreen(
        highlightedAnimalIds: [animal.id],
        animalEntities: [animal],
      ),
    ));
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
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
          _showTopSnack(context, '"$name" yeniləndi', const Color(0xFF2ECC71));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${animal.typeEmoji} ${animal.name} silinsin?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Bu əməliyyat geri alına bilməz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ləğv et', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AnimalBloc>().add(DeleteAnimalEvent(animal.id));
              _showTopSnack(
                  context, '"${animal.name}" silindi', Colors.red.shade400);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTopSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(animal.zoneStatus);
    final statusLabel = _statusLabel(animal.zoneStatus);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: selectMode ? onTap : () => _openOnMap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : animal.zoneStatus == AnimalZoneStatus.alert
                    ? const Color(0xFFFF4444).withValues(alpha: 0.3)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            if (selectMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2ECC71)
                        : Colors.grey.shade300,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _typeColor(animal.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(animal.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Iconsax.location, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          animal.zoneName ?? 'Zona təyin edilməyib',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Iconsax.clock, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(_formatTime(animal.lastUpdate),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      if (animal.batteryLevel != null) ...[
                        Icon(
                          animal.batteryLevel! > 0.2
                              ? Iconsax.battery_charging
                              : Iconsax.battery_disable,
                          size: 12,
                          color: animal.batteryLevel! > 0.2
                              ? const Color(0xFF2ECC71)
                              : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text('${(animal.batteryLevel! * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: animal.batteryLevel! > 0.2
                                  ? const Color(0xFF2ECC71)
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: animal.isTracking
                              ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: animal.isTracking
                                      ? const Color(0xFF2ECC71)
                                      : Colors.grey,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(animal.isTracking ? 'Canlı' : 'Offline',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: animal.isTracking
                                      ? const Color(0xFF2ECC71)
                                      : Colors.grey)),
                        ]),
                      ),
                      const Spacer(),
                      if (!selectMode) ...[
                        // Xəritədə gör
                        GestureDetector(
                          onTap: () => _openOnMap(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Iconsax.map,
                                size: 13, color: Color(0xFF2ECC71)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => _showEditSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3498DB)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Iconsax.edit_2,
                                size: 13, color: Color(0xFF3498DB)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => _confirmDelete(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4444)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Iconsax.trash,
                                size: 13, color: Color(0xFFFF4444)),
                          ),
                        ),
                      ],
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Color _statusColor(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return const Color(0xFF2ECC71);
      case AnimalZoneStatus.outside:
        return const Color(0xFF3498DB);
      case AnimalZoneStatus.alert:
        return const Color(0xFFFF4444);
    }
  }

  String _statusLabel(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return 'İçərdə';
      case AnimalZoneStatus.outside:
        return 'Xaricdə';
      case AnimalZoneStatus.alert:
        return 'ALERT';
    }
  }

  Color _typeColor(AnimalType t) {
    switch (t) {
      case AnimalType.cattle:
        return const Color(0xFF8B5E3C);
      case AnimalType.sheep:
        return const Color(0xFF9B9B9B);
      case AnimalType.horse:
        return const Color(0xFF8B4513);
      case AnimalType.goat:
        return const Color(0xFF7B9E5E);
      case AnimalType.pig:
        return const Color(0xFFFF8FAB);
      case AnimalType.other:
        return const Color(0xFF6C63FF);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Naməlum';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dq';
    if (diff.inHours < 24) return '${diff.inHours}s';
    return '${diff.inDays}g';
  }
}
