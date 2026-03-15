import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';
import 'package:meta_tracking/features/herds/domain/entities/separation_alert.dart';
import 'package:meta_tracking/features/herds/domain/services/herd_tracking_service.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/home/presentation/screens/animal_detail_screen.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class HerdDetailScreen extends StatelessWidget {
  final HerdEntity herd;
  const HerdDetailScreen({super.key, required this.herd});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: BlocBuilder<AnimalBloc, AnimalState>(
        builder: (_, animalState) {
          final allAnimals = animalState is AnimalLoaded
              ? animalState.animals
              : <AnimalEntity>[];
          final herdAnimals = allAnimals
              .where((a) => herd.animalIds.contains(a.id))
              .toList();
          final sepResult = HerdTrackingService.checkSeparation(
              herd: herd, animals: allAnimals);

          return BlocBuilder<HerdBloc, HerdState>(
            builder: (_, herdState) {
              final currentHerd = herdState is HerdsLoaded
                  ? herdState.herds.firstWhere(
                      (h) => h.id == herd.id,
                      orElse: () => herd)
                  : herd;
              final alerts = herdState is HerdsLoaded
                  ? herdState.activeAlerts
                      .where((a) => a.herdId == herd.id)
                      .toList()
                  : <SeparationAlert>[];

              return Scaffold(
                backgroundColor: const Color(0xFFF4F6F9),
                body: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                        child: _HeroSection(herd: currentHerd)),
                    SliverToBoxAdapter(
                        child: _ActionRow(
                            herd: currentHerd, animals: herdAnimals)),
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Sürü vəziyyəti
                          _SectionTitle('Sürü vəziyyəti'),
                          const SizedBox(height: 8),
                          _HerdStatusCard(
                              result: sepResult, herd: currentHerd),
                          const SizedBox(height: 16),

                          // Alertlar
                          if (alerts.isNotEmpty) ...[
                            _SectionTitle(
                                'Alertlar (${alerts.length})'),
                            const SizedBox(height: 8),
                            ...alerts.map((a) => _AlertTile(
                                  alert: a,
                                  onTap: () => context
                                      .read<HerdBloc>()
                                      .add(MarkAlertReadEvent(a.id)),
                                )),
                            const SizedBox(height: 16),
                          ],

                          // Heyvanlar
                          _SectionTitle(
                              'Heyvanlar (${herdAnimals.length})'),
                          const SizedBox(height: 8),
                          if (herdAnimals.isEmpty)
                            _emptyHint('Heyvan yoxdur')
                          else
                            ...herdAnimals.map((a) => _HerdAnimalTile(
                                  animal: a,
                                  isSeparated: sepResult
                                      .separatedAnimals
                                      .any((s) => s.id == a.id),
                                  onTap: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AnimalDetailScreen(animal: a),
                                    ),
                                  ),
                                  onRemove: () =>
                                      context.read<HerdBloc>().add(
                                            RemoveAnimalFromHerdEvent(
                                              herdId: currentHerd.id,
                                              animalId: a.id,
                                            ),
                                          ),
                                )),
                          const SizedBox(height: 16),

                          // Sürüdə olmayan heyvanları əlavə et
                          _AddAnimalsSection(
                            herd: currentHerd,
                            allAnimals: allAnimals,
                          ),
                          const SizedBox(height: 16),

                          // Redaktə + Sil
                          _EditDeleteRow(herd: currentHerd),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyHint(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Center(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final HerdEntity herd;
  const _HeroSection({required this.herd});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: top + 10, left: 20, right: 20, bottom: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(children: [
                Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF1D9E75), size: 22),
                Text('Geri',
                    style: TextStyle(
                        color: Color(0xFF1D9E75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                    child: Text('🐄',
                        style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(herd.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Row(children: [
                        _badge(
                          '${herd.animalCount} heyvan',
                          const Color(0xFF185FA5),
                          Iconsax.pet,
                        ),
                        const SizedBox(width: 6),
                        _badge(
                          herd.isTracking ? 'İzlənir' : 'İzlənmir',
                          herd.isTracking
                              ? const Color(0xFF1D9E75)
                              : Colors.grey,
                          Iconsax.radar,
                        ),
                        const SizedBox(width: 6),
                        _badge(
                          herd.separationThresholdMeters < 1000
                              ? '${herd.separationThresholdMeters.toInt()} m'
                              : '${(herd.separationThresholdMeters / 1000).toStringAsFixed(1)} km',
                          const Color(0xFF185FA5),
                          Iconsax.location,
                        ),
                      ]),
                    ]),
              ),
            ]),
          ]),
    );
  }

  Widget _badge(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Row — Xəritə, İzlə, Alertları sil
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final HerdEntity herd;
  final List<AnimalEntity> animals;
  const _ActionRow({required this.herd, required this.animals});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        Expanded(
          child: _btn(
            icon: Iconsax.map,
            label: 'Xəritədə bax',
            color: const Color(0xFF1D9E75),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MapScreen(
                animalEntities: animals,
                highlightedAnimalIds: herd.animalIds,
              ),
            )),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btn(
            icon: herd.isTracking
                ? Iconsax.pause_circle
                : Iconsax.radar,
            label: herd.isTracking ? 'Dayandır' : 'İzlə',
            color: herd.isTracking
                ? const Color(0xFFBA7517)
                : const Color(0xFF185FA5),
            onTap: () => context.read<HerdBloc>().add(
                  ToggleHerdTrackingEvent(
                    herdId: herd.id,
                    isTracking: !herd.isTracking,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btn(
            icon: Iconsax.notification,
            label: 'Alertları sil',
            color: Colors.grey,
            onTap: () => context
                .read<HerdBloc>()
                .add(const ClearAlertsEvent()),
          ),
        ),
      ]),
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: 0.2), width: 0.5),
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

// ─────────────────────────────────────────────────────────────────────────────
// Herd Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _HerdStatusCard extends StatelessWidget {
  final HerdSeparationResult result;
  final HerdEntity herd;
  const _HerdStatusCard({required this.result, required this.herd});

  @override
  Widget build(BuildContext context) {
    final spread =
        HerdTrackingService.calculateHerdSpread(result.inHerdAnimals);
    final statusColor = result.hasSeparation
        ? const Color(0xFFE24B4A)
        : const Color(0xFF1D9E75);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Icon(
            result.hasSeparation
                ? Iconsax.warning_2
                : Iconsax.tick_circle,
            color: statusColor, size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.hasSeparation
                  ? '${result.separatedAnimals.length} heyvan sürüdən ayrılıb'
                  : 'Sürü birlikdədir',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
        ]),
        if (spread > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yayılma məsafəsi',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600])),
              Text(
                spread < 1000
                    ? '${spread.toInt()} m'
                    : '${(spread / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF185FA5)),
              ),
            ],
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Tile
// ─────────────────────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final SeparationAlert alert;
  final VoidCallback onTap;
  const _AlertTile({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.isRead
              ? Colors.white
              : const Color(0xFFE24B4A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? Colors.grey.shade200
                : const Color(0xFFE24B4A).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Icon(Iconsax.warning_2,
              color: alert.isRead ? Colors.grey : const Color(0xFFE24B4A),
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.animalName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(alert.distanceLabel,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ]),
          ),
          if (!alert.isRead)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFFE24B4A), shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Herd Animal Tile — heyvanı sürüdən çıxarma düyməsi ilə
// ─────────────────────────────────────────────────────────────────────────────

class _HerdAnimalTile extends StatelessWidget {
  final AnimalEntity animal;
  final bool isSeparated;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HerdAnimalTile({
    required this.animal,
    required this.isSeparated,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSeparated
                ? const Color(0xFFE24B4A).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSeparated
                  ? const Color(0xFFE24B4A).withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.10),
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
                  Row(children: [
                    if (isSeparated) ...[
                      const Icon(Iconsax.warning_2,
                          size: 10, color: Color(0xFFE24B4A)),
                      const SizedBox(width: 3),
                      const Text('Ayrılmış',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFFE24B4A))),
                    ] else if (animal.zoneName != null) ...[
                      Text(animal.zoneName!,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500])),
                    ],
                    if (animal.batteryLevel != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '🔋 ${(animal.batteryLevel! * 100).toInt()}%',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ]),
                ]),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Iconsax.close_circle,
                size: 18, color: Colors.grey),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heyvan əlavə et bölməsi — sürüdə olmayan heyvanları göstərir
// ─────────────────────────────────────────────────────────────────────────────

class _AddAnimalsSection extends StatefulWidget {
  final HerdEntity herd;
  final List<AnimalEntity> allAnimals;
  const _AddAnimalsSection(
      {required this.herd, required this.allAnimals});

  @override
  State<_AddAnimalsSection> createState() => _AddAnimalsSectionState();
}

class _AddAnimalsSectionState extends State<_AddAnimalsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final available = widget.allAnimals
        .where((a) => !widget.herd.animalIds.contains(a.id))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Başlıq + genişlət/daralt
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.2),
                width: 0.5),
          ),
          child: Row(children: [
            const Icon(Iconsax.add_circle,
                color: Color(0xFF1D9E75), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sürüyə heyvan əlavə et (${available.length} mövcud)',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D9E75)),
              ),
            ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF1D9E75),
            ),
          ]),
        ),
      ),
      if (_expanded) ...[
        const SizedBox(height: 8),
        ...available.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(a.typeEmoji,
                          style: const TextStyle(fontSize: 17))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text(a.zoneName ?? a.typeName,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500])),
                      ]),
                ),
                GestureDetector(
                  onTap: () => context.read<HerdBloc>().add(
                        AddAnimalToHerdEvent(
                          herdId: widget.herd.id,
                          animalId: a.id,
                        ),
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Əlavə et',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            )),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Redaktə + Sil row
// ─────────────────────────────────────────────────────────────────────────────

class _EditDeleteRow extends StatelessWidget {
  final HerdEntity herd;
  const _EditDeleteRow({required this.herd});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _btn(
          icon: Iconsax.edit,
          label: 'Sürüyü Redaktə Et',
          color: const Color(0xFF185FA5),
          onTap: () => _showEditSheet(context),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _btn(
          icon: Iconsax.trash,
          label: 'Sürüyü Sil',
          color: const Color(0xFFE24B4A),
          onTap: () => _confirmDelete(context),
        ),
      ),
    ]);
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      );

  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: herd.name);
    final descCtrl =
        TextEditingController(text: herd.description ?? '');
    double threshold = herd.separationThresholdMeters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HerdBloc>(),
        child: StatefulBuilder(
          builder: (ctx, set) => Container(
            margin: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(children: [
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sürüyü Redaktə Et',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 14),
                  _sheetField(nameCtrl, 'Sürü adı *', Iconsax.people),
                  const SizedBox(height: 10),
                  _sheetField(descCtrl, 'Təsvir (ixtiyari)', Iconsax.note),
                  const SizedBox(height: 12),
                  // Threshold
                  Row(children: [
                    Expanded(
                      child: Text(
                        'Ayrılma məsafəsi: ${threshold < 1000 ? '${threshold.toInt()} m' : '${(threshold / 1000).toStringAsFixed(1)} km'}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D9E75)),
                      ),
                    ),
                  ]),
                  Slider(
                    value: threshold,
                    min: 100, max: 2000, divisions: 38,
                    activeColor: const Color(0xFF1D9E75),
                    onChanged: (v) => set(() => threshold = v),
                  ),
                  const SizedBox(height: 4),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      ctx.read<HerdBloc>().add(UpdateHerdEvent(
                            herd.copyWith(
                              name: name,
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              separationThresholdMeters: threshold,
                            ),
                          ));
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Iconsax.tick_circle, size: 18),
                    label: const Text('Yadda Saxla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('"${herd.name}" silinsin?',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'Sürü silinəcək. Heyvanlar silinməyəcək.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<HerdBloc>()
                  .add(DeleteHerdEvent(herd.id));
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6),
      );
}