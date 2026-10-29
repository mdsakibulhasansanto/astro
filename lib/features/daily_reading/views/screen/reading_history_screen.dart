import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../riverpod/daily_reading_provider.dart';
import 'daily_reading_screen.dart';

/// Earlier daily readings.
class ReadingHistoryScreen extends ConsumerWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingHistoryStateNotifierProvider);
    final natal = ref.watch(astrologyStateNotifierProvider.select((s) => s.result));
    final engine = ref.read(dailyInsightEngineProvider);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Reading history')),
      body: state.loading
          ? const LoadingView()
          : state.message != null
          ? ErrorView(
              message: state.message!,
              onRetry: ref.read(readingHistoryStateNotifierProvider.notifier).load,
            )
          : state.readings.isEmpty
          ? const EmptyView(
              icon: Icons.history,
              title: 'No readings yet',
              message: 'Open today\'s reading from the Home tab; each day is saved here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: state.readings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = state.readings[i];
                final insight = engine.build(r, natal: natal);
                final moon = signByName(r.moonSign);
                return Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: c.line),
                    ),
                    leading: Text(
                      moon.symbol + AppTextStyles.textVariation,
                      style: AppTextStyles.symbol(22, c.forAstroElement(moon.element)),
                    ),
                    title: Text(
                      insight.headline,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${formatReadableDate(r.date)} · Moon in ${r.moonSign}'),
                    trailing: Icon(Icons.chevron_right, color: c.muted),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => DailyReadingScreen(reading: r))),
                  ),
                );
              },
            ),
    );
  }
}
