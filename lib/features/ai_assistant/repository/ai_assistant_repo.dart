import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../model/ai_explanation_model.dart';
import '../model/ai_explanation_request_model.dart';
import '../model/chat_message_model.dart';

/// Calls the `ai-explain` Edge Function, which holds the AI key server-side.
class AiAssistantRepo {
  AiAssistantRepo(this._dio);

  final Dio _dio;

  Future<AiExplanationModel> explain(AiExplanationRequestModel request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiExplain,
        data: request.toJson(),
      );
      final model = AiExplanationModel.fromJson(res.data ?? const {});
      if (model.text.isEmpty) {
        throw const AppException('The assistant returned an empty answer. Please try again.');
      }
      return model;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Sends the conversation plus the user's calculated data; returns the reply.
  Future<String> chat(List<ChatMessageModel> messages, Map<String, dynamic> context) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiChat,
        data: {
          'messages': [for (final m in messages) m.toJson()],
          'context': context,
        },
      );
      final reply = (res.data?['reply'] as String? ?? '').trim();
      if (reply.isEmpty) throw const AppException('The assistant returned an empty reply.');
      return reply;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
