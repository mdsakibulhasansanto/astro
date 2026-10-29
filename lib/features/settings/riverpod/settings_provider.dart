import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/utils/preferences.dart';
import '../../../core/utils/reminder_service.dart';
import '../model/app_settings_model.dart';
import '../repository/settings_repo.dart';
import 'settings_state_notifier.dart';

final settingsRepoProvider = Provider<SettingsRepo>(
  (ref) => SettingsRepo(ref.watch(sharedPreferencesProvider)),
);

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());

final settingsStateNotifierProvider =
    StateNotifierProvider<SettingsStateNotifier, AppSettingsModel>(
      (ref) => SettingsStateNotifier(
        ref.watch(settingsRepoProvider),
        ref.watch(reminderServiceProvider),
      ),
    );
