import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/home/presentation/screens/home_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool _passVisible    = false;
  bool _confirmVisible = false;

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _cardY;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    AppLogger.ekranAcildi('Register Screen');
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _bgAnim   = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _cardY    = Tween<double>(begin: 48.0, end: 0.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _bgCtrl.dispose(); _cardCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    AppLogger.melumat('REGISTER', 'Qeydiyyat: ${_emailCtrl.text.trim()}');
    context.read<AuthBloc>().add(RegisterEvent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(ctx).pushAndRemoveUntil(_fadeRoute(const HomePage()), (_) => false);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Iconsax.warning_2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(state.message)),
            ]),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050D18),
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _bgAnim,
          builder: (ctx, child) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [
                  Color.lerp(const Color(0xFF050D18), const Color(0xFF071015), _bgAnim.value)!,
                  Color.lerp(const Color(0xFF071810), const Color(0xFF0A2018), _bgAnim.value)!,
                  Color.lerp(const Color(0xFF050D18), const Color(0xFF071218), _bgAnim.value)!,
                ],
              ),
            ),
            child: child,
          ),
          child: SafeArea(
            child: Column(children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Text('YENİ HESAB', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3,
                  )),
                  const Spacer(),
                  const SizedBox(width: 40),
                ]),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: AnimatedBuilder(
                    animation: _cardCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _cardY.value),
                      child: Opacity(opacity: _cardOpacity.value, child: child),
                    ),
                    child: Column(children: [
                      // Icon
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF56D97B), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 22, spreadRadius: 3),
                          ],
                        ),
                        child: const Icon(Iconsax.user_add, size: 34, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text('Hesab yaradın', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9), fontSize: 22, fontWeight: FontWeight.w800,
                      )),
                      const SizedBox(height: 4),
                      Text('Məlumatlarınızı daxil edin', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38), fontSize: 13,
                      )),
                      const SizedBox(height: 24),
                      // Form card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 16)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            _field(ctrl: _nameCtrl, label: 'Ad Soyad', icon: Iconsax.user,
                              validator: (v) => (v == null || v.isEmpty) ? 'Ad daxil edin' : null),
                            const SizedBox(height: 12),
                            _field(ctrl: _emailCtrl, label: 'Email ünvanı', icon: Iconsax.sms,
                              type: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email daxil edin';
                                if (!v.contains('@')) return 'Düzgün email daxil edin';
                                return null;
                              }),
                            const SizedBox(height: 12),
                            _field(ctrl: _passCtrl, label: 'Şifrə', icon: Iconsax.lock,
                              obscure: !_passVisible,
                              suffix: GestureDetector(
                                onTap: () => setState(() => _passVisible = !_passVisible),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(_passVisible ? Iconsax.eye_slash : Iconsax.eye, color: Colors.white38, size: 18),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Şifrə daxil edin';
                                if (v.length < 6) return 'Ən az 6 xanə olmalıdır';
                                return null;
                              }),
                            const SizedBox(height: 12),
                            _field(ctrl: _confirmCtrl, label: 'Şifrəni təkrar daxil edin', icon: Iconsax.lock,
                              obscure: !_confirmVisible,
                              suffix: GestureDetector(
                                onTap: () => setState(() => _confirmVisible = !_confirmVisible),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(_confirmVisible ? Iconsax.eye_slash : Iconsax.eye, color: Colors.white38, size: 18),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passCtrl.text) return 'Şifrələr uyğun deyil';
                                return null;
                              }),
                            const SizedBox(height: 22),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (_, state) => _registerBtn(state is AuthLoading),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Artıq hesabınız var? ',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Daxil Ol',
                            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: Colors.white38, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.11)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF9A9A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }

  Widget _registerBtn(bool loading) {
    return GestureDetector(
      onTap: loading ? null : _register,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: loading ? null : const LinearGradient(
            colors: [Color(0xFF56D97B), Color(0xFF2E7D32)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          color: loading ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: loading ? [] : [
            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
            ? const SizedBox(width: 21, height: 21,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white60)))
            : const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Iconsax.user_add, color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text('QEYDİYYATDAN KEÇ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2)),
              ]),
        ),
      ),
    );
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );
}