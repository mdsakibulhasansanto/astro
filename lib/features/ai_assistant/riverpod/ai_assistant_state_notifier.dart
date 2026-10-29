import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/ai_explanation_model.dart';
import '../model/ai_explanation_request_model.dart';
import '../repository/ai_assistant_repo.dart';

enum AiStatus { idle, loading, ready, error }

class AiAssistantState {
  const AiAssistantState({
    this.status = AiStatus.idle,
    this.explanation,
    this.signature,
    this.message,
  });

  final AiStatus status;
  final AiExplanationModel? explanation;

  /// Inputs the current explanation was written for.
  final String? signature;
  final String? message;

  bool isStaleFor(AiExplanationRequestModel request) =>
      explanation != null && signature != request.signature;
}

class AiAssistantStateNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantStateNotifier(this._repo) : super(const AiAssistantState());

  final AiAssistantRepo _repo;

  Future<void> explain(AiExplanationRequestModel request) async {
    if (state.status == AiStatus.loading) return;
    state = AiAssistantState(
      status: AiStatus.loading,
      explanation: state.explanation,
      signature: state.signature,
    );
    try {
      final result = await _repo.explain(request);
      if (!mounted) return;
      state = AiAssistantState(
        status: AiStatus.ready,
        explanation: result,
        signature: request.signature,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      state = AiAssistantState(
        status: AiStatus.error,
        explanation: state.explanation,
        signature: state.signature,
        message: e.message,
      );
    }
  }
}
