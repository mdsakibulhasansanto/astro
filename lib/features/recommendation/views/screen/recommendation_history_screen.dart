import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../riverpod/recommendation_provider.dart';

/// Recommendations the user kept for one room, newest first.
class RecommendationHistoryScreen extends ConsumerWidget {
  const RecommendationHistoryScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationHistoryStateNotifierProvider(roomId));
    final notifier = ref.read(recommendationHistoryStateNotifierProvider(roomId).notifier);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendation history')),
      body: state.loading
          ? const LoadingView()
          : state.message != null
          ? ErrorView(message: state.message!, onRetry: notifier.load)
          : state.entries.isEmpty
          ? const EmptyView(
              icon: Icons.history,
              title: 'No history yet',
              message: 'Tap "Keep in history" on a recommendation to track how your room improves.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: state.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final e = state.entries[i];
                final good = e.pieceCount - e.improvementCount;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.createdAt == null
                                  ? 'Saved'
                                  : '${formatReadableDate(e.createdAt!.toLocal())} · '
                                        '${TimeOfDay.fromDateTime(e.createdAt!.toLocal()).format(context)}',
                              style: AppTextStyles.overline(c.muted),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(Icons.delete_outline, color: c.muted),
                            onPressed: () async {
                              final ok = await showConfirm(
                                context,
                                title: 'Delete this entry?',
                                message: 'Only this history entry is removed.',
                              );
                              if (!ok) return;
                              final err = await notifier.delete(e);
                              if (err != null && context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(err)));
                              }
                            },
                          ),
                        ],
                      ),
                      Text(
                        e.pieceCount == 0
                            ? 'No furniture'
                            : '$good of ${e.pieceCount} pieces in a good spot',
                        style: AppTextStyles.display(19, c.ink),
                      ),
                      if (e.pieceCount > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: good / e.pieceCount,
                            minHeight: 8,
                            backgroundColor: c.bg,
                            color: c.jade,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(e.summary, style: TextStyle(color: c.muted, fontSize: 13.5)),
                      for (final p in e.placements.where((p) => p['verdict'] == 'improve'))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '• ${p['furniture']}: ${p['current_zone']} → ${p['suggested_zone'] ?? '—'}',
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
