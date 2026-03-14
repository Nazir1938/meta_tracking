import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';

class TrackingAppBar extends StatelessWidget {
  final int animalCount;
  final int alertCount;
  final bool isSelectMode;
  final VoidCallback onToggleSelectMode;
  final VoidCallback onFilterTap;

  const TrackingAppBar({
    super.key,
    required this.animalCount,
    required this.alertCount,
    required this.isSelectMode,
    required this.onToggleSelectMode,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        return Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            bottom: 14,
          ),
          child: Row(children: [
            if (user != null) _buildAvatar(user),
            if (user != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user != null)
                    Text(
                      'Salam, ${user.name.split(' ').first}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  const Text('Heyvanlarım',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.5)),
                  Text(
                    '$animalCount heyvan'
                    '${alertCount > 0 ? ' • $alertCount alert' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            if (alertCount > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFF4444).withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Iconsax.warning_2,
                      color: Color(0xFFFF4444), size: 13),
                  const SizedBox(width: 4),
                  Text('$alertCount',
                      style: const TextStyle(
                          color: Color(0xFFFF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onToggleSelectMode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelectMode
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelectMode
                        ? const Color(0xFF2ECC71)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  isSelectMode ? 'Bitir' : 'Seç',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelectMode
                        ? const Color(0xFF2ECC71)
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildAvatar(UserEntity user) {
    final initials = user.name.isNotEmpty
        ? user.name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF56D97B), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
