import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class CreateHerdSheet extends StatefulWidget {
  final String ownerId;
  final List<String>? preSelectedAnimalIds;

  const CreateHerdSheet({
    super.key,
    required this.ownerId,
    this.preSelectedAnimalIds,
  });

  @override
  State<CreateHerdSheet> createState() => _CreateHerdSheetState();
}

class _CreateHerdSheetState extends State<CreateHerdSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedAnimalIds = {};
  String? _selectedZoneId;
  double _threshold = 500;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedAnimalIds != null) {
      _selectedAnimalIds.addAll(widget.preSelectedAnimalIds!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack('Sürü adı daxil edin'); return; }
    if (_selectedAnimalIds.isEmpty) { _snack('Ən az 1 heyvan seçin'); return; }
    setState(() => _isLoading = true);
    context.read<HerdBloc>().add(CreateHerdEvent(
          name: name,
          ownerId: widget.ownerId,
          animalIds: _selectedAnimalIds.toList(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          separationThresholdMeters: _threshold,
        ));
    Navigator.pop(context);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFE24B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final animals = context.watch<AnimalBloc>().state is AnimalLoaded
        ? (context.watch<AnimalBloc>().state as AnimalLoaded).animals
        : <AnimalEntity>[];
    final zones = context.watch<ZoneBloc>().state is ZonesLoaded
        ? (context.watch<ZoneBloc>().state as ZonesLoaded).zones
        : <ZoneEntity>[];

    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Başlıq
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              const Text('Yeni Sürü',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              Text('${_selectedAnimalIds.length} heyvan seçildi',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // ── Ad + Təsvir ───────────────────────────────────
                _field(_nameCtrl, 'Sürü adı *', Iconsax.people,
                    autofocus: true),
                const SizedBox(height: 10),
                _field(_descCtrl, 'Təsvir (ixtiyari)', Iconsax.note),
                const SizedBox(height: 20),

                // ── Ərazi seçimi ──────────────────────────────────
                _sectionTitle('Ərazi (ixtiyari)'),
                const SizedBox(height: 10),
                _ZoneSelection(
                  zones: zones,
                  selectedZoneId: _selectedZoneId,
                  onSelected: (id, name) => setState(() {
                    _selectedZoneId = id;
                  }),
                  onClear: () => setState(() {
                    _selectedZoneId = null;
                  }),
                ),
                const SizedBox(height: 20),

                // ── Ayrılma məsafəsi ──────────────────────────────
                _sectionTitle('Ayrılma məsafəsi'),
                const SizedBox(height: 6),
                _ThresholdSlider(
                  threshold: _threshold,
                  onChanged: (v) => setState(() => _threshold = v),
                ),
                const SizedBox(height: 20),

                // ── Heyvan seçimi ─────────────────────────────────
                Row(children: [
                  _sectionTitle('Heyvanlar'),
                  const Text(' *',
                      style: TextStyle(
                          color: Color(0xFFE24B4A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (animals.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedAnimalIds.length == animals.length
                            ? _selectedAnimalIds.clear()
                            : _selectedAnimalIds
                                .addAll(animals.map((a) => a.id));
                      }),
                      child: Text(
                        _selectedAnimalIds.length == animals.length
                            ? 'Hamısını ləğv et'
                            : 'Hamısını seç',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                if (animals.isEmpty)
                  _emptyBox('Heyvan yoxdur. Əvvəlcə heyvan əlavə edin.')
                else
                  ...animals.map((a) => _AnimalTile(
                        animal: a,
                        isSelected: _selectedAnimalIds.contains(a.id),
                        onTap: () => setState(() {
                          _selectedAnimalIds.contains(a.id)
                              ? _selectedAnimalIds.remove(a.id)
                              : _selectedAnimalIds.add(a.id);
                        }),
                      )),
                const SizedBox(height: 20),

                // ── Yarat düyməsi ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Iconsax.people, size: 18),
                    label: Text(
                        _isLoading ? 'Yaradılır...' : 'Sürü Yarat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E)));

  Widget _emptyBox(String msg) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
            child: Text(msg,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12))),
      );

  TextField _field(TextEditingController ctrl, String label, IconData icon,
      {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ərazi seçim widget-i
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneSelection extends StatelessWidget {
  final List<ZoneEntity> zones;
  final String? selectedZoneId;
  final void Function(String id, String name) onSelected;
  final VoidCallback onClear;

  const _ZoneSelection({
    required this.zones,
    this.selectedZoneId,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text('Zona yoxdur. Xəritədən zona əlavə edin.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center),
      );
    }

    return Column(children: [
      if (selectedZoneId != null)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Iconsax.location,
                color: Color(0xFF1D9E75), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  zones
                          .firstWhere((z) => z.id == selectedZoneId,
                              orElse: () => zones.first)
                          .name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const Icon(Iconsax.tick_circle,
                color: Color(0xFF1D9E75), size: 16),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Iconsax.close_circle,
                  color: Colors.grey, size: 16),
            ),
          ]),
        ),
      ...zones.map((zone) {
        final isSelected = selectedZoneId == zone.id;
        return GestureDetector(
          onTap: () => onSelected(zone.id, zone.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1D9E75)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1D9E75)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1D9E75)
                          : Colors.grey.shade300),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              const Icon(Iconsax.location,
                  size: 14, color: Color(0xFF1D9E75)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(zone.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(zone.displayRadius,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
            ]),
          ),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ayrılma məsafəsi slider
// ─────────────────────────────────────────────────────────────────────────────

class _ThresholdSlider extends StatelessWidget {
  final double threshold;
  final ValueChanged<double> onChanged;
  const _ThresholdSlider(
      {required this.threshold, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(
            'Heyvan sürünün mərkəzindən bu qədər uzaqlaşarsa bildiriş göndərilir',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          threshold < 1000
              ? '${threshold.toInt()} m'
              : '${(threshold / 1000).toStringAsFixed(1)} km',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D9E75)),
        ),
      ]),
      Slider(
        value: threshold,
        min: 100, max: 2000, divisions: 38,
        activeColor: const Color(0xFF1D9E75),
        onChanged: onChanged,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['100 m', '500 m', '1 km', '2 km']
            .map((t) => Text(t,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey[500])))
            .toList(),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heyvan seçim tile-ı
// ─────────────────────────────────────────────────────────────────────────────

class _AnimalTile extends StatelessWidget {
  final AnimalEntity animal;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimalTile(
      {required this.animal,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1D9E75).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D9E75)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1D9E75)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1D9E75)
                      : Colors.grey.shade300),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  Text(animal.zoneName ?? animal.typeName,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ]),
          ),
        ]),
      ),
    );
  }
}