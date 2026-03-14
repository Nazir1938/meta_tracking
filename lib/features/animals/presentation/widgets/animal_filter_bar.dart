import 'package:flutter/material.dart';

class AnimalFilterBar extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const AnimalFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _chip('Hamısı', 'all'),
          const SizedBox(width: 8),
          _chip('Aktiv', 'active'),
          const SizedBox(width: 8),
          _chip('Alert', 'alert'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isActive = activeFilter == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2ECC71) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : Colors.grey[600],
        )),
      ),
    );
  }
}