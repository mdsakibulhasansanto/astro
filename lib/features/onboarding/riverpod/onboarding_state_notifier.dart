import 'package:flutter_riverpod/legacy.dart';

import '../repository/onboarding_repo.dart';

/// Whether the intro has been completed. Starts from the saved value, so
/// the router can decide the first screen without waiting.
class OnboardingStateNotifier extends StateNotifier<bool> {
  OnboardingStateNotifier(this._repo) : super(_repo.isCompleted);

  final OnboardingRepo _repo;

  Future<void> complete() async {
    state = true;
    await _repo.markCompleted();
  }
}
