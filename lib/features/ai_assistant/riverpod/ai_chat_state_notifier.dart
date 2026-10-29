import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/chat_message_model.dart';
import '../repository/ai_assistant_repo.dart';

class AiChatState {
  const AiChatState({this.messages = const [], this.sending = false, this.error});

  final List<ChatMessageModel> messages;
  final bool sending;
  final String? error;
}

/// The AI chat conversation for this session.
class AiChatStateNotifier extends StateNotifier<AiChatState> {
  AiChatStateNotifier(this._repo, this._context) : super(const AiChatState());

  final AiAssistantRepo _repo;

  /// Builds the user's calculated data at send time (chart, rooms).
  final Map<String, dynamic> Function() _context;

  Future<void> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.sending) return;
    final history = [
      ...state.messages.where((m) => !m.failed),
      ChatMessageModel(role: ChatRole.user, text: clean),
    ];
    state = AiChatState(messages: history, sending: true);
    try {
      final reply = await _repo.chat(history, _context());
      if (!mounted) return;
      state = AiChatState(
        messages: [
          ...history,
          ChatMessageModel(role: ChatRole.assistant, text: reply),
        ],
      );
    } on AppException catch (e) {
      if (!mounted) return;
      state = AiChatState(
        messages: [
          ...history.take(history.length - 1),
          ChatMessageModel(role: ChatRole.user, text: clean, failed: true),
        ],
        error: e.message,
      );
    }
  }

  void clear() => state = const AiChatState();
}
