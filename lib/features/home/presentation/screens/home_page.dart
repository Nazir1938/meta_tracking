import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/screens/tracking_screen.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/add_animal_sheet.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/profile_screen.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/tracking/services/tracking_service.dart';
import 'package:meta_tracking/features/home/presentation/screens/home_tab.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TrackingService _trackingService;
  // 0 = Ana Səhifə (HomeTab dashboard)
  // 1 = İzləmə (TrackingScreen — heyvan siyahısı + filterlər)
  // 2 = Xəritə
  // 3 = Profil
  int _currentIndex = 0;

  // ── Status bar ────────────────────────────────────────────────────────────
  static const _lightOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  static const _darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0A1628),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  // Xəritə tabı tünd AppBar istifadə edir
  SystemUiOverlayStyle get _overlay =>
      _currentIndex == 2 ? _darkOverlay : _lightOverlay;

  final List<Widget> _pages = const [
    HomeTab(),          // 0 — Ana Səhifə (dashboard)
    TrackingScreen(),   // 1 — İzləmə
    MapScreen(),        // 2 — Xəritə
    ProfileScreen(),    // 3 — Profil
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Ana Səhifə');
    SystemChrome.setSystemUIOverlayStyle(_lightOverlay);
    _trackingService = TrackingService(context);
    _initBlocs();
  }

  void _initBlocs() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    context.read<AnimalBloc>().add(WatchAnimalsEvent(auth.user.id));
    context.read<ZoneBloc>().add(LoadZonesEvent(ownerId: auth.user.id));
    context.read<HerdBloc>().add(WatchHerdsEvent(auth.user.id));
    context
        .read<NotificationBloc>()
        .add(WatchNotificationsEvent(auth.user.id));
    // Tracking servisini başlat
    _trackingService.start();
  }

  void _onTabChanged(int i) {
    setState(() => _currentIndex = i);
    SystemChrome.setSystemUIOverlayStyle(
        i == 2 ? _darkOverlay : _lightOverlay);
  }

  // FAB — Tab 0 və 1-də heyvan əlavə et
  void _onFab() {
    if (_currentIndex == 0 || _currentIndex == 1) {
      _showAddAnimalSheet();
    }
  }

  void _showAddAnimalSheet() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAnimalSheet(
        ownerId: auth.user.id,
        onSubmit: (name, type, chipId, notes, zoneId, zoneName) {
          context.read<AnimalBloc>().add(AddAnimalEvent(
                name: name,
                type: type,
                ownerId: auth.user.id,
                chipId: chipId.isNotEmpty ? chipId : null,
                notes: notes.isNotEmpty ? notes : null,
                zoneId: zoneId,
                zoneName: zoneName,
              ));
          Navigator.pop(context);
          _showSnack('"$name" uğurla əlavə edildi');
        },
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  IconData _fabIcon() =>
      _currentIndex == 2 ? Iconsax.location_add : Iconsax.add;

  bool get _showFab => _currentIndex != 3;

  @override
  void dispose() {
    _trackingService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlay,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButton: _showFab
            ? FloatingActionButton(
                onPressed: _onFab,
                backgroundColor: const Color(0xFF1D9E75),
                elevation: 4,
                shape: const CircleBorder(),
                child: Icon(_fabIcon(), color: Colors.white, size: 26),
              )
            : null,
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation Bar
// Sol: 0=Ana Səhifə, 1=İzləmə  |  FAB  |  Sağ: 2=Xəritə, 3=Profil
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
        child: Row(children: [
          // Sol
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _item(context, 0, Iconsax.home_2, 'Ana Səhifə'),
                _item(context, 1, Iconsax.location, 'İzləmə'),
              ],
            ),
          ),
          // FAB boşluğu
          const SizedBox(width: 72),
          // Sağ
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _item(context, 2, Iconsax.map, 'Xəritə'),
                _item(context, 3, Iconsax.user, 'Profil'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _item(
      BuildContext context, int idx, IconData icon, String label) {
    final active = currentIndex == idx;
    return GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1D9E75).withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 20,
                color: active
                    ? const Color(0xFF1D9E75)
                    : Colors.grey[400]),
          ),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(0xFF1D9E75)
                    : Colors.grey[400],
              )),
        ]),
      ),
    );
  }
}