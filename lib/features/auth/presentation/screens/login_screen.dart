import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/register_screen.dart';
import 'package:meta_tracking/features/home/presentation/screens/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _passwordVisible = false;

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _cardY;
  late Animation<double> _cardOpacity;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    AppLogger.ekranAcildi('Login Screen');
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _bgAnim   = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _cardY    = Tween<double>(begin: 56.0, end: 0.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn));
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _bgCtrl.dispose(); _cardCtrl.dispose(); _shakeCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    AppLogger.melumat('LOGIN', 'Login formu göndərilir: ${_emailCtrl.text.trim()}');
    context.read<AuthBloc>().add(LoginEvent(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          AppLogger.ugur('LOGIN', 'Uğurlu giriş: ${state.user.email}');
          Navigator.of(ctx).pushAndRemoveUntil(_slideRoute(const HomePage()), (_) => false);
        } else if (state is AuthError) {
          _shakeCtrl.forward(from: 0);
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
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF050D18), const Color(0xFF071810), _bgAnim.value)!,
                  Color.lerp(const Color(0xFF0A1C10), const Color(0xFF0D2318), _bgAnim.value)!,
                  Color.lerp(const Color(0xFF071215), const Color(0xFF050D18), _bgAnim.value)!,
                ],
              ),
            ),
            child: child,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height
                      - MediaQuery.of(context).padding.top
                      - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _cardCtrl,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _cardY.value),
                          child: Opacity(opacity: _cardOpacity.value, child: child),
                        ),
                        child: _buildCard(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
      child: Column(children: [
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF56D97B), Color(0xFF1B5E20)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
                blurRadius: 28, spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Iconsax.pet5, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFA5D6A7), Color(0xFF4CAF50)],
          ).createShader(b),
          child: const Text(
            'XOŞ GƏLDİNİZ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hesabınıza daxil olun',
          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.5),
        ),
      ]),
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final shake = _shakeCtrl.isAnimating
            ? 5.0 * (0.5 - (_shakeAnim.value - 0.5).abs()) * 2 : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 48, offset: const Offset(0, 20)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _field(ctrl: _emailCtrl, label: 'Email ünvanı', icon: Iconsax.sms,
                type: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email daxil edin';
                  if (!v.contains('@')) return 'Düzgün email daxil edin';
                  return null;
                }),
              const SizedBox(height: 14),
              _field(ctrl: _passwordCtrl, label: 'Şifrə', icon: Iconsax.lock,
                obscure: !_passwordVisible,
                suffix: GestureDetector(
                  onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _passwordVisible ? Iconsax.eye_slash : Iconsax.eye,
                      color: Colors.white38, size: 19,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Şifrə daxil edin';
                  if (v.length < 6) return 'Ən az 6 xanə olmalıdır';
                  return null;
                }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Şifrəni unutmusunuz?',
                  style: TextStyle(fontSize: 12, color: const Color(0xFF4CAF50).withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (_, state) => _loginBtn(state is AuthLoading),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('və ya', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
                ),
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08))),
              ]),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).push(_slideRoute(const RegisterScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.user_add, color: Color(0xFF4CAF50), size: 18),
                      SizedBox(width: 8),
                      Text('Yeni hesab yarat',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
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
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: Colors.white38, size: 19),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF9A9A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }

  Widget _loginBtn(bool loading) {
    return GestureDetector(
      onTap: loading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: loading ? null : const LinearGradient(
            colors: [Color(0xFF56D97B), Color(0xFF2E7D32)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          color: loading ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading ? [] : [
            BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 7)),
          ],
        ),
        child: Center(
          child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white60)))
            : const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Iconsax.login, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('DAXİL OL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 2.5)),
              ]),
        ),
      ),
    );
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 320),
  );
}