import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class AddAnimalSheet extends StatefulWidget {
  final String ownerId;
  final void Function(
    String name,
    AnimalType type,
    String chipId,
    String notes,
    String? zoneId,
    String? zoneName,
  ) onSubmit;
  final AnimalEntity? existingAnimal;

  const AddAnimalSheet({
    super.key,
    required this.ownerId,
    required this.onSubmit,
    this.existingAnimal,
  });

  @override
  State<AddAnimalSheet> createState() => _AddAnimalSheetState();
}

class _AddAnimalSheetState extends State<AddAnimalSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _chipCtrl;
  late final TextEditingController _notesCtrl;
  late AnimalType _selectedType;
  String? _selectedZoneId;
  String? _selectedZoneName;
  bool _isLoading = false;
  bool _zoneError = false;

  bool get _isEdit => widget.existingAnimal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAnimal;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _chipCtrl = TextEditingController(text: a?.chipId ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _selectedType = a?.type ?? AnimalType.cattle;
    _selectedZoneId = a?.zoneId;
    _selectedZoneName = a?.zoneName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _chipCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ── Zona seçimi üçün tam ekran açar ──────────────────────────────────────
  void _openZonePicker(List<ZoneEntity> zones) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ZoneBloc>(),
        child: _ZonePickerSheet(
          zones: zones,
          selectedZoneId: _selectedZoneId,
          onSelected: (zone) {
            setState(() {
              _selectedZoneId = zone.id;
              _selectedZoneName = zone.name;
              _zoneError = false;
            });
          },
          onCreateNew: () {
            // Sheet-i bağla, xəritəyə get
            Navigator.pop(context);
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MapScreen()))
                .then((_) {
              // Geri döndükdə zonaları yenilə
              context.read<ZoneBloc>().add(const LoadZonesEvent());
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZoneBloc, ZoneState>(
      builder: (context, zoneState) {
        final zones = zoneState is ZonesLoaded
            ? zoneState.activeZones
            : <ZoneEntity>[];

        return Container(
          margin:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  _isEdit ? 'Heyvanı Redaktə Et' : 'Yeni Heyvan',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 16),

                // ── Ad ──────────────────────────────────────────────────────
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDec('Heyvan adı *', Iconsax.pet),
                ),
                const SizedBox(height: 12),

                // ── Çip ─────────────────────────────────────────────────────
                TextField(
                  controller: _chipCtrl,
                  decoration:
                      _inputDec('Çip nömrəsi (ixtiyari)', Iconsax.tag),
                ),
                const SizedBox(height: 12),

                // ── Qeydlər ─────────────────────────────────────────────────
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: _inputDec('Qeydlər (ixtiyari)', Iconsax.note),
                ),
                const SizedBox(height: 14),

                // ── Növ ──────────────────────────────────────────────────────
                const Text('Növ',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AnimalType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                                  .withValues(alpha: 0.10)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2ECC71)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_emoji(type),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(_name(type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2ECC71)
                                    : Colors.grey[600],
                              )),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Otlama Sahəsi ─────────────────────────────────────────
                _buildZoneSection(zones),

                const SizedBox(height: 20),

                // ── Əlavə Et / Yadda Saxla düyməsi ───────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(_isEdit ? Iconsax.edit : Iconsax.add,
                            size: 18),
                    label: Text(_isLoading
                        ? 'Saxlanılır...'
                        : _isEdit
                            ? 'Yadda Saxla'
                            : 'Əlavə Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
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
        );
      },
    );
  }

  Widget _buildZoneSection(List<ZoneEntity> zones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlıq + xəta
        Row(children: [
          const Text('Otlama Sahəsi',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: Color(0xFFFF4444),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const Spacer(),
          // Xəritədən yeni zona yarat
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MapScreen()))
                  .then((_) =>
                      context.read<ZoneBloc>().add(const LoadZonesEvent()));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Iconsax.add, size: 12, color: Color(0xFF2ECC71)),
                SizedBox(width: 4),
                Text('Zona yarat',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        if (_zoneError)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Zona seçilməlidir',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF4444),
                    fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 8),

        // Seçilmiş zona göstər
        if (_selectedZoneId != null && _selectedZoneName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      const Color(0xFF2ECC71).withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Iconsax.location_tick,
                  size: 16, color: Color(0xFF2ECC71)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedZoneName!,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2ECC71)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedZoneId = null;
                  _selectedZoneName = null;
                }),
                child: const Icon(Iconsax.close_circle,
                    size: 16, color: Color(0xFF2ECC71)),
              ),
            ]),
          ),

        // Zona siyahısı
        if (zones.isEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF4444).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Iconsax.warning_2,
                  size: 16, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hələ zona yoxdur. "Zona yarat" düyməsini basın.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ]),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...zones.map((zone) {
                final isSelected = _selectedZoneId == zone.id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedZoneId = zone.id;
                    _selectedZoneName = zone.name;
                    _zoneError = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ECC71).withValues(alpha: 0.10)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2ECC71)
                            : _zoneError
                                ? const Color(0xFFFF4444)
                                    .withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isSelected
                            ? Iconsax.tick_circle
                            : Iconsax.location,
                        size: 13,
                        color: isSelected
                            ? const Color(0xFF2ECC71)
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 5),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(zone.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF2ECC71)
                                      : Colors.grey[700],
                                )),
                            Text(
                              '${(zone.radiusInMeters / 1000).toStringAsFixed(2)} km',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                          ]),
                    ]),
                  ),
                );
              }),
              // Bütün zonaları gör
              if (zones.length > 4)
                GestureDetector(
                  onTap: () => _openZonePicker(zones),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text('Hamısını gör →',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showTopSnack('Heyvan adı daxil edin', isWarning: true);
      return;
    }

    if (_selectedZoneId == null) {
      setState(() => _zoneError = true);
      _showTopSnack('Otlama sahəsi seçilməlidir', isWarning: false);
      return;
    }

    setState(() => _isLoading = true);
    widget.onSubmit(
      name,
      _selectedType,
      _chipCtrl.text.trim(),
      _notesCtrl.text.trim(),
      _selectedZoneId,
      _selectedZoneName,
    );
  }

  void _showTopSnack(String msg, {required bool isWarning}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.location_off_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor:
          isWarning ? const Color(0xFFFF9800) : const Color(0xFFFF4444),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 560),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _emoji(AnimalType t) {
    switch (t) {
      case AnimalType.cattle:
        return '🐄';
      case AnimalType.sheep:
        return '🐑';
      case AnimalType.horse:
        return '🐎';
      case AnimalType.goat:
        return '🐐';
      case AnimalType.pig:
        return '🐖';
      case AnimalType.other:
        return '🐾';
    }
  }

  String _name(AnimalType t) {
    switch (t) {
      case AnimalType.cattle:
        return 'İnək';
      case AnimalType.sheep:
        return 'Qoyun';
      case AnimalType.horse:
        return 'At';
      case AnimalType.goat:
        return 'Keçi';
      case AnimalType.pig:
        return 'Donuz';
      case AnimalType.other:
        return 'Digər';
    }
  }
}

// ── Zona seçici sheet (çox zona olduqda) ────────────────────────────────────

class _ZonePickerSheet extends StatelessWidget {
  final List<ZoneEntity> zones;
  final String? selectedZoneId;
  final void Function(ZoneEntity) onSelected;
  final VoidCallback onCreateNew;

  const _ZonePickerSheet({
    required this.zones,
    required this.selectedZoneId,
    required this.onSelected,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0A1628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            const Icon(Iconsax.location, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Otlama Sahəsi Seç',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Iconsax.close_circle,
                  color: Colors.white, size: 20),
            ),
          ]),
        ),
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            shrinkWrap: true,
            itemCount: zones.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (_, i) {
              final zone = zones[i];
              final isSelected = zone.id == selectedZoneId;
              return GestureDetector(
                onTap: () {
                  onSelected(zone);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2ECC71)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      isSelected ? Iconsax.tick_circle : Iconsax.location,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF2ECC71)
                          : Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(zone.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFF1A1A2E),
                                )),
                            Text(
                              'Radius: ${(zone.radiusInMeters / 1000).toStringAsFixed(2)} km'
                              '${zone.description != null ? ' • ${zone.description}' : ''}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Yeni Zona Yarat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2ECC71),
                side: const BorderSide(color: Color(0xFF2ECC71)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}