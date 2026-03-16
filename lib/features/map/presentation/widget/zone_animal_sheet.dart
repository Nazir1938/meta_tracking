import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

/// Zona sheet — v4
///
/// Düzəltmələr:
/// 1. _withZone / manual copy silindi → copyWith(clearZone: true) istifadə edilir
/// 2. StreamSubscription-da GPS yeniləmələrindən qaynaqlanan çoxlu setState()
///    loop-unu kəsmək üçün debounce əlavə edildi (_pendingUpdate Timer)
/// 3. Optimistic UI saxlanıldı (dərhal görünür), Firestore cavabı gəldikdə
///    stream state-i yenilənir
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
  List<AnimalEntity> _animals = [];
  StreamSubscription<AnimalState>? _sub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    final bloc = context.read<AnimalBloc>();
    final state = bloc.state;
    _animals = state is AnimalLoaded
        ? List.from(state.animals)
        : List.from(widget.allAnimals);

    // Stream-ə qoşul — GPS yeniləmələrini debounce ilə sıxışdır
    _sub = bloc.stream.listen((s) {
      if (!mounted) return;
      if (s is AnimalLoaded) {
        // 150ms debounce: GPS update-ləri çox tez gəlir,
        // hər birində setState() çağırmaq yerinə sonuncusunu götürürük
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _animals = List.from(s.animals));
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    _tab.dispose();
    super.dispose();
  }

  List<AnimalEntity> get _zoneAnimals =>
      _animals.where((a) => a.zoneId == widget.zone.id).toList();

  List<AnimalEntity> get _otherAnimals =>
      _animals.where((a) => a.zoneId != widget.zone.id).toList();

  void _addToZone(AnimalEntity animal) {
    // Optimistic update — dərhal UI-da göstər
    setState(() {
      _animals = _animals
          .map((a) => a.id == animal.id
              ? a.copyWith(zoneId: widget.zone.id, zoneName: widget.zone.name)
              : a)
          .toList();
    });
    // Firestore-a yaz
    context.read<AnimalBloc>().add(EditAnimalEvent(
          animalId: animal.id,
          name: animal.name,
          type: animal.type,
          chipId: animal.chipId,
          notes: animal.notes,
          zoneId: widget.zone.id,
          zoneName: widget.zone.name,
        ));
  }

  void _removeFromZone(AnimalEntity animal) {
    // Optimistic update — dərhal UI-da çıxar
    // FIX: clearZone: true istifadə edilir, əks halda copyWith zoneId=null-ı qəbul etmir
    setState(() {
      _animals = _animals
          .map((a) => a.id == animal.id ? a.copyWith(clearZone: true) : a)
          .toList();
    });
    // Firestore-a yaz
    context.read<AnimalBloc>().add(EditAnimalEvent(
          animalId: animal.id,
          name: animal.name,
          type: animal.type,
          chipId: animal.chipId,
          notes: animal.notes,
          zoneId: null,
          zoneName: null,
        ));
  }

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
        _ZoneHeader(zone: widget.zone, color: color, onFocus: widget.onFocus),
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
        SizedBox(
          height: 260,
          child: TabBarView(
            controller: _tab,
            children: [
              _ZoneAnimalsTab(animals: _zoneAnimals, onRemove: _removeFromZone),
              _AddAnimalsTab(animals: _otherAnimals, onAdd: _addToZone),
            ],
          ),
        ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            zone.zoneType == ZoneType.polygon
                ? Iconsax.shapes
                : Iconsax.location,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            if (zone.description?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(zone.description!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ]),
        ),
        GestureDetector(
          onTap: onFocus,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Iconsax.location_tick, color: color, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ZoneAnimalsTab extends StatelessWidget {
  final List<AnimalEntity> animals;
  final void Function(AnimalEntity) onRemove;
  const _ZoneAnimalsTab({required this.animals, required this.onRemove});

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
class _AddAnimalsTab extends StatelessWidget {
  final List<AnimalEntity> animals;
  final void Function(AnimalEntity) onAdd;
  const _AddAnimalsTab({required this.animals, required this.onAdd});

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
        return _AnimalRow(
          animal: a,
          subtitle: a.zoneName ?? 'Zonasız',
          trailing: GestureDetector(
            onTap: () => onAdd(a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Əlavə Et',
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
class _AnimalRow extends StatelessWidget {
  final AnimalEntity animal;
  final String? subtitle;
  final Widget trailing;
  const _AnimalRow(
      {required this.animal, this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Text(animal.typeEmoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(animal.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
        trailing,
      ]),
    );
  }
}
