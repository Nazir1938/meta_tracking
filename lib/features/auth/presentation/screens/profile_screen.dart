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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıxış',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Hesabdan çıxmaq istəyirsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Xeyr', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppLogger.melumat('PROFİL', 'Çıxış edilir');
              ctx.read<AuthBloc>().add(const LogoutEvent());
            },
            child: const Text(
              'Çıx',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
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
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                  )
                : _buildContent(ctx, user),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, UserEntity user) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(ctx, user)),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _buildMenu(ctx)),
      ],
    );
  }

  Widget _buildHeader(BuildContext ctx, UserEntity user) {
    final initials = user.name.isNotEmpty
        ? user.name
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(ctx).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Menyu',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2ECC71,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Premium Abunə',
                          style: TextStyle(
                            color: Color(0xFF2ECC71),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCCCCCC),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('4', 'Heyvan', Icons.pets_rounded, const Color(0xFF2ECC71)),
          _divider(),
          _stat(
            '2',
            'Zona',
            Icons.location_on_outlined,
            const Color(0xFF3498DB),
          ),
          _divider(),
          _stat(
            '3',
            'Alert',
            Icons.warning_amber_rounded,
            const Color(0xFFFF4444),
          ),
          _divider(),
          _stat(
            '81%',
            'Batareya',
            Icons.battery_4_bar,
            const Color(0xFF9B59B6),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade100);

  Widget _buildMenu(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('HESAB'),
          const SizedBox(height: 8),
          _menuCard([
            _menuRow(
              icon: Icons.person_outline_rounded,
              label: 'Şəxsi Məlumatlar',
              onTap: () => AppLogger.melumat('PROFİL', 'Şəxsi məlumatlar'),
            ),
            _menuDivider(),
            _menuRow(
              icon: Icons.pets_outlined,
              label: 'Heyvanlarım',
              onTap: () => AppLogger.melumat('PROFİL', 'Heyvanlar'),
            ),
            _menuDivider(),
            _menuRow(
              icon: Icons.my_location_outlined,
              label: 'Geofencing Zonaları',
              badge: '2',
              badgeColor: const Color(0xFF3498DB),
              onTap: () => AppLogger.melumat('PROFİL', 'Geofencing'),
            ),
            _menuDivider(),
            _menuRow(
              icon: Icons.history_rounded,
              label: 'Mövcud Tarix',
              onTap: () => AppLogger.melumat('PROFİL', 'Tarix'),
            ),
          ]),
          const SizedBox(height: 16),
          _sectionTitle('TƏNZİMLƏMƏLƏR'),
          const SizedBox(height: 8),
          _menuCard([
            _menuRow(
              icon: Icons.notifications_outlined,
              label: 'Bildiriş Tənzimləri',
              onTap: () {},
            ),
            _menuDivider(),
            _menuRow(
              icon: Icons.language_outlined,
              label: 'Dil: Azərbaycan',
              onTap: () {},
            ),
            _menuDivider(),
            _menuRow(
              icon: Icons.help_outline_rounded,
              label: 'Dəstək',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _logout(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Çıxış Et',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFCCCCCC),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[400],
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF2ECC71)).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? const Color(0xFF2ECC71),
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 66),
      height: 1,
      color: const Color(0xFFF5F7FA),
    );
  }
}
