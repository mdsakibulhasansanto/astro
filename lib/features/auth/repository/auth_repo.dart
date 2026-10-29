import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/env.dart';
import '../../../core/network/app_exception.dart';
import '../model/app_user_model.dart';
import '../model/login_model.dart';
import '../model/sign_up_model.dart';

/// Result of a registration attempt.
enum SignUpResult {
  /// Signed in straight away.
  signedIn,

  /// Supabase sent a confirmation email; the user must confirm first.
  confirmEmail,
}

/// Authentication through Supabase Auth. All errors surface as
/// [AppException].
class AuthRepo {
  AuthRepo(this._client, [Dio? dio]) : _dio = dio ?? Dio();

  final SupabaseClient _client;
  final Dio _dio;

  GoTrueClient get _auth => _client.auth;

  AppUserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUserModel.fromSupabaseUser(user);
  }

  /// Emits the user after every sign-in, sign-out and token refresh.
  Stream<AppUserModel?> authChanges() => _auth.onAuthStateChange.map((event) {
    final user = event.session?.user;
    return user == null ? null : AppUserModel.fromSupabaseUser(user);
  });

  /// Fires when the user opens a password-reset link from their email.
  /// Supabase signs them in for that purpose only; the app then asks for a
  /// new password.
  Stream<void> passwordRecoveryEvents() =>
      _auth.onAuthStateChange.where((e) => e.event == AuthChangeEvent.passwordRecovery).map((_) {});

  /// Restores the saved session, refreshing it if it has expired.
  Future<AppUserModel?> restoreSession() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      try {
        await _auth.refreshSession();
      } on AuthRetryableFetchException {
        // Offline: keep the user signed in; Supabase retries the refresh.
        return currentUser;
      } on AuthException {
        await _auth.signOut();
        return null;
      }
    }
    return currentUser;
  }

  Future<AppUserModel> login(LoginModel model) async {
    try {
      final m = model.normalized();
      final res = await _auth.signInWithPassword(email: m.email, password: m.password);
      final user = res.user;
      if (user == null) throw const AppException('Login failed.');
      return AppUserModel.fromSupabaseUser(user);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<SignUpResult> signUp(SignUpModel model) async {
    try {
      final res = await _auth.signUp(
        email: model.normalizedEmail,
        password: model.password,
        data: model.toMetadata(),
        emailRedirectTo: Env.authRedirectUrl,
      );
      return res.session == null ? SignUpResult.confirmEmail : SignUpResult.signedIn;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Opens Google sign-in in the browser. The session arrives through the
  /// `astrohome://auth-callback` deep link and [authChanges].
  Future<void> signInWithGoogle() async {
    try {
      // Check first, so users get a clear message instead of an error page.
      final res = await _dio.get<Map<String, dynamic>>(
        '${Env.supabaseUrl}/auth/v1/settings',
        options: Options(headers: {'apikey': Env.supabasePublishableKey}),
      );
      final external = res.data?['external'];
      if (external is Map && external['google'] != true) {
        throw const AppException('Google sign-in is not set up yet. Use email for now.');
      }
      final launched = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Env.authRedirectUrl,
      );
      if (!launched) throw const AppException('Could not open Google sign-in.');
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Emails a reset link that opens the app.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: Env.authRedirectUrl,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Sets a new password for the signed-in (or recovering) user.
  Future<void> updatePassword(String password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
