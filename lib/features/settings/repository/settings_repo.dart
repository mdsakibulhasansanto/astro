import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/app_settings_model.dart';

/// Stores preferences on this device.
class SettingsRepo {
  SettingsRepo(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'settings_theme_mode';
  static const _reminderKey = 'settings_daily_reminder';
  static const _reminderMinuteKey = 'settings_reminder_minute_of_day';

  AppSettingsModel load() {
    final minute = _prefs.getInt(_reminderMinuteKey) ?? 8 * 60;
    return AppSettingsModel(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      ),
      dailyReminder: _prefs.getBool(_reminderKey) ?? false,
      reminderTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) => _prefs.setString(_themeKey, mode.name);

  Future<void> saveReminder(bool enabled, TimeOfDay time) async {
    await _prefs.setBool(_reminderKey, enabled);
    await _prefs.setInt(_reminderMinuteKey, time.hour * 60 + time.minute);
  }
}
