import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Zona siyahısı paneli
// ─────────────────────────────────────────────────────────────────────────────

class MapZoneListPanel extends StatelessWidget {
  final List<ZoneEntity> zones;
  final void Function(ZoneEntity) onZoneTap;
  final void Function(ZoneEntity) onToggle;
  final void Function(ZoneEntity) onEdit;
  final void Function(ZoneEntity) onDelete;

  const MapZoneListPanel({
    super.key,
    required this.zones,
    required this.onZoneTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        right: 58,
        child: Container(
          width: 230,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Başlıq
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1628),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Iconsax.location,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('Zonalar (${zones.length})',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ),

            if (zones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Hələ zona yoxdur.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: zones.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (_, i) => ZoneTileRow(
                    zone: zones[i],
                    onTap: () => onZoneTap(zones[i]),
                    onToggle: () => onToggle(zones[i]),
                    onEdit: () => onEdit(zones[i]),
                    onDelete: () => onDelete(zones[i]),
                  ),
                ),
              ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Zona siyahı sətiri
// ─────────────────────────────────────────────────────────────────────────────

class ZoneTileRow extends StatelessWidget {
  final ZoneEntity zone;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ZoneTileRow({
    super.key,
    required this.zone,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(children: [
            // Toggle circle
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: zone.isActive
                      ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: zone.isActive
                          ? const Color(0xFF1D9E75)
                          : Colors.grey.shade300,
                      width: 0.5),
                ),
                child: Icon(
                  zone.isActive
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 10,
                  color: zone.isActive
                      ? const Color(0xFF1D9E75)
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Ad + ölçü
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(zone.displayRadius,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500])),
                  ]),
            ),

            // Redaktə
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Iconsax.edit_2,
                    size: 14, color: Colors.grey[500]),
              ),
            ),

            // Sil
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Iconsax.trash,
                    size: 14, color: Color(0xFFE24B4A)),
              ),
            ),
          ]),
        ),
      );
}