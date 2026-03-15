import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AnimalFilterBar extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isSelectMode;
  final VoidCallback onToggleSelectMode;

  const AnimalFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isSelectMode,
    required this.onToggleSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          // ── Filtr chipləri ─────────────────────────────────────────────────
          _chip('Hamısı', 'all'),
          const SizedBox(width: 8),
          _chip('Aktiv', 'active'),
          const SizedBox(width: 8),
          _chip('Alert', 'alert'),

          const Spacer(),

          // ── Seç düyməsi ────────────────────────────────────────────────────
          GestureDetector(
            onTap: onToggleSelectMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelectMode
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelectMode
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isSelectMode
                      ? Iconsax.close_circle
                      : Iconsax.tick_square,
                  size: 13,
                  color: isSelectMode
                      ? const Color(0xFF2ECC71)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 5),
                Text(
                  isSelectMode ? 'İmtina' : 'Seç',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelectMode
                        ? const Color(0xFF2ECC71)
                        : Colors.grey[600],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isActive = activeFilter == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2ECC71) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}