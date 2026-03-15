import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (ctx, state) {
            final notifications = state is NotificationLoaded
                ? state.notifications
                : <NotificationEntity>[];
            final unread = state is NotificationLoaded
                ? state.unreadCount
                : 0;

            return CustomScrollView(
              slivers: [
                // AppBar
                SliverToBoxAdapter(
                  child: _AppBar(
                    unread: unread,
                    onMarkAll: () => context
                        .read<NotificationBloc>()
                        .add(const MarkAllAsReadEvent()),
                  ),
                ),

                if (notifications.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final n = notifications[i];
                          return _NotificationTile(
                            notification: n,
                            onTap: () => context
                                .read<NotificationBloc>()
                                .add(MarkNotificationReadEvent(n.id)),
                          );
                        },
                        childCount: notifications.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final int unread;
  final VoidCallback onMarkAll;
  const _AppBar({required this.unread, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding:
          EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left_rounded,
              color: Color(0xFF1D9E75), size: 26),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Bildirişlər',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
        ),
        if (unread > 0)
          GestureDetector(
            onTap: onMarkAll,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Hamısını oxu',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  const _NotificationTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final color = _typeColor(notification.type);
    final icon = _typeIcon(notification.type);
    final timeLabel = _formatTime(notification.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? color.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? color.withValues(alpha: 0.25)
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(notification.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: const Color(0xFF1A1A2E))),
                ),
                Text(timeLabel,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[400])),
              ]),
              const SizedBox(height: 3),
              Text(notification.body,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.zoneAlert:   return const Color(0xFFE24B4A);
      case NotificationType.separation:  return const Color(0xFFBA7517);
      case NotificationType.system:      return const Color(0xFF185FA5);
    }
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.zoneAlert:   return Iconsax.location;
      case NotificationType.separation:  return Iconsax.warning_2;
      case NotificationType.system:      return Iconsax.notification;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq';
    if (diff.inHours < 24) return '${diff.inHours} saat';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Iconsax.notification,
                size: 44, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Bildiriş yoxdur',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Yeni alertlar burada görünəcək',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[400])),
        ]),
      );
}