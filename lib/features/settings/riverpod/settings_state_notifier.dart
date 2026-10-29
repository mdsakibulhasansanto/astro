import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/utils/reminder_service.dart';
import '../model/app_settings_model.dart';
import '../repository/settings_repo.dart';

class SettingsStateNotifier extends StateNotifier<AppSettingsModel> {
  SettingsStateNotifier(this._repo, this._reminders) : super(_repo.load());

  final SettingsRepo _repo;
  final ReminderService _reminders;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.saveThemeMode(mode);
  }

  /// Turns the daily reminder on or off, or changes its time.
  /// Returns null on success or a message to show.
  Future<String?> setReminder({required bool enabled, TimeOfDay? time}) async {
    final at = time ?? state.reminderTime;
    try {
      if (enabled) {
        final allowed = await _reminders.requestPermission();
        if (!allowed) return 'Notifications are turned off for Astro Home in your phone settings.';
        await _reminders.scheduleDaily(at);
      } else {
        await _reminders.cancelDaily();
      }
    } catch (_) {
      return 'Could not update the reminder on this device.';
    }
    state = state.copyWith(dailyReminder: enabled, reminderTime: at);
    await _repo.saveReminder(enabled, at);
    return null;
  }
}
