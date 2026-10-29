import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/night_sky.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../riverpod/astrology_provider.dart';
import '../../riverpod/astrology_state_notifier.dart';
import '../widgets/aspects_tab.dart';
import '../widgets/chart_tab.dart';
import '../widgets/insights_tab.dart';
import '../widgets/planets_tab.dart';

/// Astrology tab: chart, planets, aspects and insights, or a prompt to
/// enter birth details.
class AstrologyResultScreen extends ConsumerWidget {
  const AstrologyResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(astrologyStateNotifierProvider);
    final notifier = ref.read(astrologyStateNotifierProvider.notifier);

    Widget simple(Widget body) => Scaffold(
      appBar: AppBar(title: const Text('Astrology')),
      body: body,
    );

    return switch (state.status) {
      AstrologyStatus.initial ||
      AstrologyStatus.loading => simple(const LoadingView(message: 'Loading your chart…')),
      AstrologyStatus.error => simple(
        ErrorView(message: state.message ?? 'Could not load your chart.', onRetry: notifier.load),
      ),
      AstrologyStatus.empty => simple(
        EmptyView(
          icon: Icons.auto_awesome_outlined,
          title: 'Start with your birth chart',
          message:
              'Enter your birth date, time and place. We calculate your planets, houses, '
              'aspects and element balance, then explain what they mean.',
          actionLabel: 'Enter birth details',
          onAction: () => context.goNamed(RouteNames.birthInfo),
        ),
      ),
      AstrologyStatus.ready when state.result == null => simple(
        _NeedsCalculation(state: state, onRecalculate: notifier.recalculate),
      ),
      AstrologyStatus.ready => _ChartScreen(state: state),
    };
  }
}

class _NeedsCalculation extends StatelessWidget {
  const _NeedsCalculation({required this.state, required this.onRecalculate});

  final AstrologyState state;
  final Future<void> Function() onRecalculate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.message ?? 'Your chart has not been calculated yet.',
                style: TextStyle(color: c.fire),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.isSaving ? null : onRecalculate,
                child: Text(state.isSaving ? 'Calculating…' : 'Calculate my chart'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartScreen extends ConsumerWidget {
  const _ChartScreen({required this.state});

  final AstrologyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(chartInsightsProvider);
    final result = state.result!;
    final c = context.colors;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, inner) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 286,
              backgroundColor: SkyColors.top,
              foregroundColor: SkyColors.text,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: inner ? Text('${result.sunSign} · ${result.moonSign}') : null,
              titleTextStyle: AppTextStyles.display(20, SkyColors.text),
              actions: [
                if (state.isSaving)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: SkyColors.brass),
                    ),
                  ),
                IconButton(
                  tooltip: 'Edit birth details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.goNamed(RouteNames.birthInfo),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: NightSky(
                  orbitCenter: const Alignment(1.1, -0.6),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 60),
                      // Shrinks instead of overflowing on small phones or
                      // with large system text.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width - 40,
                          child: _HeaderContent(state: state),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                isScrollable: false,
                labelColor: SkyColors.brass,
                unselectedLabelColor: SkyColors.muted,
                indicatorColor: SkyColors.brass,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'Chart'),
                  Tab(text: 'Planets'),
                  Tab(text: 'Aspects'),
                  Tab(text: 'Insights'),
                ],
              ),
            ),
          ],
          body: insights == null
              ? const LoadingView()
              : Container(
                  color: c.bg,
                  child: TabBarView(
                    children: [
                      ChartTab(state: state),
                      PlanetsTab(result: result, insights: insights),
                      AspectsTab(result: result, insights: insights),
                      InsightsTab(insights: insights),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.state});

  final AstrologyState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    final result = state.result!;
    Widget big(String label, String value, String? symbol) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overline(
              SkyColors.brass,
            ).copyWith(fontSize: 10.5, letterSpacing: 1.6),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (symbol != null) ...[
                Text(
                  symbol + AppTextStyles.textVariation,
                  style: AppTextStyles.symbol(16, SkyColors.muted),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.display(21, SkyColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name.isEmpty ? 'Your birth chart' : profile.name,
          style: AppTextStyles.display(28, SkyColors.text),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatReadableDate(profile.birthDate)}'
          '${profile.hasBirthTime ? ' · ${profile.birthTime}' : ''} · ${profile.birthPlace}',
          style: const TextStyle(color: SkyColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            big('Sun', result.sunSign, signByName(result.sunSign).symbol),
            big('Moon', result.moonSign, signByName(result.moonSign).symbol),
            big(
              'Rising',
              result.ascendant ?? '—',
              result.ascendant == null ? null : signByName(result.ascendant!).symbol,
            ),
          ],
        ),
      ],
    );
  }
}
