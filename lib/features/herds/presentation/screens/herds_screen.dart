import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/screens/create_herd_sheet.dart';
import 'package:meta_tracking/features/herds/presentation/screens/herd_detail_screen.dart';

class HerdsScreen extends StatelessWidget {
  const HerdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: BlocBuilder<HerdBloc, HerdState>(
          builder: (ctx, herdState) {
            final herds =
                herdState is HerdsLoaded ? herdState.herds : <HerdEntity>[];
            final unreadAlerts =
                herdState is HerdsLoaded ? herdState.unreadAlertCount : 0;

            return CustomScrollView(
              slivers: [
                // AppBar
                SliverToBoxAdapter(
                  child: _AppBar(unreadAlerts: unreadAlerts),
                ),

                if (herds.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      onTap: () => _showCreateSheet(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _HerdCard(
                          herd: herds[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  HerdDetailScreen(herd: herds[i]),
                            ),
                          ),
                        ),
                        childCount: herds.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateSheet(context),
          backgroundColor: const Color(0xFF1D9E75),
          icon: const Icon(Iconsax.people, color: Colors.white, size: 20),
          label: const Text('Naxır Yarat',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HerdBloc>(),
        child: BlocProvider.value(
          value: context.read<AnimalBloc>(),
          child: CreateHerdSheet(ownerId: auth.user.id),
        ),
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final int unreadAlerts;
  const _AppBar({required this.unreadAlerts});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: top + 12, left: 16, right: 16, bottom: 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left_rounded,
              color: Color(0xFF1D9E75), size: 26),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Naxırlarım',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
        ),
        if (unreadAlerts > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE24B4A).withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.warning_2,
                  size: 12, color: Color(0xFFE24B4A)),
              const SizedBox(width: 4),
              Text('$unreadAlerts',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE24B4A),
                      fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }
}

// ─── Herd Card ────────────────────────────────────────────────────────────────

class _HerdCard extends StatelessWidget {
  final HerdEntity herd;
  final VoidCallback onTap;
  const _HerdCard({required this.herd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final herdState = context.watch<HerdBloc>().state;
    final alerts = herdState is HerdsLoaded
        ? herdState.activeAlerts
            .where((a) => a.herdId == herd.id && !a.isRead)
            .length
        : 0;

    final result = herdState is HerdsLoaded
        ? herdState.separationResults[herd.id]
        : null;

    final hasSeparation = result?.hasSeparation ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasSeparation
              ? const Color(0xFFE24B4A).withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSeparation
                ? const Color(0xFFE24B4A).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          // İkon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: herd.isTracking
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('🐄', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          // İnfo
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(herd.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Iconsax.pet, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${herd.animalCount} heyvan',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 10),
                Icon(Iconsax.radar, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  herd.separationThresholdMeters < 1000
                      ? '${herd.separationThresholdMeters.toInt()} m'
                      : '${(herd.separationThresholdMeters / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ]),
            ]),
          ),
          // Sağ tərəf
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // İzləmə statusu
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: herd.isTracking
                    ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: herd.isTracking
                        ? const Color(0xFF1D9E75)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  herd.isTracking ? 'İzlənir' : 'Passiv',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: herd.isTracking
                          ? const Color(0xFF1D9E75)
                          : Colors.grey),
                ),
              ]),
            ),
            if (alerts > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE24B4A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$alerts alert',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE24B4A),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Text('🐄', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          const Text('Hələ naxır yoxdur',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Heyvanlarınızı qruplandırın',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Iconsax.people, size: 18),
            label: const Text('Naxır Yarat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      );
}