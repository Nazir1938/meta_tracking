import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/core/services/local_notification_service.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/splash_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.konfiqurasiya(aktiv: true, zamanGoster: true, yalnizDebug: false);
  AppLogger.tetbiqBasladi();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.ugur('FIREBASE', 'Firebase uğurla başladıldı');
  await LocalNotificationService().initialize();
  AppLogger.ugur('LOCAL NOTIF', 'Bildiriş servisi hazır');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MetaTrackingApp());
}

class MetaTrackingApp extends StatelessWidget {
  const MetaTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<AnimalBloc>(create: (_) => AnimalBloc()),
        BlocProvider<ZoneBloc>(create: (_) => ZoneBloc()),
        BlocProvider<NotificationBloc>(create: (_) => NotificationBloc()),
      ],
      child: MaterialApp(
        title: 'Meta Tracking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2ECC71),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}