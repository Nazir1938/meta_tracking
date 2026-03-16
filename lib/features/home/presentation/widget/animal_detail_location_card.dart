import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class AnimalDetailLocationCard extends StatelessWidget {
  final AnimalEntity animal;
  const AnimalDetailLocationCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MapScreen(
              highlightedAnimalIds: [animal.id],
              animalEntities: [animal]))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(painter: _MapPainter())),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Iconsax.location,
                  size: 14, color: Color(0xFF1D9E75)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  animal.lastLatitude != null
                      ? '${animal.lastLatitude!.toStringAsFixed(5)}, '
                          '${animal.lastLongitude!.toStringAsFixed(5)}'
                      : 'Mövqe məlumatı yoxdur',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E)),
                ),
              ),
              Text(animal.zoneName ?? '',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
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
    canvas.drawRect(Offset.zero & s,
        Paint()..color = const Color(0xFFD4E5F0));
    canvas.drawCircle(
        Offset(s.width * .5, s.height * .5),
        30,
        Paint()
          ..color =
              const Color(0xFF185FA5).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(s.width * .5, s.height * .5),
        30,
        Paint()
          ..color =
              const Color(0xFF185FA5).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .7, s.height * .65)
          ..quadraticBezierTo(s.width * .6, s.height * .55,
              s.width * .5, s.height * .5),
        Paint()
          ..color =
              const Color(0xFF185FA5).withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 6,
        Paint()..color = const Color(0xFF185FA5));
    canvas.drawCircle(Offset(s.width * .5, s.height * .5), 3,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}