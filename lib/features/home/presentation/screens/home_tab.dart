import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/home/presentation/screens/animal_detail_screen.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: BlocBuilder<AnimalBloc, AnimalState>(
        builder: (context, animalState) {
          final animals = animalState is AnimalLoaded
              ? animalState.animals
              : <AnimalEntity>[];
          final alertAnimals = animals
              .where((a) => a.zoneStatus == AnimalZoneStatus.alert)
              .toList();
          final activeCount = animals.where((a) => a.isTracking).length;
          final insideCount = animals
              .where((a) => a.zoneStatus == AnimalZoneStatus.inside)
              .length;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            body: RefreshIndicator(
              color: const Color(0xFF1D9E75),
              displacement: MediaQuery.of(context).padding.top + 8,
              onRefresh: () async {
                final auth = context.read<AuthBloc>().state;
                if (auth is AuthAuthenticated) {
                  context
                      .read<AnimalBloc>()
                      .add(WatchAnimalsEvent(auth.user.id));
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── AppBar ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _AppBar(alertCount: alertAnimals.length),
                  ),

                  // ── 4 Summary kart ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SummaryCards(
                      total: animals.length,
                      active: activeCount,
                      inside: insideCount,
                      alert: alertAnimals.length,
                    ),
                  ),

                  // ── Sürüşən məzmun ──────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Alert banner
                        if (alertAnimals.isNotEmpty) ...[
                          _AlertBanner(animals: alertAnimals),
                          const SizedBox(height: 14),
                        ],

                        // Xəritə preview
                        _SectionRow(
                          title: 'Canlı xəritə',
                          action: 'Tam bax →',
                          onAction: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MapScreen()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MapCard(
                          zoneCount: _getZoneCount(context),
                          animalCount: animals.length,
                          animals: animals,
                        ),
                        const SizedBox(height: 18),

                        // Heyvanlar
                        _SectionRow(
                          title: 'Heyvanlar',
                          action: 'Hamısı →',
                          onAction: () {},
                        ),
                        const SizedBox(height: 8),
                        if (animals.isEmpty)
                          const _EmptyHint(
                              text: '+ düyməsindən heyvan əlavə edin')
                        else
                          ...animals.take(3).map(
                                (a) => _AnimalTile(
                                  animal: a,
                                  onTap: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AnimalDetailScreen(animal: a),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 18),

                        // Zonalar
                        _SectionRow(
                          title: 'Zonalar',
                          action: '+ Əlavə et',
                          onAction: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MapScreen()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ZoneGrid(animals: animals, context: context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getZoneCount(BuildContext context) {
    final s = context.read<ZoneBloc>().state;
    return s is ZonesLoaded ? s.zones.length : 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final int alertCount;
  const _AppBar({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final auth = context.read<AuthBloc>().state;
    final name =
        auth is AuthAuthenticated ? auth.user.name : 'İstifadəçi';
    final avatarUrl =
        auth is AuthAuthenticated ? auth.user.avatarUrl : null;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (ctx, ns) {
        final unread = ns is NotificationLoaded ? ns.unreadCount : 0;
        return Container(
          color: Colors.white,
          padding: EdgeInsets.only(
              top: top + 12, left: 16, right: 16, bottom: 14),
          child: Row(children: [
            _AvatarWidget(name: name, url: avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_greeting(),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                            height: 1.2)),
                  ]),
            ),
            if (alertCount > 0) ...[
              _badge(alertCount),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: const Icon(Iconsax.notification,
                      size: 20, color: Color(0xFF1A1A2E)),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE24B4A),
                            shape: BoxShape.circle)),
                  ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _badge(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE24B4A).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Iconsax.warning_2, size: 11, color: Color(0xFFE24B4A)),
          const SizedBox(width: 3),
          Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE24B4A),
                  fontWeight: FontWeight.w700)),
        ]),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Sabahınız xeyir 👋';
    if (h < 18) return 'Günortanız xeyir 👋';
    return 'Axşamınız xeyir 👋';
  }
}

class _AvatarWidget extends StatelessWidget {
  final String name;
  final String? url;
  const _AvatarWidget({required this.name, this.url});

  @override
  Widget build(BuildContext context) {
    final init = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(url!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initWidget(init))
          : _initWidget(init),
    );
  }

  Widget _initWidget(String i) => Center(
        child: Text(i,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D9E75))),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Cards — 4 kart yan-yana
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int total, active, inside, alert;
  const _SummaryCards({
    required this.total,
    required this.active,
    required this.inside,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(children: [
        _card('Ümumi', total, const Color(0xFF185FA5), Iconsax.pet),
        const SizedBox(width: 8),
        _card('Aktiv', active, const Color(0xFF1D9E75), Iconsax.location),
        const SizedBox(width: 8),
        _card('İçərdə', inside, const Color(0xFF0F6E56), Iconsax.home),
        const SizedBox(width: 8),
        _card('Alert', alert, const Color(0xFFE24B4A), Iconsax.warning_2),
      ]),
    );
  }

  Widget _card(String lbl, int val, Color c, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: c, size: 15),
            ),
            const SizedBox(height: 5),
            Text('$val',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c)),
            Text(lbl,
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Row — başlıq + action link
// ─────────────────────────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final String title, action;
  final VoidCallback onAction;
  const _SectionRow(
      {required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          GestureDetector(
            onTap: onAction,
            child: Text(action,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1D9E75),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final List<AnimalEntity> animals;
  const _AlertBanner({required this.animals});

  @override
  Widget build(BuildContext context) {
    final names = animals.take(2).map((a) => a.name).join(' və ');
    final extra = animals.length > 2 ? ' +${animals.length - 2}' : '';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AnimalDetailScreen(animal: animals.first))),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFE24B4A).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.warning_2,
                size: 18, color: Color(0xFFE24B4A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${animals.length} heyvan zona xaricindədir',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA32D2D)),
                  ),
                  const SizedBox(height: 2),
                  Text('$names$extra',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFE24B4A))),
                ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFE24B4A), size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Card
// ─────────────────────────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final int zoneCount, animalCount;
  final List<AnimalEntity> animals;
  const _MapCard(
      {required this.zoneCount,
      required this.animalCount,
      required this.animals});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MapScreen(animalEntities: animals))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(painter: _MapPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Əsas otlaq sahəsi',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text('$zoneCount zona · $animalCount heyvan',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                  ]),
              const Spacer(),
              const Text('Xəritəyə bax →',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFD4E5F0));

    // Zone dairəsi
    canvas.drawCircle(Offset(s.width * .38, s.height * .52), 36,
        Paint()
          ..color = const Color(0xFF1D9E75).withValues(alpha: 0.14)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(s.width * .38, s.height * .52), 36,
        Paint()
          ..color = const Color(0xFF1D9E75).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Yol
    final road = Path()
      ..moveTo(0, s.height * .62)
      ..quadraticBezierTo(
          s.width * .5, s.height * .56, s.width, s.height * .62);
    canvas.drawPath(
        road,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);

    // Heyvan nöqtələri
    final gp = Paint()..color = const Color(0xFF1D9E75);
    final rp = Paint()..color = const Color(0xFFE24B4A);
    final grp = Paint()..color = const Color(0xFF888780);

    for (final d in [
      Offset(s.width * .32, s.height * .50),
      Offset(s.width * .38, s.height * .56),
      Offset(s.width * .35, s.height * .41),
      Offset(s.width * .43, s.height * .47),
    ]) canvas.drawCircle(d, 4.5, gp);

    canvas.drawCircle(Offset(s.width * .57, s.height * .38), 4.5, rp);
    canvas.drawCircle(Offset(s.width * .62, s.height * .65), 4.5, rp);
    canvas.drawCircle(Offset(s.width * .22, s.height * .34), 4, grp);
    canvas.drawCircle(Offset(s.width * .80, s.height * .50), 4, grp);

    // Label
    final textPainter = TextPainter(
      text: const TextSpan(
          text: 'Otlaq-1',
          style: TextStyle(
              color: Color(0xFF1D9E75),
              fontSize: 10,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelBg = RRect.fromRectAndRadius(
        Rect.fromLTWH(8, s.height - 26, textPainter.width + 16, 18),
        const Radius.circular(6));
    canvas.drawRRect(
        labelBg,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.92));
    textPainter.paint(canvas, Offset(16, s.height - 22));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animal Tile — şəkildəki kart
// ─────────────────────────────────────────────────────────────────────────────

class _AnimalTile extends StatelessWidget {
  final AnimalEntity animal;
  final VoidCallback onTap;
  const _AnimalTile({required this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAlert = animal.zoneStatus == AnimalZoneStatus.alert;
    final statusColor = _statusColor(animal.zoneStatus);
    final statusLabel = _statusLabel(animal.zoneStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAlert
              ? const Color(0xFFE24B4A).withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAlert
                ? const Color(0xFFE24B4A).withValues(alpha: 0.25)
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Row(children: [
          // Emoji
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _typeColor(animal.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
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
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Iconsax.location, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        animal.zoneName ?? 'Zona təyin edilməyib',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ]),
          ),
          const SizedBox(width: 8),
          // Sağ tərəf
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
            const SizedBox(height: 5),
            if (animal.batteryLevel != null)
              Text('🔋 ${(animal.batteryLevel! * 100).toInt()}%',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[500])),
          ]),
        ]),
      ),
    );
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone Grid — 2 sütun, progress bar ilə
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneGrid extends StatelessWidget {
  final List<AnimalEntity> animals;
  final BuildContext context;
  const _ZoneGrid({required this.animals, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return BlocBuilder<ZoneBloc, ZoneState>(
      builder: (ctx, zoneState) {
        final zones =
            zoneState is ZonesLoaded ? zoneState.zones : <ZoneEntity>[];

        if (zones.isEmpty) {
          return _EmptyHint(text: 'Hələ zona yoxdur. Xəritədən əlavə edin.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: zones.length,
          itemBuilder: (_, i) {
            final zone = zones[i];
            final inZone = animals
                .where((a) => a.zoneId == zone.id)
                .length;
            final capacity = 100;
            final pct = (inZone / capacity).clamp(0.0, 1.0);
            return _ZoneTile(
              zone: zone,
              animalCount: inZone,
              pct: pct,
              onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => MapScreen())),
            );
          },
        );
      },
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final ZoneEntity zone;
  final int animalCount;
  final double pct;
  final VoidCallback onTap;
  const _ZoneTile(
      {required this.zone,
      required this.animalCount,
      required this.pct,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = zone.isActive
        ? const Color(0xFF1D9E75)
        : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(_zoneEmoji(zone.name),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(zone.name,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E)),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              Text('$animalCount heyvan',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[500])),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
      ),
    );
  }

  String _zoneEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('otlaq') || n.contains('çəmən')) return '🌿';
    if (n.contains('ahır') || n.contains('bina')) return '🏠';
    if (n.contains('su')) return '💧';
    if (n.contains('qarantina') || n.contains('qadağa')) return '🔒';
    return '📍';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Center(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ),
      );
}