import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class ProfileMenuSection extends StatelessWidget {
  final List<AnimalEntity> animals;

  const ProfileMenuSection({super.key, required this.animals});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('HESAB'),
        const SizedBox(height: 8),
        _menuGroup([
          _menuTile(
              icon: Iconsax.user,
              label: 'Şəxsi Məlumatlar',
              onTap: () {}),
          _menuTile(
              icon: Iconsax.pet,
              label: 'Heyvanlarım',
              badge: '${animals.length}',
              badgeColor: const Color(0xFF2ECC71),
              onTap: () {}),
          _menuTile(
              icon: Iconsax.location,
              label: 'Geofencing Zonaları',
              onTap: () {}),
          _menuTile(
              icon: Iconsax.clock,
              label: 'Hərəkət Tarixi',
              onTap: () {},
              last: true),
        ]),
        const SizedBox(height: 16),
        _sectionLabel('TƏNZİMLƏMƏLƏR'),
        const SizedBox(height: 8),
        _menuGroup([
          _menuTile(
              icon: Iconsax.notification,
              label: 'Bildiriş Tənzimləri',
              onTap: () {}),
          _menuTile(
              icon: Iconsax.global,
              label: 'Dil: Azərbaycan',
              onTap: () {}),
          _menuTile(
              icon: Iconsax.message_question,
              label: 'Dəstək',
              onTap: () {},
              last: true),
        ]),
      ]),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.5));

  Widget _menuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    bool last = false,
  }) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E))),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF2ECC71))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? const Color(0xFF2ECC71))),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[300], size: 18),
          ]),
        ),
      ),
      if (!last)
        Container(
            margin: const EdgeInsets.only(left: 66),
            height: 0.8,
            color: const Color(0xFFF0F2F5)),
    ]);
  }
}