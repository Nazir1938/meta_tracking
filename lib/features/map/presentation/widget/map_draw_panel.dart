import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum DrawMode { none, radius, freehand }

// Redaktə rejimi — mövcud zona üçün
enum EditMode { none, editRadius, editPolygon }

class MapDrawPanel extends StatelessWidget {
  final DrawMode drawMode;
  final double radius;
  final int freehandPointCount;
  final ValueChanged<DrawMode> onModeChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const MapDrawPanel({
    super.key,
    required this.drawMode,
    required this.radius,
    required this.freehandPointCount,
    required this.onModeChanged,
    required this.onRadiusChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12), blurRadius: 16)
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _modeTab('⊙  Radius', drawMode == DrawMode.radius,
                () => onModeChanged(DrawMode.radius)),
            const SizedBox(width: 10),
            _modeTab('✏  Azad Çiz', drawMode == DrawMode.freehand,
                () => onModeChanged(DrawMode.freehand)),
          ]),
          const SizedBox(height: 14),
          if (drawMode == DrawMode.radius)
            Row(children: [
              const Text('Radius:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: radius.clamp(100.0, 5000.0),
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: const Color(0xFF1D9E75),
                  label: '${(radius / 1000).toStringAsFixed(2)} km',
                  onChanged: onRadiusChanged,
                ),
              ),
              Text('${(radius / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D9E75))),
            ]),
          if (drawMode == DrawMode.freehand)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Xəritəyə toxunaraq nöqtələri əlavə edin.\n'
                'Ən az 3 nöqtə lazımdır. ($freehandPointCount seçildi)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Iconsax.close_circle, size: 16),
                label: const Text('İmtina'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Iconsax.tick_circle, size: 16),
                label: const Text('Təsdiq Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback fn) => Expanded(
        child: GestureDetector(
          onTap: fn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.10)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? const Color(0xFF1D9E75) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? const Color(0xFF1D9E75) : Colors.grey[600])),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Polygon redaktə paneli — xəritədə yenidən çəkmək üçün
// ─────────────────────────────────────────────────────────────────────────────

class MapEditPolygonPanel extends StatelessWidget {
  final int pointCount;
  final String zoneName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const MapEditPolygonPanel({
    super.key,
    required this.pointCount,
    required this.zoneName,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12), blurRadius: 16)
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          // Başlıq
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Iconsax.edit, color: Color(0xFF9B59B6), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('"$zoneName" — Polygon Redaktəsi',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(
                      'Xəritəyə toxunaraq yeni nöqtələri əlavə edin. '
                      'Ən az 3 nöqtə lazımdır.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          // Nöqtə sayı göstəricisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Iconsax.location, color: Color(0xFF1D9E75), size: 16),
              const SizedBox(width: 8),
              Text('$pointCount nöqtə seçildi',
                  style: TextStyle(
                      fontSize: 12,
                      color: pointCount >= 3
                          ? const Color(0xFF1D9E75)
                          : Colors.orange,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (pointCount < 3)
                Text('${3 - pointCount} daha lazımdır',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Iconsax.close_circle, size: 16),
                label: const Text('İmtina'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: pointCount >= 3 ? onConfirm : null,
                icon: const Icon(Iconsax.tick_circle, size: 16),
                label: const Text('Yadda Saxla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zona adı dialog
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showZoneNameDialog(
  BuildContext context,
  void Function(String name, String? desc) onConfirm,
) async {
  final nameCtrl = TextEditingController(
      text: 'Zona-${DateTime.now().millisecondsSinceEpoch % 1000}');
  final descCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title:
          const Text('Zona adı', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dialogField(nameCtrl, 'Ad *', 'Otlaq-1', autofocus: true),
        const SizedBox(height: 10),
        _dialogField(descCtrl, 'Açıqlama (ixtiyari)', ''),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            final name = nameCtrl.text.trim().isEmpty
                ? 'Yeni Zona'
                : nameCtrl.text.trim();
            onConfirm(name,
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
          },
          child: const Text('Yarat',
              style: TextStyle(
                  color: Color(0xFF1D9E75), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Zona redaktə dialog — dairə üçün (radius slider)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showZoneEditDialog(
  BuildContext context,
  ZoneEditParams params,
  void Function(String name, String? desc, double radius) onSave,
) async {
  final nameCtrl = TextEditingController(text: params.name);
  final descCtrl = TextEditingController(text: params.description ?? '');
  double radius = params.radiusInMeters.clamp(100.0, 5000.0);

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Zonayı Redaktə Et',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(nameCtrl, 'Ad *', ''),
          const SizedBox(height: 10),
          _dialogField(descCtrl, 'Açıqlama (ixtiyari)', ''),
          // Yalnız dairə zona üçün radius slider
          const SizedBox(height: 12),
          Row(children: [
            Text('${(radius / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D9E75))),
            Expanded(
              child: Slider(
                value: radius,
                min: 100,
                max: 5000,
                divisions: 49,
                activeColor: const Color(0xFF1D9E75),
                label: '${(radius / 1000).toStringAsFixed(2)} km',
                onChanged: (v) => set(() => radius = v),
              ),
            ),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSave(
                nameCtrl.text.trim().isEmpty
                    ? params.name
                    : nameCtrl.text.trim(),
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                radius,
              );
            },
            child: const Text('Yadda Saxla',
                style: TextStyle(
                    color: Color(0xFF1D9E75), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Polygon zona redaktə seçim dialogu
// ─────────────────────────────────────────────────────────────────────────────

/// Polygon zonasını redaktə etmə seçimlərini göstərir:
/// 1. Yalnız adı dəyiş
/// 2. Xəritədə yenidən çək
Future<PolygonEditChoice?> showPolygonEditChoiceDialog(
  BuildContext context,
  ZoneEditParams params,
  void Function(String name, String? desc) onNameOnly,
) async {
  final nameCtrl = TextEditingController(text: params.name);
  final descCtrl = TextEditingController(text: params.description ?? '');
  PolygonEditChoice? choice;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Polygon Zonasını Redaktə Et',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dialogField(nameCtrl, 'Ad *', ''),
        const SizedBox(height: 10),
        _dialogField(descCtrl, 'Açıqlama (ixtiyari)', ''),
        const SizedBox(height: 14),
        // Sahəni yenidən çək seçimi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9B59B6).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                width: 0.5),
          ),
          child: const Row(children: [
            Icon(Iconsax.edit, color: Color(0xFF9B59B6), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sahəni xəritədə yenidən çəkmək üçün "Yenidən Çək" düyməsini istifadə edin.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9B59B6)),
              ),
            ),
          ]),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İmtina', style: TextStyle(color: Colors.grey[500]))),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            choice = PolygonEditChoice.redraw;
          },
          child: const Text('Yenidən Çək',
              style: TextStyle(
                  color: Color(0xFF9B59B6), fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            choice = PolygonEditChoice.nameOnly;
            onNameOnly(
              nameCtrl.text.trim().isEmpty ? params.name : nameCtrl.text.trim(),
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            );
          },
          child: const Text('Yadda Saxla',
              style: TextStyle(
                  color: Color(0xFF1D9E75), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  return choice;
}

enum PolygonEditChoice { nameOnly, redraw }

// ─────────────────────────────────────────────────────────────────────────────
// Edit params
// ─────────────────────────────────────────────────────────────────────────────

class ZoneEditParams {
  final String name;
  final String? description;
  final double radiusInMeters;
  final bool isCircle;

  const ZoneEditParams({
    required this.name,
    this.description,
    required this.radiusInMeters,
    required this.isCircle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared dialog field
// ─────────────────────────────────────────────────────────────────────────────

TextField _dialogField(
  TextEditingController ctrl,
  String label,
  String hint, {
  bool autofocus = false,
}) {
  return TextField(
    controller: ctrl,
    autofocus: autofocus,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
