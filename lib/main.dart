// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/presentation/screens/tracking_screen.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/profile_screen.dart';
import 'package:meta_tracking/features/auth/presentation/screens/splash_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.konfiqurasiya(aktiv: true, zamanGoster: true, yalnizDebug: false);
  AppLogger.tetbiqBasladi();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.melumat('TETBIQ', 'MyApp widget qurulur');
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(
          create: (_) {
            AppLogger.melumat('BLOC', 'ZoneBloc yaradildi');
            return ZoneBloc()..add(const FetchZonesEvent());
          },
        ),
      ],
      child: MaterialApp(
        title: 'Meta Tracking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ─── Ana Sehife ───────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TrackingScreen(),
    MapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  final List<String> _labels = ['Heyvanlar', 'Xerite', 'Revanlar', 'Profil'];

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Ana Sehife (HomePage)');
  }

  @override
  void dispose() {
    AppLogger.ekranBaglandi('Ana Sehife (HomePage)');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.pets_outlined, Icons.pets),
                _navItem(1, Icons.map_outlined, Icons.map),
                _navItem(2, Icons.notifications_outlined, Icons.notifications),
                _navItem(3, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        AppLogger.melumat(
          'NAVIGASIYA',
          'Tab: ${_labels[_currentIndex]} -> ${_labels[index]}',
        );
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              _labels[index],
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF4CAF50)
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
