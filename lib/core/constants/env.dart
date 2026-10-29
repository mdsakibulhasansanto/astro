/// Supabase connection settings.
///
/// The defaults point at the astro-home project, so a plain `flutter run`
/// (or the IDE's Run button) works. Pass `--dart-define-from-file=env.json`
/// to point the app at a different project.
///
/// Only the public URL and publishable key belong here. They are safe in the
/// app because row-level security protects the data. Secret keys (service
/// role, AI provider) live in Supabase secrets.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ajihpxesnkwckvdcfzxr.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_73wZZxDfpqLQw0FLtXzK6A_ERqLkjZy',
  );

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Deep link that Supabase email links (confirm sign-up, reset password)
  /// redirect to. Registered in AndroidManifest.xml and Info.plist, and in
  /// Supabase Auth → URL Configuration.
  static const authRedirectUrl = 'astrohome://auth-callback';

  /// Base URL for Supabase Edge Functions, called through Dio.
  static String get functionsUrl => '$supabaseUrl/functions/v1/';
}
