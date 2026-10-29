import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/app_user_model.dart';
import '../model/login_model.dart';
import '../model/sign_up_model.dart';
import '../repository/auth_repo.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.message, this.passwordRecovery = false});

  const AuthState.initial() : this(status: AuthStatus.initial);

  final AuthStatus status;
  final AppUserModel? user;

  /// Error text, or an info note such as "check your email".
  final String? message;

  /// True after the user opened a password-reset link: they are signed in
  /// only to choose a new password.
  final bool passwordRecovery;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUserModel? user,
    String? message,
    bool? passwordRecovery,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    message: message,
    passwordRecovery: passwordRecovery ?? this.passwordRecovery,
  );
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._repo) : super(const AuthState.initial()) {
    _restore();
    _sub = _repo.authChanges().listen(_onAuthChange);
    _recoverySub = _repo.passwordRecoveryEvents().listen((_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: _repo.currentUser,
        passwordRecovery: true,
      );
    });
  }

  final AuthRepo _repo;
  StreamSubscription<AppUserModel?>? _sub;
  StreamSubscription<void>? _recoverySub;

  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    if (!mounted) return;
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
  }

  void _onAuthChange(AppUserModel? user) {
    // Ignore stream events while a login/sign-up call reports its own result,
    // and before the saved session has been restored.
    if (state.isLoading || state.status == AuthStatus.initial) return;
    if (user != null) {
      // Keep the recovery flag until a new password is saved.
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else if (state.isAuthenticated) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(LoginModel model) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.login(model);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AppException catch (e) {
      if (!mounted) return;
      state = AuthState(status: AuthStatus.error, message: e.message);
    }
  }

  /// Returns true when the account was created (signed in, or awaiting
  /// email confirmation).
  Future<bool> signUp(SignUpModel model) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final result = await _repo.signUp(model);
      if (!mounted) return false;
      if (result == SignUpResult.signedIn) {
        state = AuthState(status: AuthStatus.authenticated, user: _repo.currentUser);
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          message: 'Account created. Check your email to confirm it, then log in.',
        );
      }
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = AuthState(status: AuthStatus.error, message: e.message);
      return false;
    }
  }

  /// Starts Google sign-in. The router moves on when the session arrives.
  Future<void> signInWithGoogle() async {
    try {
      await _repo.signInWithGoogle();
    } on AppException catch (e) {
      if (mounted) state = AuthState(status: AuthStatus.error, message: e.message);
    }
  }

  /// Sends a reset link. Returns null on success or an error message.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordReset(email);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  /// Saves a new password (after a reset link, or from Settings).
  /// Returns null on success or an error message.
  Future<String?> updatePassword(String password) async {
    try {
      await _repo.updatePassword(password);
      if (mounted) state = state.copyWith(passwordRecovery: false);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } on AppException {
      // The local session is cleared even if the server call fails.
    }
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clears an error or info message once it has been shown.
  void clearMessage() {
    if (state.message == null) return;
    state = AuthState(
      status: state.status == AuthStatus.error ? AuthStatus.unauthenticated : state.status,
      user: state.user,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recoverySub?.cancel();
    super.dispose();
  }
}
