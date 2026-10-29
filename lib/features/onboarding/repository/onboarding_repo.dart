import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether the intro has been shown.
class OnboardingRepo {
  OnboardingRepo(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'onboarding_completed_v1';

  bool get isCompleted => _prefs.getBool(_key) ?? false;

  Future<void> markCompleted() => _prefs.setBool(_key, true);
}
