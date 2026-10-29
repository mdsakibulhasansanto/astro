import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/utils/preferences.dart';
import '../repository/onboarding_repo.dart';
import 'onboarding_state_notifier.dart';

final onboardingRepoProvider = Provider<OnboardingRepo>(
  (ref) => OnboardingRepo(ref.watch(sharedPreferencesProvider)),
);

/// True once the user has finished or skipped the intro on this device.
final onboardingStateNotifierProvider = StateNotifierProvider<OnboardingStateNotifier, bool>(
  (ref) => OnboardingStateNotifier(ref.watch(onboardingRepoProvider)),
);
