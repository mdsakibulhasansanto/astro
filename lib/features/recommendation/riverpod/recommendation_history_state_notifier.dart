import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/recommendation_history_model.dart';
import '../model/recommendation_model.dart';
import '../repository/recommendation_history_repo.dart';

class RecommendationHistoryState {
  const RecommendationHistoryState({this.loading = true, this.entries = const [], this.message});

  final bool loading;
  final List<RecommendationHistoryModel> entries;
  final String? message;
}

/// Kept recommendations for one room.
class RecommendationHistoryStateNotifier extends StateNotifier<RecommendationHistoryState> {
  RecommendationHistoryStateNotifier(this._repo, this.roomId)
    : super(const RecommendationHistoryState());

  final RecommendationHistoryRepo _repo;
  final String roomId;

  Future<void> load() async {
    try {
      final entries = await _repo.fetch(roomId);
      if (mounted) state = RecommendationHistoryState(loading: false, entries: entries);
    } on AppException catch (e) {
      if (mounted) state = RecommendationHistoryState(loading: false, message: e.message);
    }
  }

  /// Returns null on success or an error message.
  Future<String?> save(RecommendationModel rec) async {
    try {
      final entry = await _repo.save(roomId, rec);
      if (mounted) {
        state = RecommendationHistoryState(loading: false, entries: [entry, ...state.entries]);
      }
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(RecommendationHistoryModel entry) async {
    try {
      await _repo.delete(entry.id);
      if (mounted) {
        state = RecommendationHistoryState(
          loading: false,
          entries: state.entries.where((e) => e.id != entry.id).toList(),
        );
      }
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }
}
