import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

/// Yalnız zona statistika + əməliyyat düymələri.
/// Heyvan idarəsi ZoneAnimalSheet-də (map_screen tərəfindən birbaşa açılır).
class ZoneInfoSheet extends StatelessWidget {
  final ZoneEntity zone;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onFocus;

  const ZoneInfoSheet({
    super.key,
    required this.zone,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final color = zone.isActive ? const Color(0xFF1D9E75) : Colors.grey;
    final sizeLabel = zone.zoneType == ZoneType.polygon ? 'Sahə' : 'Radius';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
        ),

        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(_zoneEmoji(zone.name),
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    if (zone.description != null)
                      Text(zone.description!,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        zone.isActive ? 'Aktiv' : 'Deaktiv',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ]),
            ),
            GestureDetector(
              onTap: onFocus,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.location, color: color, size: 18),
              ),
            ),
          ]),
        ),

        // Stat satırları
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _statRow(Iconsax.radar, sizeLabel, zone.displayRadius),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(Iconsax.chart, 'Sahə', zone.displayArea),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(Iconsax.calendar, 'Yaradılıb', _fmt(zone.createdAt)),
              Divider(height: 1, color: Colors.grey[200]),
              _statRow(
                Iconsax.location,
                'Koordinat',
                '${zone.latitude.toStringAsFixed(4)}, '
                    '${zone.longitude.toStringAsFixed(4)}',
              ),
              if (zone.zoneType == ZoneType.polygon) ...[
                Divider(height: 1, color: Colors.grey[200]),
                _statRow(
                  Iconsax.shapes,
                  'Növ',
                  'Polygon (${zone.polygonPoints.length} nöqtə)',
                ),
              ],
            ]),
          ),
        ),

        // Əməliyyat düymələri
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            Expanded(
              child: _actionBtn(
                icon: Iconsax.edit,
                label: 'Redaktə',
                color: const Color(0xFF185FA5),
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon:
                    zone.isActive ? Iconsax.pause_circle : Iconsax.play_circle,
                label: zone.isActive ? 'Deaktiv et' : 'Aktiv et',
                color: zone.isActive ? Colors.grey : const Color(0xFF1D9E75),
                onTap: onToggle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Iconsax.trash,
                label: 'Sil',
                color: const Color(0xFFE24B4A),
                onTap: onDelete,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
                textAlign: TextAlign.right),
          ),
        ]),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  String _zoneEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('otlaq') || n.contains('çəmən')) return '🌿';
    if (n.contains('orman') || n.contains('meşə')) return '🌳';
    if (n.contains('ahır') || n.contains('bina')) return '🏠';
    if (n.contains('su')) return '💧';
    if (n.contains('qarantina') || n.contains('qadağa')) return '🔒';
    return '📍';
  }

  String _fmt(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';
}
