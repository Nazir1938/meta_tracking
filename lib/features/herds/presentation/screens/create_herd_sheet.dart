import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';

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
  final Set<String> _selected = {};
  double _threshold = 500;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedAnimalIds != null) {
      _selected.addAll(widget.preSelectedAnimalIds!);
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
    if (name.isEmpty) {
      _snack('Naxır adı daxil edin');
      return;
    }
    if (_selected.isEmpty) {
      _snack('Ən az 1 heyvan seçin');
      return;
    }
    setState(() => _isLoading = true);
    context.read<HerdBloc>().add(CreateHerdEvent(
          name: name,
          ownerId: widget.ownerId,
          animalIds: _selected.toList(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          separationThresholdMeters: _threshold,
        ));
    Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE24B4A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final animalState = context.watch<AnimalBloc>().state;
    final animals =
        animalState is AnimalLoaded ? animalState.animals : <AnimalEntity>[];

    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              const Text('Yeni Naxır',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              Text('${_selected.length} seçildi',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
          // Scroll məzmun
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Ad
                _field(_nameCtrl, 'Naxır adı *', Iconsax.people, autofocus: true),
                const SizedBox(height: 10),
                // Təsvir
                _field(_descCtrl, 'Təsvir (ixtiyari)', Iconsax.note),
                const SizedBox(height: 16),

                // Ayrılma məsafəsi
                _thresholdSection(),
                const SizedBox(height: 16),

                // Heyvan seçimi
                _animalSelectionSection(animals),
                const SizedBox(height: 20),

                // Yarat düyməsi
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
                    label: Text(_isLoading ? 'Yaradılır...' : 'Naxır Yarat'),
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

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _thresholdSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Iconsax.radar, size: 16, color: Color(0xFF1D9E75)),
          const SizedBox(width: 8),
          const Text('Ayrılma həddi',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _threshold < 1000
                  ? '${_threshold.toInt()} m'
                  : '${(_threshold / 1000).toStringAsFixed(1)} km',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D9E75)),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Bu heyvan sürünün mərkəzindən bu qədər uzaqlaşarsa bildiriş göndərilir',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        Slider(
          value: _threshold,
          min: 100,
          max: 2000,
          divisions: 38,
          activeColor: const Color(0xFF1D9E75),
          onChanged: (v) => setState(() => _threshold = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('100 m', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('500 m', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('1 km', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text('2 km', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ]),
    );
  }

  Widget _animalSelectionSection(List<AnimalEntity> animals) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Heyvanlar',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(width: 4),
        const Text('*',
            style: TextStyle(
                color: Color(0xFFE24B4A),
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        // Hamısını seç / ləğv et
        if (animals.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              if (_selected.length == animals.length) {
                _selected.clear();
              } else {
                _selected.addAll(animals.map((a) => a.id));
              }
            }),
            child: Text(
              _selected.length == animals.length
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(
            child: Text('Heyvan yoxdur. Əvvəlcə heyvan əlavə edin.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        )
      else
        ...animals.map((animal) => _animalTile(animal)),
    ]);
  }

  Widget _animalTile(AnimalEntity animal) {
    final isSelected = _selected.contains(animal.id);
    return GestureDetector(
      onTap: () => setState(() {
        isSelected ? _selected.remove(animal.id) : _selected.add(animal.id);
      }),
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
          // Checkbox
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
                    : Colors.grey.shade300,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          // Emoji
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _typeColor(animal.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          // İnfo
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(animal.name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              Text(
                animal.zoneName ?? animal.typeName,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ]),
          ),
          // Status
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(animal.zoneStatus)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(animal.zoneStatus),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(animal.zoneStatus)),
            ),
          ),
        ]),
      ),
    );
  }

  Color _typeColor(AnimalType t) {
    switch (t) {
      case AnimalType.cattle: return const Color(0xFF8B5E3C);
      case AnimalType.sheep:  return const Color(0xFF9B9B9B);
      case AnimalType.horse:  return const Color(0xFF185FA5);
      case AnimalType.goat:   return const Color(0xFF7B9E5E);
      case AnimalType.pig:    return const Color(0xFFFF8FAB);
      case AnimalType.other:  return const Color(0xFF6C63FF);
    }
  }

  Color _statusColor(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:  return const Color(0xFF1D9E75);
      case AnimalZoneStatus.outside: return const Color(0xFF185FA5);
      case AnimalZoneStatus.alert:   return const Color(0xFFE24B4A);
    }
  }

  String _statusLabel(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:  return 'İçərdə';
      case AnimalZoneStatus.outside: return 'Xaricdə';
      case AnimalZoneStatus.alert:   return 'ALERT';
    }
  }
}