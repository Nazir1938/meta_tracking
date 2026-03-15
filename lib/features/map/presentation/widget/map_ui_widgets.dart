import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class MapAppBar extends StatelessWidget {
  final bool isDrawing;
  final bool locationReady;
  final int zoneCount;
  final int highlightCount;
  final String title;
  final VoidCallback onCancel;

  const MapAppBar({
    super.key,
    required this.isDrawing,
    required this.locationReady,
    required this.zoneCount,
    required this.highlightCount,
    required this.title,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF0A1628),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 8,
          bottom: 10,
        ),
        child: Row(children: [
          const Icon(Iconsax.map, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          if (highlightCount > 0)
            _badge('$highlightCount heyvan', const Color(0xFF4CAF50)),
          _badge('$zoneCount zona', const Color(0xFF1D9E75)),
          if (locationReady) ...[
            const SizedBox(width: 4),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF1D9E75), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('GPS',
                  style: TextStyle(
                      color: Color(0xFF1D9E75),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ],
          if (isDrawing) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onCancel,
              child: const Text('İmtina',
                  style: TextStyle(
                      color: Color(0xFFE24B4A),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Banner
// ─────────────────────────────────────────────────────────────────────────────

class MapInfoBanner extends StatelessWidget {
  final double top;
  final Widget child;

  const MapInfoBanner({super.key, required this.top, required this.child});

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        left: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sağ kontrol düymələri
// ─────────────────────────────────────────────────────────────────────────────

class MapControls extends StatelessWidget {
  final double top;
  final MapType mapType;
  final bool locationReady;
  final bool showZoneList;
  final bool isDrawing;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleMapType;
  final VoidCallback onToggleZoneList;

  const MapControls({
    super.key,
    required this.top,
    required this.mapType,
    required this.locationReady,
    required this.showZoneList,
    required this.isDrawing,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleMapType,
    required this.onToggleZoneList,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        right: 12,
        child: Column(children: [
          _btn(Iconsax.add_square, onZoomIn),
          const SizedBox(height: 8),
          _btn(Icons.remove_rounded, onZoomOut),
          const SizedBox(height: 8),
          _btn(Iconsax.location, onMyLocation,
              color: locationReady
                  ? const Color(0xFF1D9E75)
                  : Colors.grey),
          const SizedBox(height: 8),
          _btn(
            mapType == MapType.hybrid
                ? Icons.map_outlined
                : Icons.satellite_alt_outlined,
            onToggleMapType,
            color: mapType == MapType.hybrid
                ? const Color(0xFF1D9E75)
                : const Color(0xFF1A1A2E),
          ),
          if (!isDrawing) ...[
            const SizedBox(height: 8),
            _btn(
              showZoneList ? Iconsax.close_circle : Iconsax.location,
              onToggleZoneList,
              color: showZoneList
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF1A1A2E),
            ),
          ],
        ]),
      );

  Widget _btn(IconData icon, VoidCallback fn, {Color? color}) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 6)
            ],
          ),
          child: Icon(icon, size: 18,
              color: color ?? const Color(0xFF1A1A2E)),
        ),
      );
}