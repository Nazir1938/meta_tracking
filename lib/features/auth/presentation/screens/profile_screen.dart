import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';
import 'package:meta_tracking/features/auth/presentation/widgets/profile_hero_header.dart';
import 'package:meta_tracking/features/auth/presentation/widgets/profile_logout_button.dart';
import 'package:meta_tracking/features/auth/presentation/widgets/profile_menu_section.dart';
import 'package:meta_tracking/features/auth/presentation/widgets/profile_stats_row.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Profile Screen');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(ctx).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (_) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (ctx, authState) {
          if (authState is! AuthAuthenticated) {
            return const Scaffold(
              backgroundColor: Color(0xFFF5F7FA),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
              ),
            );
          }
          return BlocBuilder<AnimalBloc, AnimalState>(
            builder: (ctx, animalState) {
              final animals = animalState is AnimalLoaded
                  ? animalState.animals
                  : <AnimalEntity>[];
              return _ProfileBody(
                user: authState.user,
                animals: animals,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Əsas gövdə ────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserEntity user;
  final List<AnimalEntity> animals;

  const _ProfileBody({required this.user, required this.animals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ProfileHeroHeader(user: user),
          ),
          SliverToBoxAdapter(
            child: ProfileStatsRow(animals: animals),
          ),
          SliverToBoxAdapter(
            child: ProfileMenuSection(animals: animals),
          ),
          const SliverToBoxAdapter(
            child: ProfileLogoutButton(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}