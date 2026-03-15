import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/notifications/presentation/screens/notifications_screen.dart';

class TrackingAppBar extends StatelessWidget {
  final int animalCount;
  final int alertCount;

  const TrackingAppBar({
    super.key,
    required this.animalCount,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        final unread =
            notifState is NotificationLoaded ? notifState.unreadCount : 0;

        // İstifadəçi məlumatlarını AuthBloc-dan al
        final authState = context.read<AuthBloc>().state;
        final String userName = authState is AuthAuthenticated
            ? (authState.user.name)
            : 'İstifadəçi';
        final String? photoUrl =
            authState is AuthAuthenticated ? authState.user.avatarUrl : null;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            top: top + 12,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Sol: istifadəçi foto + ad ──────────────────────────────────
              _buildAvatar(photoUrl, userName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Alert badge ────────────────────────────────────────────────
              if (alertCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Iconsax.warning_2,
                        size: 11, color: Color(0xFFFF4444)),
                    const SizedBox(width: 3),
                    Text(
                      '$alertCount',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
              ],

              // ── Bildiriş ikonu ─────────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.notification,
                        size: 20,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl.isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsWidget(initials),
            )
          : _initialsWidget(initials),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2ECC71),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Sabahınız xeyir 👋';
    if (hour < 18) return 'Günortanız xeyir 👋';
    return 'Axşamınız xeyir 👋';
  }
}
