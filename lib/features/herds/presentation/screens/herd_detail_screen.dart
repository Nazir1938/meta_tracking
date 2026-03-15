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
        builder: (ctx, animalState) {
          final allAnimals = animalState is AnimalLoaded
              ? animalState.animals
              : <AnimalEntity>[];

          // Bu naxıra aid heyvanlar
          final herdAnimals = allAnimals
              .where((a) => herd.animalIds.contains(a.id))
              .toList();

          // Sürü yoxlaması
          final result = HerdTrackingService.checkSeparation(
            herd: herd,
            animals: allAnimals,
          );

          return BlocBuilder<HerdBloc, HerdState>(
            builder: (ctx, herdState) {
              // Bu naxırın alertları
              final alerts = herdState is HerdsLoaded
                  ? herdState.activeAlerts
                      .where((a) => a.herdId == herd.id)
                      .toList()
                  : <SeparationAlert>[];

              // Güncel herd
              final currentHerd = herdState is HerdsLoaded
                  ? herdState.herds.firstWhere(
                      (h) => h.id == herd.id,
                      orElse: () => herd)
                  : herd;

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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Sürü vəziyyəti kartı
                          const _SectionTitle('Sürü vəziyyəti'),
                          const SizedBox(height: 8),
                          _HerdStatusCard(
                              result: result, herd: currentHerd),
                          const SizedBox(height: 16),

                          // Alertlar
                          if (alerts.isNotEmpty) ...[
                            _SectionTitle('Alertlar (${alerts.length})'),
                            const SizedBox(height: 8),
                            ...alerts.map((a) => _AlertTile(
                                  alert: a,
                                  onTap: () {
                                    context
                                        .read<HerdBloc>()
                                        .add(MarkAlertReadEvent(a.id));
                                  },
                                )),
                            const SizedBox(height: 16),
                          ],

                          // Heyvan siyahısı
                          _SectionTitle('Heyvanlar (${herdAnimals.length})'),
                          const SizedBox(height: 8),
                          if (herdAnimals.isEmpty)
                            _emptyHint('Heyvan yoxdur')
                          else
                            ...herdAnimals.map((a) => _HerdAnimalTile(
                                  animal: a,
                                  isSeparated: result.separatedAnimals
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

                          // Sil düyməsi
                          _DeleteButton(herd: currentHerd),
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
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
      );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Geri
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: Text('🐄', style: TextStyle(fontSize: 28))),
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
              const SizedBox(height: 3),
              Text('${herd.animalCount} heyvan',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _badge(
                  herd.isTracking ? 'İzlənir' : 'İzlənmir',
                  herd.isTracking
                      ? const Color(0xFF1D9E75)
                      : Colors.grey,
                  herd.isTracking ? Iconsax.radar : Iconsax.radar,
                ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

// ─── Action Row ───────────────────────────────────────────────────────────────

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
        // Xəritədə göstər
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
        // İzlə / Dayandır
        Expanded(
          child: _btn(
            icon: herd.isTracking ? Iconsax.pause_circle : Iconsax.radar,
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
        // Alertları sil
        Expanded(
          child: _btn(
            icon: Iconsax.notification,
            label: 'Alertları sil',
            color: Colors.grey,
            onTap: () =>
                context.read<HerdBloc>().add(const ClearAlertsEvent()),
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

// ─── Herd Status Card ─────────────────────────────────────────────────────────

class _HerdStatusCard extends StatelessWidget {
  final HerdSeparationResult result;
  final HerdEntity herd;
  const _HerdStatusCard({required this.result, required this.herd});

  @override
  Widget build(BuildContext context) {
    final spread =
        HerdTrackingService.calculateHerdSpread(result.inHerdAnimals);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.hasSeparation
            ? const Color(0xFFE24B4A).withValues(alpha: 0.05)
            : const Color(0xFF1D9E75).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: result.hasSeparation
              ? const Color(0xFFE24B4A).withValues(alpha: 0.3)
              : const Color(0xFF1D9E75).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(children: [
        Row(children: [
          Icon(
            result.hasSeparation ? Iconsax.warning_2 : Iconsax.tick_circle,
            color: result.hasSeparation
                ? const Color(0xFFE24B4A)
                : const Color(0xFF1D9E75),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.hasSeparation
                  ? '${result.separatedAnimals.length} heyvan sürüdən ayrılıb!'
                  : 'Sürü normal vəziyyətdədir',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: result.hasSeparation
                      ? const Color(0xFFE24B4A)
                      : const Color(0xFF1D9E75)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('İçərdə', result.inHerdAnimals.length,
              const Color(0xFF1D9E75)),
          _stat('Ayrılan', result.separatedAnimals.length,
              const Color(0xFFE24B4A)),
          _stat('GPS yox', result.noLocationAnimals.length,
              Colors.grey),
          _stat(
            'Yayılma',
            null,
            const Color(0xFF185FA5),
            label2: spread < 1000
                ? '${spread.toStringAsFixed(0)}m'
                : '${(spread / 1000).toStringAsFixed(1)}km',
          ),
        ]),
      ]),
    );
  }

  Widget _stat(String label, int? val, Color color, {String? label2}) =>
      Expanded(
        child: Column(children: [
          Text(
            label2 ?? '$val',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ]),
      );
}

// ─── Alert Tile ───────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final SeparationAlert alert;
  final VoidCallback onTap;
  const _AlertTile({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.isRead
              ? Colors.white
              : const Color(0xFFE24B4A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? Colors.grey.shade200
                : const Color(0xFFE24B4A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(alert.animalEmoji,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                '${alert.animalName} — ${alert.typeLabel}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 2),
              Text(
                'Sürü mərkəzindən ${alert.distanceLabel} uzaqda',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
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

// ─── Herd Animal Tile ─────────────────────────────────────────────────────────

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
          color: isSeparated
              ? const Color(0xFFE24B4A).withValues(alpha: 0.04)
              : Colors.white,
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isSeparated
                  ? const Color(0xFFE24B4A).withValues(alpha: 0.12)
                  : const Color(0xFF1D9E75).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 20))),
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
                  const Text('Ayrıldı',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE24B4A),
                          fontWeight: FontWeight.w600)),
                ] else if (animal.lastLatitude != null) ...[
                  const Icon(Icons.circle, size: 7, color: Color(0xFF1D9E75)),
                  const SizedBox(width: 3),
                  Text('Sürüdə',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500])),
                ] else ...[
                  Icon(Icons.circle, size: 7, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text('GPS yox',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[400])),
                ],
              ]),
            ]),
          ),
          if (animal.batteryLevel != null)
            Text('🔋${(animal.batteryLevel! * 100).toInt()}%',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[400])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Iconsax.close_circle,
                size: 16, color: Colors.grey),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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

class _DeleteButton extends StatelessWidget {
  final HerdEntity herd;
  const _DeleteButton({required this.herd});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => _confirm(context),
          icon: const Icon(Iconsax.trash,
              size: 16, color: Color(0xFFE24B4A)),
          label: const Text('Naxırı sil',
              style: TextStyle(
                  color: Color(0xFFE24B4A),
                  fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
                color: Color(0xFFE24B4A), width: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('"${herd.name}" silinsin?',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Naxır silinəcək. Heyvanlar silinməyəcək.'),
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