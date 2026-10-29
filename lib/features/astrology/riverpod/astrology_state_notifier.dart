import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/utils/kua_calculator.dart';
import '../model/astrology_result_model.dart';
import '../model/birth_profile_model.dart';
import '../repository/astrology_repo.dart';

enum AstrologyStatus {
  initial,
  loading,

  /// No birth profile saved yet.
  empty,
  ready,
  error,
}

class AstrologyState {
  const AstrologyState({
    this.status = AstrologyStatus.initial,
    this.profile,
    this.result,
    this.isSaving = false,
    this.message,
  });

  final AstrologyStatus status;
  final BirthProfileModel? profile;

  /// Null when the profile is saved but the calculation failed.
  final AstrologyResultModel? result;

  /// True while the Birth Information form is being saved and calculated.
  final bool isSaving;
  final String? message;

  int? get kua => profile == null
      ? null
      : kuaNumber(profile!.birthDate, isMale: profile!.kuaBasis == KuaBasis.male);

  AstrologyState copyWith({
    AstrologyStatus? status,
    BirthProfileModel? profile,
    AstrologyResultModel? result,
    bool? isSaving,
    String? message,
  }) => AstrologyState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    result: result ?? this.result,
    isSaving: isSaving ?? this.isSaving,
    message: message,
  );
}

class AstrologyStateNotifier extends StateNotifier<AstrologyState> {
  AstrologyStateNotifier(this._repo, this._userId) : super(const AstrologyState());

  final AstrologyRepo _repo;
  final String? _userId;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      state = const AstrologyState(status: AstrologyStatus.empty);
      return;
    }
    state = state.copyWith(status: AstrologyStatus.loading);
    try {
      final profile = await _repo.fetchBirthProfile(uid);
      if (!mounted) return;
      if (profile == null) {
        state = const AstrologyState(status: AstrologyStatus.empty);
        return;
      }
      final result = await _repo.fetchResult(profile.id!);
      if (!mounted) return;
      state = AstrologyState(status: AstrologyStatus.ready, profile: profile, result: result);
      // A profile without a stored result (e.g. an earlier failure):
      // calculate it now. Charts from the older engine (no aspects or
      // modalities) are recalculated too. The profile stays visible if this fails.
      if (result == null || !result.isAdvanced) await recalculate();
    } on AppException catch (e) {
      if (!mounted) return;
      state = AstrologyState(status: AstrologyStatus.error, message: e.message);
    }
  }

  /// Saves the Birth Information form and calculates the chart.
  /// Returns true on success.
  Future<bool> saveAndCalculate(BirthProfileModel profile) async {
    state = state.copyWith(isSaving: true);
    BirthProfileModel? saved;
    try {
      saved = await _repo.saveBirthProfile(profile);
      final result = await _repo.calculateChart(saved.id!);
      if (!mounted) return false;
      state = AstrologyState(status: AstrologyStatus.ready, profile: saved, result: result);
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      // Keep the saved profile so the user can retry only the calculation.
      state = AstrologyState(
        status: saved != null ? AstrologyStatus.ready : state.status,
        profile: saved ?? state.profile,
        result: saved != null ? null : state.result,
        message: e.message,
      );
      return false;
    }
  }

  Future<void> recalculate() async {
    final id = state.profile?.id;
    if (id == null) return;
    state = state.copyWith(isSaving: true);
    try {
      final result = await _repo.calculateChart(id);
      if (!mounted) return;
      state = state.copyWith(result: result, isSaving: false);
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, message: e.message);
    }
  }
}
