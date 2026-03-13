import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';

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
  const RegisterEvent(
      {required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

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

const _kUserId = 'auth_user_id';
const _kUserName = 'auth_user_name';
const _kUserEmail = 'auth_user_email';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final List<Map<String, String>> _mockUsers = [
    {
      'id': 'demo-001',
      'name': 'Demo İstifadəçi',
      'email': 'demo@meta.az',
      'password': '123456'
    },
  ];
  UserEntity? _currentUser;

  AuthBloc() : super(const AuthInitial()) {
    AppLogger.melumat('AUTH BLOC', 'AuthBloc işə salındı');
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
  }

  UserEntity? get currentUser => _currentUser;

  Future<void> _saveSession(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUserName, user.name);
    await prefs.setString(_kUserEmail, user.email);
  }

  Future<UserEntity?> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserId);
    final name = prefs.getString(_kUserName);
    final email = prefs.getString(_kUserEmail);
    if (id != null && name != null && email != null) {
      return UserEntity(
          id: id, name: name, email: email, createdAt: DateTime.now());
    }
    return null;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserEmail);
  }

  Future<void> _onCheckAuth(
      CheckAuthEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'CheckAuthEvent');
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    final saved = await _loadSession();
    if (saved != null) {
      _currentUser = saved;
      AppLogger.ugur('AUTH', 'Session bərpa edildi: ${saved.email}');
      emit(AuthAuthenticated(_currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'LoginEvent');
    AppLogger.melumat('AUTH', 'Login cəhdi: ${event.email}');
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    final found = _mockUsers.where(
      (u) => u['email'] == event.email && u['password'] == event.password,
    );
    if (found.isNotEmpty) {
      final d = found.first;
      _currentUser = UserEntity(
          id: d['id']!,
          name: d['name']!,
          email: d['email']!,
          createdAt: DateTime.now());
      await _saveSession(_currentUser!);
      AppLogger.ugur('AUTH', 'Login uğurlu: ${_currentUser!.name}');
      emit(AuthAuthenticated(_currentUser!));
    } else {
      AppLogger.xeberdarliq('AUTH', 'Login uğursuz');
      emit(const AuthError('Email və ya şifrə yanlışdır'));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'RegisterEvent');
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    if (_mockUsers.any((u) => u['email'] == event.email)) {
      emit(const AuthError('Bu email artıq qeydiyyatdan keçib'));
      return;
    }
    final newId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    _mockUsers.add({
      'id': newId,
      'name': event.name,
      'email': event.email,
      'password': event.password
    });
    _currentUser = UserEntity(
        id: newId,
        name: event.name,
        email: event.email,
        createdAt: DateTime.now());
    await _saveSession(_currentUser!);
    AppLogger.ugur('AUTH', 'Qeydiyyat uğurlu: ${_currentUser!.name}');
    emit(AuthAuthenticated(_currentUser!));
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'LogoutEvent');
    _currentUser = null;
    await _clearSession();
    emit(const AuthUnauthenticated());
    AppLogger.ugur('AUTH', 'Çıxış uğurlu');
  }
}
