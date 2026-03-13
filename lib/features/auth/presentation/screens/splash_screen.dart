import 'package:flutter/material.dart';
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
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late AnimationController _pawController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Splash Screen');

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _bgController.forward();
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    AppLogger.melumat('SPLASH', 'Auth yoxlanılır...');
    context.read<AuthBloc>().add(const CheckAuthEvent());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _pawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          AppLogger.ugur('SPLASH', 'Auth OK -> Ana səhifə');
          Navigator.of(context).pushReplacement(_fadeRoute(const HomePage()));
        } else if (state is AuthUnauthenticated) {
          AppLogger.melumat('SPLASH', 'Auth yoxdur -> Login');
          Navigator.of(
            context,
          ).pushReplacement(_fadeRoute(const LoginScreen()));
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A1628),
                    Color.lerp(
                      const Color(0xFF0A1628),
                      const Color(0xFF0D2818),
                      _bgAnimation.value,
                    )!,
                    const Color(0xFF1A3A1A),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              _buildDecorativeCircles(),
              _buildPawPrints(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4CAF50,
                                ).withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                              ).createShader(bounds),
                              child: const Text(
                                'META TRACKING',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Heyvan İzləmə Sistemi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 2,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF4CAF50).withValues(alpha: 0.7),
                          ),
                        ),
                      ),
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

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: AnimatedBuilder(
            animation: _bgAnimation,
            builder: (_, __) => Opacity(
              opacity: _bgAnimation.value * 0.15,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -60,
          child: AnimatedBuilder(
            animation: _bgAnimation,
            builder: (_, __) => Opacity(
              opacity: _bgAnimation.value * 0.1,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF81C784), width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPawPrints() {
    final positions = [
      const Offset(40, 180),
      const Offset(90, 240),
      const Offset(50, 300),
      const Offset(300, 120),
      const Offset(330, 180),
      const Offset(290, 240),
    ];
    return Stack(
      children: positions.asMap().entries.map((entry) {
        final i = entry.key;
        final pos = entry.value;
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: AnimatedBuilder(
            animation: _pawController,
            builder: (_, __) {
              final delay = i * 0.15;
              final t = ((_pawController.value - delay) % 1.0).clamp(0.0, 1.0);
              return Opacity(
                opacity: t * 0.2,
                child: const Icon(
                  Icons.pets,
                  size: 20,
                  color: Color(0xFF4CAF50),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}
