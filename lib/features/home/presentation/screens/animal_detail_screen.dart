import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/add_animal_sheet.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: CustomScrollView(
          slivers: [
            // ── Hero AppBar ──────────────────────────────────────────────
            SliverToBoxAdapter(child: _HeroSection(animal: animal)),

            // ── 3 Əməliyyat düyməsi ──────────────────────────────────────
            SliverToBoxAdapter(child: _ActionButtons(animal: animal)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Canlı mövqe
                  _SectionTitle(title: 'Canlı mövqe'),
                  const SizedBox(height: 8),
                  _LocationCard(animal: animal),
                  const SizedBox(height: 16),

                  // GPS cihazı
                  _SectionTitle(title: 'GPS cihazı'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    _InfoRow('Çip ID', animal.chipId ?? 'Təyin edilməyib'),
                    _InfoRow('Son yeniləmə', _formatTime(animal.lastUpdate),
                        valueColor: const Color(0xFF185FA5)),
                    _InfoRow('Batareya', '',
                        customValue: _BatteryWidget(
                            level: animal.batteryLevel ?? 0)),
                    _InfoRow('Status',
                        animal.isTracking ? 'Onlayn' : 'Offline',
                        valueColor: animal.isTracking
                            ? const Color(0xFF1D9E75)
                            : Colors.grey),
                  ]),
                  const SizedBox(height: 16),

                  // Günlük aktivlik
                  _SectionTitle(title: 'Bu günkü aktivlik'),
                  const SizedBox(height: 8),
                  _ActivityCard(animal: animal),
                  const SizedBox(height: 16),

                  // Heyvan məlumatları
                  _SectionTitle(title: 'Heyvan məlumatları'),
                  const SizedBox(height: 8),
                  _InfoCard(rows: [
                    _InfoRow('Növ', animal.typeName),
                    _InfoRow('Zona',
                        animal.zoneName ?? 'Təyin edilməyib'),
                    _InfoRow('Sürət',
                        animal.speed != null
                            ? '${animal.speed!.toStringAsFixed(1)} km/h'
                            : '—'),
                    _InfoRow('Son mövqe',
                        animal.lastLatitude != null
                            ? '${animal.lastLatitude!.toStringAsFixed(4)}, ${animal.lastLongitude!.toStringAsFixed(4)}'
                            : 'Məlumat yoxdur'),
                    if (animal.notes != null && animal.notes!.isNotEmpty)
                      _InfoRow('Qeyd', animal.notes!),
                  ]),
                  const SizedBox(height: 16),

                  // Sil düyməsi
                  _DeleteButton(animal: animal),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Naməlum';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq əvvəl';
    if (diff.inHours < 24) return '${diff.inHours} saat əvvəl';
    return '${diff.inDays} gün əvvəl';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AnimalEntity animal;
  const _HeroSection({required this.animal});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isAlert = animal.zoneStatus == AnimalZoneStatus.alert;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: top + 10, left: 20, right: 20, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Geri
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(children: [
            const Icon(Icons.chevron_left_rounded,
                color: Color(0xFF1D9E75), size: 22),
            const Text('Geri',
                style: TextStyle(
                    color: Color(0xFF1D9E75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 14),
        // Avatar + info
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _typeColor(animal.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: isAlert
                  ? Border.all(
                      color: const Color(0xFFE24B4A).withValues(alpha: 0.4),
                      width: 1.5)
                  : null,
            ),
            child: Center(
                child: Text(animal.typeEmoji,
                    style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 3),
                  Text(
                    '${animal.typeName} · ${_formatCreated(animal.createdAt)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _Badge(
                      label: animal.isTracking ? 'Canlı izləmə' : 'Offline',
                      color: animal.isTracking
                          ? const Color(0xFF185FA5)
                          : Colors.grey,
                      icon: Iconsax.radar,
                    ),
                    if (animal.zoneName != null)
                      _Badge(
                          label: animal.zoneName!,
                          color: Colors.grey,
                          icon: Iconsax.home),
                    if ((animal.batteryLevel ?? 1) < 0.3)
                      const _Badge(
                          label: 'Pil az',
                          color: Color(0xFFBA7517),
                          icon: Iconsax.battery_disable),
                    if (isAlert)
                      const _Badge(
                          label: 'ALERT',
                          color: Color(0xFFE24B4A),
                          icon: Iconsax.warning_2),
                  ]),
                ]),
          ),
        ]),
      ]),
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

  String _formatCreated(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff < 30) return '$diff gün əvvəl əlavə edildi';
    return '${(diff / 30).floor()} ay əvvəl';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final AnimalEntity animal;
  const _ActionButtons({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        // Xəritədə bax
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.map,
            label: 'Xəritədə bax',
            color: const Color(0xFF1D9E75),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MapScreen(
                      highlightedAnimalIds: [animal.id],
                      animalEntities: [animal],
                    ))),
          ),
        ),
        const SizedBox(width: 8),
        // Redaktə et
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.edit,
            label: 'Redaktə et',
            color: const Color(0xFF185FA5),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddAnimalSheet(
                ownerId: animal.ownerId,
                existingAnimal: animal,
                onSubmit: (name, type, chipId, notes, zoneId, zoneName) {
                  context.read<AnimalBloc>().add(EditAnimalEvent(
                        animalId: animal.id,
                        name: name,
                        type: type,
                        chipId: chipId.isNotEmpty ? chipId : null,
                        notes: notes.isNotEmpty ? notes : null,
                        zoneId: zoneId,
                        zoneName: zoneName,
                      ));
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Kayıb modu
        Expanded(
          child: _ActionBtn(
            icon: Iconsax.radar,
            label: 'Kayıb modu',
            color: const Color(0xFFE24B4A),
            onTap: () => _showLostModeDialog(context),
          ),
        ),
      ]),
    );
  }

  void _showLostModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kayıb modu',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            '"${animal.name}" üçün kayıb modu aktiv edilsin?\n'
            'GPS yüksək tezlikdə konum göndərəcək.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Aktiv et',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
// Location Card — mini xəritə + koordinat
// ─────────────────────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final AnimalEntity animal;
  const _LocationCard({required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MapScreen(
                highlightedAnimalIds: [animal.id],
                animalEntities: [animal],
              ))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // Mini xəritə
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(painter: _DetailMapPainter()),
          ),
          // Koordinat sətri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Iconsax.location, size: 14, color: Color(0xFF1D9E75)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  animal.lastLatitude != null
                      ? '${animal.lastLatitude!.toStringAsFixed(5)}, ${animal.lastLongitude!.toStringAsFixed(5)}'
                      : 'Mövqe məlumatı yoxdur',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E)),
                ),
              ),
              Text(
                animal.zoneName ?? '',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DetailMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFD4E5F0));
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 30,
        Paint()
          ..color = const Color(0xFF185FA5).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 30,
        Paint()
          ..color = const Color(0xFF185FA5).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    // Hərəkət izi
    final trail = Path()
      ..moveTo(s.width * .7, s.height * .65)
      ..quadraticBezierTo(
          s.width * .6, s.height * .55, s.width * .5, s.height * .5);
    canvas.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFF185FA5).withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    // Nöqtə
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 6,
        Paint()..color = const Color(0xFF185FA5));
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 3,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Card — 24h bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final AnimalEntity animal;
  const _ActivityCard({required this.animal});

  // Demo aktivlik məlumatları (real datadan gəlməlidir)
  static const _hours = [
    6, 5, 5, 5, 6, 8, 12, 22,
    68, 82, 95, 88, 38, 24, 28,
    72, 100, 78, 48, 42, 24, 16, 10, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final dist = animal.speed != null
        ? '${(animal.speed! * 3.5).toStringAsFixed(1)} km'
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(children: [
        // Stat sətri
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem(dist, 'Məsafə', const Color(0xFF1D9E75)),
                _statItem('3.5 s', 'Hərəkət', const Color(0xFF185FA5)),
                _statItem('4.5 s', 'Dinləmə', const Color(0xFFBA7517)),
                _statItem('2 s', 'Otlama', const Color(0xFF0F6E56)),
              ]),
        ),
        const Divider(height: 1, thickness: 0.5),
        // Bar chart
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_hours.length, (i) {
                final pct = _hours[i] / 100.0;
                final isActive = _hours[i] > 30;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: (pct * 46).clamp(4.0, 46.0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF185FA5)
                          : const Color(0xFFE6F1FB),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // Saat labelları
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['00', '06', '12', '18', '23']
                .map((t) => Text(t,
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey[400])))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _statItem(String val, String lbl, Color c) => Column(children: [
        Text(val,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 2),
        Text(lbl,
            style:
                TextStyle(fontSize: 9, color: Colors.grey[500])),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card + Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: Colors.grey.shade100, width: 0.5)),
            ),
            child: Row(children: [
              Text(e.value.label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              e.value.customValue ??
                  Text(e.value.value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: e.value.valueColor ??
                              const Color(0xFF1A1A2E)),
                      textAlign: TextAlign.right),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? customValue;

  const _InfoRow(this.label, this.value,
      {this.valueColor, this.customValue});
}

// ─────────────────────────────────────────────────────────────────────────────
// Battery Widget
// ─────────────────────────────────────────────────────────────────────────────

class _BatteryWidget extends StatelessWidget {
  final double level;
  const _BatteryWidget({required this.level});

  @override
  Widget build(BuildContext context) {
    final pct = (level * 100).toInt();
    final color = level > 0.5
        ? const Color(0xFF1D9E75)
        : level > 0.2
            ? const Color(0xFFBA7517)
            : const Color(0xFFE24B4A);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 56, height: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: level,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('$pct%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Button
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  final AnimalEntity animal;
  const _DeleteButton({required this.animal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Iconsax.trash, size: 16, color: Color(0xFFE24B4A)),
        label: const Text('Heyvanı sil',
            style: TextStyle(
                color: Color(0xFFE24B4A), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
              color: Color(0xFFE24B4A), width: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${animal.typeEmoji} ${animal.name} silinsin?',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Bu əməliyyat geri alına bilməz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AnimalBloc>()
                  .add(DeleteAnimalEvent(animal.id));
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