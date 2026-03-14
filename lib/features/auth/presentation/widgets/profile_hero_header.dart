import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';

class ProfileHeroHeader extends StatelessWidget {
  final UserEntity user;

  const ProfileHeroHeader({super.key, required this.user});

  String get _initials {
    if (user.name.isEmpty) return '?';
    return user.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTopBar(),
        const SizedBox(height: 18),
        _buildProfileCard(),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [
      const Text('Profil',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.5)),
      const Spacer(),
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Iconsax.setting_2,
            size: 18, color: Color(0xFF1A1A2E)),
      ),
    ]);
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0D2818)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        _buildAvatar(),
        const SizedBox(width: 14),
        Expanded(child: _buildUserInfo()),
        Icon(Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.3), size: 20),
      ]),
    );
  }

  Widget _buildAvatar() {
    return Stack(alignment: Alignment.center, children: [
      Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
        ),
      ),
      Container(
        width: 60, height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF56D97B), Color(0xFF27AE60)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(_initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  Widget _buildUserInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(user.name,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(user.email,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded,
              color: Color(0xFF2ECC71), size: 11),
          SizedBox(width: 4),
          Text('Premium',
              style: TextStyle(
                  color: Color(0xFF2ECC71),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }
}