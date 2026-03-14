import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';
import 'package:meta_tracking/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _dotsOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Opacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    AppLogger.ekranAcildi('Splash Screen');

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Logo scale: 0→1 with elastic bounce
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );
    // Glow behind logo
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );
    // Text slide up + fade
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.4, 0.72, curve: Curves.easeOutCubic),
    ));
    // Progress dots
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );
    // Decorative rings
    _ring1Opacity = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.0, end: 0.10).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    // Pulse glow
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _masterCtrl.forward().then((_) => _navigate());
  }

  void _navigate() {
    if (!mounted) return;
    AppLogger.melumat('SPLASH', 'Auth yoxlanılır...');
    context.read<AuthBloc>().add(const CheckAuthEvent());
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
            // ── Mesh gradient background ──────────────────────────────────
            _buildBackground(),

            // ── Decorative rings ──────────────────────────────────────────
            AnimatedBuilder(
              animation: _masterCtrl,
              builder: (_, __) => Stack(children: [
                // Ring 1 — large
                Positioned(
                  top: -120,
                  right: -120,
                  child: Opacity(
                    opacity: _ring1Opacity.value,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF4CAF50), width: 1.5),
                      ),
                    ),
                  ),
                ),
                // Ring 2 — bottom left
                Positioned(
                  bottom: -160,
                  left: -100,
                  child: Opacity(
                    opacity: _ring2Opacity.value,
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF66BB6A), width: 1),
                      ),
                    ),
                  ),
                ),
                // Ring 3 — small accent
                Positioned(
                  top: -40,
                  right: -40,
                  child: Opacity(
                    opacity: _ring1Opacity.value * 0.5,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF81C784), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Floating paw prints ───────────────────────────────────────
            _buildPawPrints(),

            // ── Main center content ───────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with glow + pulse
                  AnimatedBuilder(
                    animation: Listenable.merge([_masterCtrl, _pulseCtrl]),
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow pulse
                        Opacity(
                          opacity: _glowOpacity.value * 0.35,
                          child: Transform.scale(
                            scale: _pulseScale.value * 1.4,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        // Mid glow
                        Opacity(
                          opacity: _glowOpacity.value * 0.5,
                          child: Transform.scale(
                            scale: _pulseScale.value * 1.18,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                        // Logo itself
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF56D97B),
                                    Color(0xFF2E9E54),
                                    Color(0xFF1B5E20),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.55),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 60,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name + subtitle
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          // Main title with shimmer-like gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFA5D6A7),
                                Color(0xFF4CAF50),
                                Color(0xFF81C784),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(bounds),
                            child: const Text(
                              'META TRACKING',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 7,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Divider line
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 1,
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Heyvan İzləmə Sistemi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 32,
                                height: 1,
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 72),

                  // Loading dots
                  FadeTransition(
                    opacity: _dotsOpacity,
                    child: _DotsLoader(),
                  ),
                ],
              ),
            ),

            // ── Version tag ───────────────────────────────────────────────
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _dotsOpacity,
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.2, -0.3),
          radius: 1.4,
          colors: [
            Color(0xFF0D2818),
            Color(0xFF071410),
            Color(0xFF050D18),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildPawPrints() {
    final items = [
      (32.0, 190.0, 0.0),
      (78.0, 248.0, 0.1),
      (44.0, 306.0, 0.2),
      (310.0, 130.0, 0.15),
      (340.0, 190.0, 0.05),
      (295.0, 252.0, 0.25),
    ];
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Stack(
        children: items.map((item) {
          final (x, y, delay) = item;
          final t = ((_pulseCtrl.value - delay) % 1.0).clamp(0.0, 1.0);
          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: t * 0.14,
              child: const Icon(Icons.pets, size: 18, color: Color(0xFF4CAF50)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );
}

// Animated three-dot loader
class _DotsLoader extends StatefulWidget {
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 180)),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
    // Stagger start
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withValues(alpha: _anims[i].value),
            ),
          ),
        );
      }),
    );
  }
}
