import 'package:flutter/material.dart';

/// Device-level preferences.
class AppSettingsModel {
  const AppSettingsModel({
    this.themeMode = ThemeMode.system,
    this.dailyReminder = false,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
  });

  final ThemeMode themeMode;

  /// A daily local notification when the reading is ready.
  final bool dailyReminder;
  final TimeOfDay reminderTime;

  AppSettingsModel copyWith({ThemeMode? themeMode, bool? dailyReminder, TimeOfDay? reminderTime}) =>
      AppSettingsModel(
        themeMode: themeMode ?? this.themeMode,
        dailyReminder: dailyReminder ?? this.dailyReminder,
        reminderTime: reminderTime ?? this.reminderTime,
      );
}
