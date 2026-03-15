import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

/// Zona üzərinə tıklandıqda açılan sheet.
/// — Həmin zonada olan heyvanları göstərir (offline: zoneId field-dən)
/// — "Bu zonaya heyvan əlavə et" tab-ı ilə heyvan seçib zoneId yeniləyir
class ZoneAnimalSheet extends StatefulWidget {
  final ZoneEntity zone;
  final List<AnimalEntity> allAnimals;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onFocus;

  const ZoneAnimalSheet({
    super.key,
    required this.zone,
    required this.allAnimals,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onFocus,
  });

  @override
  State<ZoneAnimalSheet> createState() => _ZoneAnimalSheetState();
}

class _ZoneAnimalSheetState extends State<ZoneAnimalSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Həmin zonaya aid heyvanlar
  List<AnimalEntity> get _zoneAnimals =>
      widget.allAnimals.where((a) => a.zoneId == widget.zone.id).toList();

  // Başqa zonada / zonasız heyvanlar
  List<AnimalEntity> get _otherAnimals =>
      widget.allAnimals.where((a) => a.zoneId != widget.zone.id).toList();

  @override
  Widget build(BuildContext context) {
    final color = widget.zone.isActive ? const Color(0xFF1D9E75) : Colors.grey;

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

        // Zona başlığı
        _ZoneHeader(zone: widget.zone, color: color, onFocus: widget.onFocus),

        // Tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Bu Erazidə (${_zoneAnimals.length})'),
                Tab(text: 'Əlavə Et (${_otherAnimals.length})'),
              ],
            ),
          ),
        ),

        // Tab içərikləri
        SizedBox(
          height: 260,
          child: TabBarView(
            controller: _tab,
            children: [
              _ZoneAnimalsTab(
                animals: _zoneAnimals,
                zone: widget.zone,
                onRemove: _removeFromZone,
              ),
              _AddAnimalsTab(
                animals: _otherAnimals,
                zone: widget.zone,
                onAdd: _addToZone,
              ),
            ],
          ),
        ),

        // Əməliyyat düymələri
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: _actionBtn(Iconsax.edit, 'Redaktə',
                  const Color(0xFF185FA5), widget.onEdit),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                widget.zone.isActive
                    ? Iconsax.pause_circle
                    : Iconsax.play_circle,
                widget.zone.isActive ? 'Deaktiv' : 'Aktiv',
                widget.zone.isActive ? Colors.grey : const Color(0xFF1D9E75),
                widget.onToggle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Iconsax.trash, 'Sil', const Color(0xFFE24B4A),
                  widget.onDelete),
            ),
          ]),
        ),
      ]),
    );
  }

  void _addToZone(AnimalEntity animal) {
    // EditAnimalEvent-də ownerId yoxdur — animal_bloc.dart-a uyğun
    context.read<AnimalBloc>().add(EditAnimalEvent(
          animalId: animal.id,
          name: animal.name,
          type: animal.type,
          chipId: animal.chipId,
          notes: animal.notes,
          zoneId: widget.zone.id,
          zoneName: widget.zone.name,
        ));
    setState(() {});
  }

  void _removeFromZone(AnimalEntity animal) {
    context.read<AnimalBloc>().add(EditAnimalEvent(
          animalId: animal.id,
          name: animal.name,
          type: animal.type,
          chipId: animal.chipId,
          notes: animal.notes,
          zoneId: null,
          zoneName: null,
        ));
    setState(() {});
  }

  Widget _actionBtn(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Zona başlığı
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneHeader extends StatelessWidget {
  final ZoneEntity zone;
  final Color color;
  final VoidCallback onFocus;

  const _ZoneHeader(
      {required this.zone, required this.color, required this.onFocus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(_emoji(zone.name),
                  style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone.isActive ? 'Aktiv' : 'Deaktiv',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 6),
              Text(zone.displayRadius,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: onFocus,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.location, color: color, size: 16),
          ),
        ),
      ]),
    );
  }

  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('otlaq') || n.contains('çəmən')) return '🌿';
    if (n.contains('orman') || n.contains('meşə')) return '🌳';
    if (n.contains('ahır') || n.contains('bina')) return '🏠';
    if (n.contains('su')) return '💧';
    if (n.contains('qarantina') || n.contains('qadağa')) return '🔒';
    return '📍';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Zonada olan heyvanlar
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneAnimalsTab extends StatelessWidget {
  final List<AnimalEntity> animals;
  final ZoneEntity zone;
  final void Function(AnimalEntity) onRemove;

  const _ZoneAnimalsTab(
      {required this.animals, required this.zone, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (animals.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Iconsax.pet, size: 36, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('Bu erazidə heyvan yoxdur',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text('"Əlavə Et" tabından heyvan əlavə edin',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: animals.length,
      itemBuilder: (_, i) => _AnimalRow(
        animal: animals[i],
        trailing: GestureDetector(
          onTap: () => onRemove(animals[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Çıxar',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFE24B4A),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Heyvan əlavə et
// ─────────────────────────────────────────────────────────────────────────────

class _AddAnimalsTab extends StatelessWidget {
  final List<AnimalEntity> animals;
  final ZoneEntity zone;
  final void Function(AnimalEntity) onAdd;

  const _AddAnimalsTab(
      {required this.animals, required this.zone, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (animals.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Iconsax.tick_circle, size: 36, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('Bütün heyvanlar bu erazidədir',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: animals.length,
      itemBuilder: (_, i) {
        final a = animals[i];
        final currentZone = a.zoneName ?? 'Zona yoxdur';
        return _AnimalRow(
          animal: a,
          subtitle: currentZone,
          trailing: GestureDetector(
            onTap: () => onAdd(a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Əlavə et',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heyvan satırı (reusable)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimalRow extends StatelessWidget {
  final AnimalEntity animal;
  final Widget trailing;
  final String? subtitle;

  const _AnimalRow(
      {required this.animal, required this.trailing, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(animal.zoneStatus);
    final statusLabel = _statusLabel(animal.zoneStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
              child:
                  Text(animal.typeEmoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(animal.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)
            else
              Row(children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(fontSize: 10, color: statusColor)),
                if (animal.lastLatitude != null) ...[
                  const SizedBox(width: 6),
                  Icon(Iconsax.location, size: 9, color: Colors.grey[400]),
                  const SizedBox(width: 2),
                  Text('GPS aktiv',
                      style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                ],
              ]),
          ]),
        ),
        trailing,
      ]),
    );
  }

  Color _statusColor(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return const Color(0xFF1D9E75);
      case AnimalZoneStatus.outside:
        return const Color(0xFF185FA5);
      case AnimalZoneStatus.alert:
        return const Color(0xFFE24B4A);
    }
  }

  String _statusLabel(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return 'İçərdə';
      case AnimalZoneStatus.outside:
        return 'Xaricdə';
      case AnimalZoneStatus.alert:
        return 'Alert';
    }
  }
}
