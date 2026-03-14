import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/screens/tracking_screen.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/add_animal_sheet.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/profile_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TrackingScreen(),
    MapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Ana Səhifə');
    _initBlocs();
  }

  void _initBlocs() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final ownerId = authState.user.id;

    AppLogger.melumat('HOME', 'AnimalBloc yaradıldı, ownerId: $ownerId');
    context.read<AnimalBloc>().add(WatchAnimalsEvent(ownerId));

    AppLogger.melumat('HOME', 'ZoneBloc yaradıldı');
    context.read<ZoneBloc>().add(const LoadZonesEvent ());

    AppLogger.melumat('HOME', 'NotificationBloc yaradıldı');
    context.read<NotificationBloc>().add(WatchNotificationsEvent(ownerId));
  }

  void _showTopSnack(String msg, {Color color = const Color(0xFF2ECC71)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      // Yuxarıda göstər — böyük margin alt tərəfdən
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onFabPressed() {
    switch (_currentIndex) {
      case 0:
        _showAddAnimalSheet();
        break;
      case 2:
        _markAllNotificationsRead();
        break;
      default:
        break;
    }
  }

  void _showAddAnimalSheet() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAnimalSheet(
        ownerId: authState.user.id,
        onSubmit: (name, type, chipId, notes, zoneId, zoneName) {
          context.read<AnimalBloc>().add(AddAnimalEvent(
                name: name,
                type: type,
                ownerId: authState.user.id,
                chipId: chipId.isNotEmpty ? chipId : null,
                notes: notes.isNotEmpty ? notes : null,
                zoneId: zoneId,
                zoneName: zoneName,
              ));
          Navigator.pop(context);
          _showTopSnack('"$name" uğurla əlavə edildi');
        },
      ),
    );
  }

  void _markAllNotificationsRead() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<NotificationBloc>().add(MarkAllAsReadEvent(authState.user.id));
    _showTopSnack('Hamısı oxundu işarələndi');
  }

  IconData _fabIcon() {
    switch (_currentIndex) {
      case 0:
        return Iconsax.add;
      case 1:
        return Iconsax.location_add;
      case 2:
        return Iconsax.tick_circle;
      case 3:
        return Iconsax.setting_2;
      default:
        return Iconsax.add;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: const Color(0xFF2ECC71),
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(_fabIcon(), color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        final unread =
            notifState is NotificationLoaded ? notifState.unreadCount : 0;

        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 12,
          color: Colors.white,
          child: SizedBox(
            height: 60,
            child: Row(children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(0, Iconsax.pet, 'İzləmə'),
                    _navItem(1, Iconsax.map, 'Xəritə'),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItemWithBadge(
                        2, Iconsax.notification, 'Bildirişlər', unread),
                    _navItem(3, Iconsax.user, 'Profil'),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 20,
                color: isActive ? const Color(0xFF2ECC71) : Colors.grey[400]),
          ),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF2ECC71) : Colors.grey[400],
              )),
        ]),
      ),
    );
  }

  Widget _navItemWithBadge(int index, IconData icon, String label, int badge) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isActive ? const Color(0xFF2ECC71) : Colors.grey[400]),
            ),
            if (badge > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF4444), shape: BoxShape.circle),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF2ECC71) : Colors.grey[400],
              )),
        ]),
      ),
    );
  }
}
