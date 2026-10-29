import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../model/ai_explanation_request_model.dart';
import '../../riverpod/ai_assistant_provider.dart';
import '../../riverpod/ai_assistant_state_notifier.dart';
import '../../../subscription/views/widgets/premium_gate.dart';

/// Friendly AI reading of the calculated results for one room.
class AiExplanationCard extends ConsumerWidget {
  const AiExplanationCard({super.key, required this.roomId, required this.request});

  final String roomId;

  /// Current calculated inputs. The explanation is regenerated on request.
  final AiExplanationRequestModel request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAssistantStateNotifierProvider(roomId));
    final notifier = ref.read(aiAssistantStateNotifierProvider(roomId).notifier);
    final c = context.colors;
    final loading = state.status == AiStatus.loading;
    final stale = state.isStaleFor(request);

    return SectionCard(
      title: 'Personalized reading',
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.explanation != null) ...[
            Text(state.explanation!.text, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
          ] else if (!loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Get a friendly explanation of your chart and this room’s suggestions.',
                style: TextStyle(color: c.muted),
              ),
            ),
          if (stale)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Your layout changed since this reading was written.',
                style: TextStyle(color: c.brass, fontSize: 13),
              ),
            ),
          if (state.status == AiStatus.error)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.message ?? 'Could not get a reading.',
                style: TextStyle(color: c.fire),
              ),
            ),
          Row(
            children: [
              FilledButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        if (await requirePremium(context, ref, 'The AI reading')) {
                          notifier.explain(request);
                        }
                      },
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  loading
                      ? 'Writing…'
                      : state.explanation == null
                      ? 'Explain my results'
                      : 'Refresh reading',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'AI explains the calculated results in plain words. It does not calculate '
            'your chart or choose directions.',
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
