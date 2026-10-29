import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../../astrology/views/widgets/insight_card.dart';
import '../../model/daily_reading_model.dart';
import '../../riverpod/daily_reading_provider.dart';
import '../../riverpod/daily_reading_state_notifier.dart';

/// Today's reading in full: Moon, transits to your chart, retrogrades and
/// a design tip for your space.
class DailyReadingScreen extends ConsumerWidget {
  const DailyReadingScreen({super.key, this.reading});

  /// A past reading to show; null shows today's.
  final DailyReadingModel? reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyReadingStateNotifierProvider);
    final day = reading ?? state.reading;
    final natal = ref.watch(astrologyStateNotifierProvider.select((s) => s.result));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(reading == null ? 'Today' : formatReadableDate(reading!.date)),
        actions: [
          if (reading == null)
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.history),
              onPressed: () => context.pushNamed(RouteNames.readingHistory),
            ),
        ],
      ),
      body: day == null
          ? (state.status == DailyStatus.error
                ? ErrorView(
                    message: state.message ?? 'Could not load the reading.',
                    onRetry: ref.read(dailyReadingStateNotifierProvider.notifier).load,
                  )
                : const LoadingView(message: 'Reading today\'s sky…'))
          : RefreshIndicator(
              onRefresh: ref.read(dailyReadingStateNotifierProvider.notifier).load,
              child: Builder(
                builder: (context) {
                  final insight = ref.read(dailyInsightEngineProvider).build(day, natal: natal);
                  final moon = signByName(day.moonSign);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      Text(
                        formatReadableDate(day.date).toUpperCase(),
                        style: AppTextStyles.overline(c.brass),
                      ),
                      const SizedBox(height: 6),
                      Text(insight.headline, style: AppTextStyles.display(28, c.ink)),
                      const SizedBox(height: 10),
                      KeywordChips(words: insight.focusWords),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'The Moon today',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moon.symbol + AppTextStyles.textVariation,
                              style: AppTextStyles.symbol(30, c.forAstroElement(moon.element)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(insight.moonText, style: const TextStyle(height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      const SectionLabel('Transits to your chart'),
                      if (insight.transitTexts.isEmpty)
                        Text(
                          'No close transits to your chart today: a quiet, steady day.',
                          style: TextStyle(color: c.muted),
                        )
                      else
                        for (final (title, body) in insight.transitTexts) ...[
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AppTextStyles.display(18, c.ink)),
                                const SizedBox(height: 6),
                                Text(body, style: const TextStyle(height: 1.5)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      if (insight.retrogradeText != null) ...[
                        const SizedBox(height: 6),
                        NoteText(insight.retrogradeText!),
                      ],
                      const SectionLabel('Design tip for today'),
                      SectionCard(
                        highlight: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, color: c.brass),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(insight.designTip, style: const TextStyle(height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      const SectionLabel('Planets today'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in day.planetSigns.entries)
                            Chip(
                              avatar: Text(
                                (planetSymbols[e.key] ?? '') + AppTextStyles.textVariation,
                                style: AppTextStyles.symbol(14, c.ink),
                              ),
                              label: Text(
                                '${e.value}${day.retrogrades.contains(e.key) ? ' ℞' : ''}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
