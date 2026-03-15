import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/widgets/profile_widgets.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/screens/create_herd_sheet.dart';
import 'package:meta_tracking/features/herds/presentation/screens/herds_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, s) => s is AuthProfileUpdated,
        listener: (ctx, _) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: const Text('Profil yeniləndi'),
          backgroundColor: const Color(0xFF1D9E75),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        )),
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, authState) {
              final user = authState is AuthAuthenticated
                  ? authState.user
                  : null;
              final groupLabel = user?.herdGroupLabel ?? 'Sürü';

              return RefreshIndicator(
                color: const Color(0xFF1D9E75),
                displacement: MediaQuery.of(context).padding.top + 8,
                onRefresh: () async {
                  if (user != null) {
                    context
                        .read<HerdBloc>()
                        .add(WatchHerdsEvent(user.id));
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: ProfileHeader(user: user)),
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const ProfileStatsRow(),
                          const SizedBox(height: 20),

                          // ── Sürü bölməsi ──────────────────────────
                          _lbl(groupLabel),
                          const SizedBox(height: 8),
                          ProfileMenuItem(
                            icon: Iconsax.people,
                            label: '${groupLabel}lərim',
                            subtitle: 'Heyvan qruplarını idarə et',
                            color: const Color(0xFF1D9E75),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const HerdsScreen()),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ProfileHerdListSection(
                              groupLabel: groupLabel),
                          const SizedBox(height: 20),

                          // ── Hesab bölməsi ──────────────────────────
                          _lbl('Hesab'),
                          const SizedBox(height: 8),
                          ProfileMenuItem(
                            icon: Iconsax.user_edit,
                            label: 'Profili redaktə et',
                            subtitle: 'Ad, email məlumatları',
                            color: const Color(0xFF185FA5),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<AuthBloc>(),
                                child: EditProfileSheet(user: user),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ProfileMenuItem(
                            icon: Iconsax.notification,
                            label: 'Bildiriş tənzimləmələri',
                            subtitle: 'Alert, səs, vibrasiya',
                            color: const Color(0xFFBA7517),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<NotificationBloc>(),
                                child:
                                    const NotificationSettingsSheet(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Tətbiq bölməsi ─────────────────────────
                          _lbl('Tətbiq'),
                          const SizedBox(height: 8),
                          ProfileMenuItem(
                            icon: Iconsax.shield_tick,
                            label: 'Məxfilik siyasəti',
                            color: Colors.grey,
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          ProfileMenuItem(
                            icon: Iconsax.info_circle,
                            label: 'Haqqında',
                            subtitle: 'v1.0.0',
                            color: Colors.grey,
                            onTap: () => _showAbout(context),
                          ),
                          const SizedBox(height: 24),
                          const ProfileLogoutButton(),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // ── FAB — Yeni Sürü yarat ──────────────────────────────────
          floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, auth) {
              final label = auth is AuthAuthenticated
                  ? auth.user.herdGroupLabel
                  : 'Sürü';
              return FloatingActionButton.extended(
                heroTag: 'fab_profile_herd',
                onPressed: () {
                  if (auth is! AuthAuthenticated) return;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<HerdBloc>(),
                      child: BlocProvider.value(
                        value: context.read<AnimalBloc>(),
                        child: CreateHerdSheet(ownerId: auth.user.id),
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF1D9E75),
                elevation: 4,
                icon:
                    const Icon(Iconsax.add, color: Colors.white, size: 20),
                label: Text('Yeni $label',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  Widget _lbl(String text) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6),
      );

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
                child: Text('🐄', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text('Meta Tracking',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Versiya 1.0.0',
              style: TextStyle(color: Colors.grey[500])),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bağla',
                style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
  }
}