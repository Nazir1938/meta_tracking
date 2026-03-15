import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import '../../domain/entities/user_entity.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

class LoginEvent extends AuthEvent {
  final String email, password;
  const LoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name, email, password;
  const RegisterEvent(
      {required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Ad, avatar, herdGroupLabel yenilə — Firestore-a yaz
class UpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? avatarUrl;
  final String? herdGroupLabel;

  const UpdateProfileEvent({
    this.name,
    this.avatarUrl,
    this.herdGroupLabel,
  });

  @override
  List<Object?> get props => [name, avatarUrl, herdGroupLabel];
}

// ─── States ───────────────────────────────────────────────────────────────────

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

class AuthProfileUpdated extends AuthState {
  final UserEntity user;
  const AuthProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthBloc() : super(const AuthInitial()) {
    AppLogger.melumat('AUTH BLOC', 'AuthBloc işə salındı');
    on<CheckAuthEvent>(_onCheck);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  // ── Check ─────────────────────────────────────────────────────────────────

  Future<void> _onCheck(CheckAuthEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'CheckAuthEvent');
    emit(const AuthLoading());
    final user = _auth.currentUser;
    if (user != null) {
      final entity = await _getUserEntity(user.uid);
      if (entity != null) {
        AppLogger.ugur('AUTH BLOC', 'Sessiya bərpa edildi: ${user.email}');
        emit(AuthAuthenticated(entity));
      } else {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'LoginEvent: ${event.email}');
    emit(const AuthLoading());
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final entity = await _getUserEntity(cred.user!.uid);
      AppLogger.ugur('AUTH BLOC', 'Login uğurlu: ${cred.user!.email}');
      emit(AuthAuthenticated(entity!));
    } on FirebaseAuthException catch (e) {
      AppLogger.xeta('AUTH BLOC', 'Login xətası: ${e.code}');
      emit(AuthError(_parseError(e.code)));
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'RegisterEvent: ${event.email}');
    emit(const AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      await cred.user!.updateDisplayName(event.name);

      final entity = UserEntity(
        id: cred.user!.uid,
        name: event.name,
        email: event.email,
        createdAt: DateTime.now(),
        herdGroupLabel: 'Naxır',
      );

      await _db.collection('users').doc(cred.user!.uid).set({
        'name': event.name,
        'email': event.email,
        'herdGroupLabel': 'Naxır',
        'createdAt': Timestamp.now(),
      });

      AppLogger.ugur('AUTH BLOC', 'Qeydiyyat uğurlu: ${event.name}');
      emit(AuthAuthenticated(entity));
    } on FirebaseAuthException catch (e) {
      AppLogger.xeta('AUTH BLOC', 'Qeydiyyat xətası: ${e.code}');
      emit(AuthError(_parseError(e.code)));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'LogoutEvent');
    await _auth.signOut();
    AppLogger.ugur('AUTH BLOC', 'Çıxış uğurlu');
    emit(const AuthUnauthenticated());
  }

  // ── Update Profile ────────────────────────────────────────────────────────

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<AuthState> emit) async {
    AppLogger.blocHadise('AuthBloc', 'UpdateProfileEvent');

    final current = state;
    if (current is! AuthAuthenticated) return;

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (event.name != null && event.name!.isNotEmpty) {
        updates['name'] = event.name;
        await _auth.currentUser?.updateDisplayName(event.name);
      }
      if (event.avatarUrl != null) {
        updates['avatarUrl'] = event.avatarUrl;
      }
      if (event.herdGroupLabel != null && event.herdGroupLabel!.isNotEmpty) {
        updates['herdGroupLabel'] = event.herdGroupLabel;
      }

      await _db.collection('users').doc(current.user.id).update(updates);

      final updated = current.user.copyWith(
        name: event.name,
        avatarUrl: event.avatarUrl,
        herdGroupLabel: event.herdGroupLabel,
      );

      AppLogger.ugur('AUTH BLOC', 'Profil yeniləndi: ${updated.name}');
      emit(AuthAuthenticated(updated));
      emit(AuthProfileUpdated(updated));
    } catch (e, st) {
      AppLogger.xeta('AUTH BLOC', 'Profil yeniləmə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(AuthError('Profil yenilənmədi: $e'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<UserEntity?> _getUserEntity(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      return UserEntity(
        id: uid,
        name: d['name'] as String? ?? '',
        email: d['email'] as String? ?? '',
        avatarUrl: d['avatarUrl'] as String?,
        herdGroupLabel: d['herdGroupLabel'] as String? ?? 'Naxır',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.xeta('AUTH BLOC', 'İstifadəçi məlumatı alınmadı',
          xetaObyekti: e);
      return null;
    }
  }

  String _parseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu email ilə istifadəçi tapılmadı';
      case 'wrong-password':
        return 'Şifrə yanlışdır';
      case 'email-already-in-use':
        return 'Bu email artıq qeydiyyatdan keçib';
      case 'weak-password':
        return 'Şifrə ən az 6 xanə olmalıdır';
      case 'invalid-email':
        return 'Email formatı yanlışdır';
      case 'too-many-requests':
        return 'Çox cəhd edildi. Sonra yenidən cəhd edin';
      default:
        return 'Xəta baş verdi: $code';
    }
  }
}
