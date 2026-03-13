// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Mock istifadeci databazasi
  final List<Map<String, String>> _mockUsers = [
    {
      'id': 'demo-001',
      'name': 'Demo Istifadeci',
      'email': 'demo@meta.az',
      'password': '123456',
    }
  ];

  UserEntity? _currentUser;

  AuthBloc() : super(const AuthInitial()) {
    AppLogger.melumat('AUTH BLOC', 'AuthBloc ise salindi');
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
  }

  UserEntity? get currentUser => _currentUser;

  Future<void> _onCheckAuth(
    CheckAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.blocHadise('AuthBloc', 'CheckAuthEvent');
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    if (_currentUser != null) {
      emit(AuthAuthenticated(_currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.blocHadise('AuthBloc', 'LoginEvent');
    AppLogger.melumat('AUTH', 'Login cehdi: ${event.email}');
    emit(const AuthLoading());

    // Mock gecikmesi
    await Future.delayed(const Duration(seconds: 1));

    // Email + sifre yoxla
    final found = _mockUsers.where(
      (u) => u['email'] == event.email && u['password'] == event.password,
    );

    if (found.isNotEmpty) {
      final userData = found.first;
      _currentUser = UserEntity(
        id: userData['id']!,
        name: userData['name']!,
        email: userData['email']!,
        createdAt: DateTime.now(),
      );
      AppLogger.ugur('AUTH', 'Login ugurlu: ${_currentUser!.name}');
      emit(AuthAuthenticated(_currentUser!));
    } else {
      AppLogger.xeberdarliq('AUTH', 'Login ugursuz: yanlis email/sifre');
      emit(const AuthError('Email ve ya sifre yanlisdir'));
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.blocHadise('AuthBloc', 'RegisterEvent');
    AppLogger.melumat('AUTH', 'Qeydiyyat cehdi: ${event.email}');
    emit(const AuthLoading());

    await Future.delayed(const Duration(seconds: 1));

    // Email artiq varsa
    final emailExists = _mockUsers.any((u) => u['email'] == event.email);
    if (emailExists) {
      AppLogger.xeberdarliq('AUTH', 'Qeydiyyat: email artiq movcuddur');
      emit(const AuthError('Bu email artiq qeydiyyatdan kecib'));
      return;
    }

    // Yeni istifadeci elave et
    final newId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    _mockUsers.add({
      'id': newId,
      'name': event.name,
      'email': event.email,
      'password': event.password,
    });

    _currentUser = UserEntity(
      id: newId,
      name: event.name,
      email: event.email,
      createdAt: DateTime.now(),
    );

    AppLogger.ugur('AUTH', 'Qeydiyyat ugurlu: ${_currentUser!.name}');
    emit(AuthAuthenticated(_currentUser!));
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.blocHadise('AuthBloc', 'LogoutEvent');
    AppLogger.melumat('AUTH', 'Cixis edilir: ${_currentUser?.name}');
    _currentUser = null;
    emit(const AuthUnauthenticated());
    AppLogger.ugur('AUTH', 'Cixis ugurlu');
  }
}