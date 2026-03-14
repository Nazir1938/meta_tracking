import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF5350), size: 24),
            ),
            const SizedBox(height: 16),
            const Text('Çıxış Et',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Hesabdan çıxmaq istədiyinizə əminsiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.4)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Text('Ləğv et',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AuthBloc>().add(const LogoutEvent());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFC62828)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                      child: Text('Çıx',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.logout,
                  color: Color(0xFFEF5350), size: 18),
            ),
            const SizedBox(width: 14),
            const Text('Çıxış Et',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF5350))),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[300], size: 20),
          ]),
        ),
      ),
    );
  }
}
