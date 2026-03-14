import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/notifications/domain/entities/notification_entity.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Notifications Screen');
    // Firebase-dən bildirişləri yüklə
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<NotificationBloc>().add(
        WatchNotificationsEvent(authState.user.id),
      );
    }
  }

  List<NotificationEntity> _applyFilter(List<NotificationEntity> all) {
    if (_filter == 'all') return all;
    return all.where((n) => n.type.name == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final notifications = state is NotificationLoaded
            ? state.notifications
            : <NotificationEntity>[];
        final filtered = _applyFilter(notifications);
        final unread = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: Column(children: [
              _buildHeader(context, notifications, unread),
              _buildFilterTabs(),
              Expanded(
                child: state is NotificationLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                    : filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(context, filtered),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, List<NotificationEntity> all, int unread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Xəbərdarlıqlar',
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
            Text(
              unread > 0 ? '$unread oxunmamış xəbərdarlıq' : 'Hamısı oxunub',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ]),
        ),
        if (unread > 0)
          GestureDetector(
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<NotificationBloc>().add(
                  MarkAllAsReadEvent(authState.user.id));
                AppLogger.bildirisEmeliyyati('Hamısı oxundu işarələndi');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Hamısı oxundu',
                style: TextStyle(
                  color: Color(0xFF2ECC71), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }

  // ── Filter tabs ───────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(children: [
        _tab('Hamısı', 'all', null),
        const SizedBox(width: 8),
        _tab('Alert', 'alert', const Color(0xFFFF4444)),
        const SizedBox(width: 8),
        _tab('Daxil oldu', 'enter', const Color(0xFF2ECC71)),
        const SizedBox(width: 8),
        _tab('Çıxdı', 'exit', const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        _tab('Batareya', 'battery', const Color(0xFF9B59B6)),
      ]),
    );
  }

  Widget _tab(String label, String value, Color? color) {
    final isActive = _filter == value;
    final activeColor = color ?? const Color(0xFF2ECC71);
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : Colors.grey[600],
        )),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<NotificationEntity> notifications) {
    final today = <NotificationEntity>[];
    final earlier = <NotificationEntity>[];
    final now = DateTime.now();
    for (final n in notifications) {
      if (now.difference(n.timestamp).inHours < 24) {
        today.add(n);
      } else {
        earlier.add(n);
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (today.isNotEmpty) ...[
          _sectionHeader('Bugün'),
          ...today.map((n) => _notifCard(context, n)),
        ],
        if (earlier.isNotEmpty) ...[
          _sectionHeader('Daha Əvvəl'),
          ...earlier.map((n) => _notifCard(context, n)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(title, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: Colors.grey[400], letterSpacing: 0.5,
      )),
    );
  }

  Widget _notifCard(BuildContext context, NotificationEntity n) {
    final color = _typeColor(n.type);
    final icon = _typeIcon(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationBloc>().add(DeleteNotificationEvent(n.id));
        AppLogger.bildirisEmeliyyati('Bildiriş silindi: ${n.id}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Xəbərdarlıq silindi'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 22),
      ),
      child: GestureDetector(
        onTap: () {
          if (!n.isRead) {
            context.read<NotificationBloc>().add(MarkAsReadEvent(n.id));
            AppLogger.bildirisEmeliyyati('Oxundu: ${n.id}');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.isRead ? Colors.transparent : color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Stack(children: [
                Center(
                  child: Text(
                    n.animalEmoji ?? '🐾',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(icon, size: 8, color: Colors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(n.animalName ?? n.title,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(n.typeLabel, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 6),
                  if (!n.isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4444), shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(n.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  if (n.zoneName != null && n.zoneName!.isNotEmpty) ...[
                    Icon(Iconsax.location, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(n.zoneName!, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    const SizedBox(width: 10),
                  ],
                  Icon(Iconsax.clock, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(_formatTime(n.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const Spacer(),
                  Text('Xəritədə bax',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Iconsax.notification, size: 48, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        Text('Xəbərdarlıq yoxdur',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text('Heyvanlarınızın hərəkəti burada görünəcək',
          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.enter:   return const Color(0xFF2ECC71);
      case NotificationType.exit:    return const Color(0xFFFF9800);
      case NotificationType.alert:   return const Color(0xFFFF4444);
      case NotificationType.battery: return const Color(0xFF9B59B6);
      case NotificationType.info:    return Colors.grey;
    }
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.enter:   return Iconsax.login;
      case NotificationType.exit:    return Iconsax.logout;
      case NotificationType.alert:   return Iconsax.warning_2;
      case NotificationType.battery: return Iconsax.battery_disable;
      case NotificationType.info:    return Iconsax.info_circle;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'İndi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq əvvəl';
    if (diff.inHours < 24) return '${diff.inHours} saat əvvəl';
    return '${diff.inDays} gün əvvəl';
  }
}