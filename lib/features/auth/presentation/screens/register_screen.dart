// lib/features/auth/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _bgWave;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Register Screen');

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bgWave = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);
    _cardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeIn),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    AppLogger.melumat('REGISTER', 'Qeydiyyat formu gonderidir');
    context.read<AuthBloc>().add(RegisterEvent(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          AppLogger.ugur('REGISTER', 'Qeydiyyat OK -> Ana sehife');
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomePage(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (_) => false,
          );
        } else if (state is AuthError) {
          AppLogger.xeberdarliq('REGISTER', 'Xeta: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgWave,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.lerp(
                        const Color(0xFF0A1628), const Color(0xFF0D1F2D),
                        _bgWave.value)!,
                    Color.lerp(
                        const Color(0xFF0D2818), const Color(0xFF122A18),
                        _bgWave.value)!,
                    Color.lerp(
                        const Color(0xFF1A3A1A), const Color(0xFF0F2510),
                        _bgWave.value)!,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'YENİ HESAB',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedBuilder(
                      animation: _cardController,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _cardSlide.value),
                        child: Opacity(
                            opacity: _cardOpacity.value, child: child),
                      ),
                      child: Column(
                        children: [
                          // Ust ikon
                          Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF66BB6A),
                                  Color(0xFF1B5E20)
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_add_outlined,
                                size: 36, color: Colors.white),
                          ),

                          // Kart
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildField(
                                    controller: _nameController,
                                    label: 'Ad Soyad',
                                    icon: Icons.person_outline,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Ad daxil edin'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Email daxil edin';
                                      if (!v.contains('@'))
                                        return 'Duzgun email daxil edin';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _passwordController,
                                    label: 'Sifre',
                                    icon: Icons.lock_outline,
                                    obscureText: !_passwordVisible,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() =>
                                          _passwordVisible = !_passwordVisible),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Sifre daxil edin';
                                      if (v.length < 6)
                                        return 'En az 6 xaner olmalidir';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _confirmController,
                                    label: 'Sifre tekrar',
                                    icon: Icons.lock_outline,
                                    obscureText: !_confirmVisible,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _confirmVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() =>
                                          _confirmVisible = !_confirmVisible),
                                    ),
                                    validator: (v) {
                                      if (v != _passwordController.text)
                                        return 'Sifreler uygun deyil';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (_, state) {
                                      final isLoading = state is AuthLoading;
                                      return _buildRegisterButton(isLoading);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hesabiniz var? ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Daxil Ol',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        errorStyle: const TextStyle(fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _buildRegisterButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _register,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                ),
          color: isLoading ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white54),
                  ),
                )
              : const Text(
                  'QEYDİYYATDAN KEÇ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}