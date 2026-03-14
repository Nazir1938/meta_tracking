import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';
import 'package:meta_tracking/features/home/presentation/screens/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _dotsOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    AppLogger.ekranAcildi('Splash Screen');

    _masterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.0, 0.45, curve: Curves.elasticOut)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)));
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.4, 0.72, curve: Curves.easeOutCubic)));
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.65, 0.85, curve: Curves.easeIn)));
    _ringOpacity = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(parent: _masterCtrl, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)));
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _masterCtrl.forward().then((_) {
      if (!mounted) return;
      AppLogger.melumat('SPLASH', 'Auth yoxlanılır...');
      context.read<AuthBloc>().add(const CheckAuthEvent());
    });
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          AppLogger.ugur('SPLASH', 'Auth OK → Ana səhifə');
          Navigator.of(ctx).pushReplacement(_fadeRoute(const HomePage()));
        } else if (state is AuthUnauthenticated) {
          AppLogger.melumat('SPLASH', 'Auth yoxdur → Login');
          Navigator.of(ctx).pushReplacement(_fadeRoute(const LoginScreen()));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050D18),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.2, -0.3),
                  radius: 1.4,
                  colors: [Color(0xFF0D2818), Color(0xFF071410), Color(0xFF050D18)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Rings
            AnimatedBuilder(
              animation: _masterCtrl,
              builder: (_, __) => Stack(children: [
                Positioned(
                  top: -120, right: -120,
                  child: Opacity(
                    opacity: _ringOpacity.value,
                    child: Container(
                      width: 380, height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -160, left: -100,
                  child: Opacity(
                    opacity: _ringOpacity.value * 0.6,
                    child: Container(
                      width: 480, height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF66BB6A), width: 1),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: Listenable.merge([_masterCtrl, _pulseCtrl]),
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: _glowOpacity.value * 0.35,
                          child: Transform.scale(
                            scale: _pulseScale.value * 1.4,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _glowOpacity.value * 0.5,
                          child: Transform.scale(
                            scale: _pulseScale.value * 1.18,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 112, height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF56D97B), Color(0xFF2E9E54), Color(0xFF1B5E20)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.55),
                                    blurRadius: 36, spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Iconsax.pet5, size: 54, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFA5D6A7), Color(0xFF4CAF50), Color(0xFF81C784)],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'META TRACKING',
                            style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 32, height: 1,
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                          const SizedBox(width: 12),
                          Text(
                            'Heyvan İzləmə Sistemi',
                            style: TextStyle(
                              fontSize: 13, color: Colors.white.withValues(alpha: 0.55),
                              letterSpacing: 2.5, fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(width: 32, height: 1,
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 72),
                  FadeTransition(opacity: _dotsOpacity, child: const _DotsLoader()),
                ],
              ),
            ),
            // Version
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: FadeTransition(
                opacity: _dotsOpacity,
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.2), letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 500),
  );
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    ));
    _anims = _ctrls.map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: _anims[i].value),
          ),
        ),
      )),
    );
  }
}