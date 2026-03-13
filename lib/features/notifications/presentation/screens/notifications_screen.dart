import 'package:flutter/material.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

class NotificationAlert {
  final String id;
  final String animalName;
  final String animalEmoji;
  final String zoneName;
  final String message;
  final DateTime timestamp;
  final String type;
  bool isRead;

  NotificationAlert({
    required this.id,
    required this.animalName,
    required this.animalEmoji,
    required this.zoneName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationAlert> _notifications = [
    NotificationAlert(
      id: '1',
      animalName: 'Qoç-2',
      animalEmoji: '🐑',
      zoneName: 'Otlaq-1',
      message:
          'Qoç-2, Otlaq-1 zonasının hüdudunu aşdı! İndi meşəyə daxil olub.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      type: 'alert',
    ),
    NotificationAlert(
      id: '2',
      animalName: 'Alabaş-1',
      animalEmoji: '🐄',
      zoneName: 'Otlaq-1',
      message: 'Alabaş-1 Otlaq-1 zonasına daxil oldu.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      type: 'enter',
      isRead: true,
    ),
    NotificationAlert(
      id: '3',
      animalName: 'Küheylan',
      animalEmoji: '🐎',
      zoneName: 'Otlaq-2',
      message: 'Küheylan Otlaq-2 zonasının xaricinə çıxdı.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: 'exit',
      isRead: true,
    ),
    NotificationAlert(
      id: '4',
      animalName: 'Keçim-1',
      animalEmoji: '🐐',
      zoneName: '',
      message: 'Keçim-1 cihazının batareyası azalır: 12%',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'battery',
      isRead: true,
    ),
    NotificationAlert(
      id: '5',
      animalName: 'Alabaş-1',
      animalEmoji: '🐄',
      zoneName: 'Otlaq-1',
      message: 'Alabaş-1 Otlaq-1 zonasının xaricinə çıxdı.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'exit',
      isRead: true,
    ),
  ];

  String _filter = 'all';

  List<NotificationAlert> get _filtered => _filter == 'all'
      ? _notifications
      : _notifications.where((n) => n.type == _filter).toList();

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Notifications Screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(child: _filtered.isEmpty ? _buildEmpty() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xəbərdarlıqlar',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _unreadCount > 0
                      ? '$_unreadCount oxunmamış xəbərdarlıq var'
                      : 'Hamısı oxunub',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  for (var n in _notifications) n.isRead = true;
                });
                AppLogger.bildirisEmeliyyati('Hamısı oxundu işarələndi');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Hamısı oxundu',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          _tab('Hamısı', 'all', null),
          const SizedBox(width: 8),
          _tab('Alert', 'alert', const Color(0xFFFF4444)),
          const SizedBox(width: 8),
          _tab('Daxil oldu', 'enter', const Color(0xFF2ECC71)),
          const SizedBox(width: 8),
          _tab('Çıxdı', 'exit', const Color(0xFFFF9800)),
          const SizedBox(width: 8),
          _tab('Batareya', 'battery', const Color(0xFF9B59B6)),
        ],
      ),
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
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
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

  Widget _buildList() {
    final today = <NotificationAlert>[];
    final earlier = <NotificationAlert>[];
    final now = DateTime.now();
    for (final n in _filtered) {
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
          ...today.map((n) => _notifCard(n)),
        ],
        if (earlier.isNotEmpty) ...[
          _sectionHeader('Daha Əvvəl'),
          ...earlier.map((n) => _notifCard(n)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _notifCard(NotificationAlert n) {
    final typeData = _typeData(n.type);
    final color = typeData['color'] as Color;
    final icon = typeData['icon'] as IconData;
    final typeLabel = typeData['label'] as String;

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        AppLogger.bildirisEmeliyyati('Xəbərdarlıq silindi: ${n.id}');
        setState(() => _notifications.remove(n));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xəbərdarlıq silindi'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () => setState(() => _notifications.add(n)),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      child: GestureDetector(
        onTap: () {
          if (!n.isRead) {
            AppLogger.bildirisEmeliyyati('Oxundu: ${n.id}');
            setState(() => n.isRead = true);
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
              color: n.isRead
                  ? Colors.transparent
                  : color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        n.animalEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(icon, size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          n.animalName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (n.zoneName.isNotEmpty) ...[
                          Icon(
                            Icons.location_on,
                            size: 11,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            n.zoneName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(n.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => AppLogger.bildirisEmeliyyati(
                            'Xəritədə göstər: ${n.id}',
                          ),
                          child: Text(
                            'Xəritədə bax',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Xəbərdarlıq yoxdur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _typeData(String type) {
    switch (type) {
      case 'enter':
        return {
          'color': const Color(0xFF2ECC71),
          'icon': Icons.login_rounded,
          'label': 'DAXİL OLDU',
        };
      case 'exit':
        return {
          'color': const Color(0xFFFF9800),
          'icon': Icons.logout_rounded,
          'label': 'ÇIXDI',
        };
      case 'alert':
        return {
          'color': const Color(0xFFFF4444),
          'icon': Icons.warning_rounded,
          'label': 'ALERT',
        };
      case 'battery':
        return {
          'color': const Color(0xFF9B59B6),
          'icon': Icons.battery_alert,
          'label': 'BATAREYA',
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.info_outline,
          'label': 'MƏLUMAT',
        };
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
