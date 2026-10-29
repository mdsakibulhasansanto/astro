import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/feng_shui_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../astrology/riverpod/astrology_provider.dart';
import '../../room_planner/riverpod/room_planner_provider.dart';
import '../repository/ai_assistant_repo.dart';
import 'ai_assistant_state_notifier.dart';
import 'ai_chat_state_notifier.dart';

final aiAssistantRepoProvider = Provider<AiAssistantRepo>(
  (ref) => AiAssistantRepo(ref.watch(dioProvider)),
);

/// AI explanation for one room, keyed by room id.
final aiAssistantStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<AiAssistantStateNotifier, AiAssistantState, String>(
      (ref, roomId) => AiAssistantStateNotifier(ref.watch(aiAssistantRepoProvider)),
    );

/// What the chat assistant knows: only calculated results, never raw birth
/// details.
Map<String, dynamic> _chatContext(Ref ref) {
  final astrology = ref.read(astrologyStateNotifierProvider);
  final chart = astrology.result;
  final homes = ref.read(homesStateNotifierProvider).homes;
  final kua = astrology.kua;
  return {
    if (chart != null)
      'astrology': {
        'sun_sign': chart.sunSign,
        'moon_sign': chart.moonSign,
        'rising_sign': chart.ascendant,
        'dominant_element': chart.dominantElement.label,
        'weakest_element': chart.weakestElement.label,
        'planets': [
          for (final p in chart.mainPlanets)
            '${p.name} in ${p.sign}${p.house != null ? ' (house ${p.house})' : ''}',
        ],
      },
    'kua_number': ?kua,
    if (kua != null)
      'best_directions': [for (final d in kuaBestDirections[kua] ?? const <Compass>[]) d.label],
    'homes': [
      for (final h in homes)
        {
          'name': h.homeName,
          'rooms': [
            for (final r in h.rooms)
              {
                'name': r.roomName,
                'size': '${r.width} x ${r.height} ${r.unit.label}',
                'faces_on_entry': r.direction.label,
                'door': r.doorPosition.label,
                'window': r.windowPosition.label,
              },
          ],
        },
    ],
  };
}

/// The AI chat conversation, kept while the app is open.
final aiChatStateNotifierProvider = StateNotifierProvider<AiChatStateNotifier, AiChatState>(
  (ref) => AiChatStateNotifier(ref.watch(aiAssistantRepoProvider), () => _chatContext(ref)),
);
