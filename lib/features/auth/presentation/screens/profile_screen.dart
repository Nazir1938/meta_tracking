import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Profile Screen');
  }

  void _logout(BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF5350), size: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Çıxış Et',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hesabdan çıxmaq istədiyinizə əminsiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text('Ləğv et',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ctx.read<AuthBloc>().add(const LogoutEvent());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('Çıx',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(ctx).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (_) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (ctx, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: user == null
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                : _buildBody(ctx, user),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, UserEntity user) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero header ──────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeroHeader(ctx, user)),
        // ── Stats ────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildStats()),
        // ── Menu sections ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(children: [
              _sectionLabel('HESAB'),
              const SizedBox(height: 8),
              _menuGroup([
                _menuTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Şəxsi Məlumatlar',
                    onTap: () {}),
                _menuTile(
                    icon: Icons.pets_outlined,
                    label: 'Heyvanlarım',
                    onTap: () {}),
                _menuTile(
                    icon: Icons.fence_rounded,
                    label: 'Geofencing Zonaları',
                    badge: '2',
                    badgeColor: const Color(0xFF3498DB),
                    onTap: () {}),
                _menuTile(
                    icon: Icons.history_rounded,
                    label: 'Hərəkət Tarixi',
                    onTap: () {},
                    last: true),
              ]),
              const SizedBox(height: 16),
              _sectionLabel('TƏNZİMLƏMƏLƏR'),
              const SizedBox(height: 8),
              _menuGroup([
                _menuTile(
                    icon: Icons.notifications_outlined,
                    label: 'Bildiriş Tənzimləri',
                    onTap: () {}),
                _menuTile(
                    icon: Icons.language_rounded,
                    label: 'Dil: Azərbaycan',
                    onTap: () {}),
                _menuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Dəstək',
                    onTap: () {},
                    last: true),
              ]),
              const SizedBox(height: 16),
              // Logout
              GestureDetector(
                onTap: () => _logout(ctx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Color(0xFFEF5350), size: 18),
                    ),
                    const SizedBox(width: 14),
                    const Text('Çıxış Et',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF5350),
                        )),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[300], size: 20),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext ctx, UserEntity user) {
    final initials = user.name.isNotEmpty
        ? user.name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final topPad = MediaQuery.of(ctx).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 0),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top bar
        Row(children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_outlined,
                size: 18, color: Color(0xFF1A1A2E)),
          ),
        ]),
        const SizedBox(height: 18),

        // Profile card
        Container(
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
            // Avatar with glow
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF56D97B), Color(0xFF27AE60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 3),
                    Text(user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        )),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2ECC71).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF2ECC71)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(children: const [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF2ECC71), size: 11),
                          SizedBox(width: 4),
                          Text('Premium',
                              style: TextStyle(
                                color: Color(0xFF2ECC71),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )),
                        ]),
                      ),
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        _statItem('4', 'Heyvan', Icons.pets_rounded, const Color(0xFF2ECC71)),
        _vDivider(),
        _statItem('2', 'Zona', Icons.fence_rounded, const Color(0xFF3498DB)),
        _vDivider(),
        _statItem(
            '1', 'Alert', Icons.warning_amber_rounded, const Color(0xFFFF4444)),
        _vDivider(),
        _statItem('81%', 'Batareya', Icons.battery_charging_full_rounded,
            const Color(0xFF9B59B6)),
      ]),
    );
  }

  Widget _statItem(String val, String lbl, IconData icon, Color color) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            )),
        Text(lbl, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 44, color: const Color(0xFFF0F2F5));

  Widget _sectionLabel(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.5,
        ),
      );

  Widget _menuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
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
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF1A1A2E)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    )),
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
                        color: badgeColor ?? const Color(0xFF2ECC71),
                      )),
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
            color: const Color(0xFFF0F2F5),
          ),
      ],
    );
  }
}
