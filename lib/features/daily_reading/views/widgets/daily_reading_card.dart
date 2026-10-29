import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../riverpod/daily_reading_provider.dart';
import '../../riverpod/daily_reading_state_notifier.dart';

/// Today's reading summary for the Dashboard.
class DailyReadingCard extends ConsumerWidget {
  const DailyReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyReadingStateNotifierProvider);
    final natal = ref.watch(astrologyStateNotifierProvider.select((s) => s.result));
    final c = context.colors;

    Widget shell(Widget child) => Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: state.reading == null ? null : () => context.goNamed(RouteNames.dailyReading),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.jade.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );

    switch (state.status) {
      case DailyStatus.needsChart:
        return shell(
          Text('Create your birth chart to get a daily reading.', style: TextStyle(color: c.muted)),
        );
      case DailyStatus.error when state.reading == null:
        return shell(
          Row(
            children: [
              Expanded(child: Text(state.message ?? 'Could not load today\'s reading.')),
              TextButton(
                onPressed: ref.read(dailyReadingStateNotifierProvider.notifier).load,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case _ when state.reading == null:
        return shell(
          const Shimmer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 44, height: 44, radius: 22),
                SizedBox(width: 14),
                Expanded(child: SkeletonLines(lines: 2)),
              ],
            ),
          ),
        );
      default:
        break;
    }

    final reading = state.reading!;
    final insight = ref.read(dailyInsightEngineProvider).build(reading, natal: natal);
    final moon = signByName(reading.moonSign);
    return shell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                moon.symbol + AppTextStyles.textVariation,
                style: AppTextStyles.symbol(22, c.forAstroElement(moon.element)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Moon in ${reading.moonSign} · ${reading.moonPhase}',
                  style: AppTextStyles.overline(c.jade),
                ),
              ),
              Icon(Icons.chevron_right, color: c.muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.headline, style: AppTextStyles.display(20, c.ink)),
          const SizedBox(height: 6),
          Text(
            insight.designTip,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.muted, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
