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
import '../../../../core/widgets/skeleton.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../../astrology/riverpod/astrology_state_notifier.dart';
import '../../../astrology/views/widgets/insight_card.dart';
import '../../../auth/riverpod/auth_provider.dart';
import '../../../daily_reading/riverpod/daily_reading_provider.dart';
import '../../../daily_reading/views/widgets/daily_reading_card.dart';
import '../../../recommendation/model/recommendation_model.dart';
import '../../../recommendation/riverpod/recommendation_provider.dart';
import '../../../room_planner/model/room_model.dart';
import '../../../room_planner/riverpod/homes_state_notifier.dart';
import '../../../room_planner/riverpod/room_planner_provider.dart';

/// Home tab: astrology summary, quick actions, homes, recent rooms and the
/// latest recommendation.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider.select((s) => s.user));
    final astrology = ref.watch(astrologyStateNotifierProvider);
    final homes = ref.watch(homesStateNotifierProvider);
    final c = context.colors;

    final rooms = [...homes.allRooms]
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(astrologyStateNotifierProvider.notifier).load(),
              ref.read(homesStateNotifierProvider.notifier).load(),
              ref.read(dailyReadingStateNotifierProvider.notifier).load(),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Hero(name: user?.displayName ?? '', astrology: astrology),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionLabel('Today'),
                    const DailyReadingCard(),
                    const SectionLabel('Quick actions'),
                    const _QuickActions(),
                    if (rooms.isNotEmpty) ...[
                      const SectionLabel('Latest recommendation'),
                      _LatestRecommendation(room: rooms.first),
                    ],
                    SectionLabel(
                      'My homes',
                      trailing: TextButton(
                        onPressed: () => context.goNamed(RouteNames.planner),
                        child: const Text('See all'),
                      ),
                    ),
                    if (homes.status != HomesStatus.ready)
                      const _HomesSkeleton()
                    else if (homes.homes.isEmpty)
                      _EmptyCard(
                        icon: Icons.add_home_outlined,
                        text: 'Create your first home to start planning rooms.',
                        action: 'Create home',
                        onTap: () => context.goNamed(RouteNames.createHome),
                      )
                    else
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: homes.homes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final h = homes.homes[i];
                            return _HomeChip(
                              name: h.homeName,
                              rooms: h.rooms.length,
                              onTap: () => context.goNamed(RouteNames.planner),
                            );
                          },
                        ),
                      ),
                    if (rooms.isNotEmpty) ...[
                      const SectionLabel('Recent rooms'),
                      for (final r in rooms.take(3)) _RoomRow(room: r),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name, required this.astrology});

  final String name;
  final AstrologyState astrology;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final result = astrology.result;
    final top = MediaQuery.paddingOf(context).top;
    return NightSky(
      orbitCenter: const Alignment(1.1, -0.4),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatReadableDate(DateTime.now()).toUpperCase(),
              style: AppTextStyles.overline(SkyColors.brass).copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              name.isEmpty ? _greeting : '$_greeting, $name',
              style: AppTextStyles.display(28, SkyColors.text),
            ),
            const SizedBox(height: 18),
            if (result != null)
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.astrology),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SkyColors.ring),
                  ),
                  child: Row(
                    children: [
                      for (final (label, sign) in [
                        ('Sun', result.sunSign),
                        ('Moon', result.moonSign),
                        ('Rising', result.ascendant),
                      ])
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.toUpperCase(),
                                style: AppTextStyles.overline(
                                  SkyColors.muted,
                                ).copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sign == null
                                    ? '—'
                                    : '${signByName(sign).symbol}${AppTextStyles.textVariation} $sign',
                                style: AppTextStyles.display(17, SkyColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      const Icon(Icons.chevron_right, color: SkyColors.muted),
                    ],
                  ),
                ),
              )
            else if (astrology.status == AstrologyStatus.empty)
              FilledButton.icon(
                onPressed: () => context.goNamed(RouteNames.birthInfo),
                style: FilledButton.styleFrom(
                  backgroundColor: SkyColors.brass,
                  foregroundColor: SkyColors.top,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Create your birth chart'),
              )
            else
              const _SignsSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the Sun / Moon / Rising card while the chart loads.
class _SignsSkeleton extends StatelessWidget {
  const _SignsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SkyColors.ring),
      ),
      child: Shimmer(
        onDark: true,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 38, height: 9),
                    SizedBox(height: 8),
                    SkeletonBox(width: 76, height: 16),
                  ],
                ),
              ),
            const SkeletonBox(width: 18, height: 18, radius: 9),
          ],
        ),
      ),
    );
  }
}

/// Placeholder home cards while homes load.
class _HomesSkeleton extends StatelessWidget {
  const _HomesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => const SizedBox(
          width: 160,
          child: SkeletonCard(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 26, height: 26, radius: 8),
                Spacer(),
                SkeletonBox(width: 96, height: 16),
                SizedBox(height: 6),
                SkeletonBox(width: 54, height: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.auto_awesome_outlined, 'Chart', () => context.goNamed(RouteNames.astrology)),
      (Icons.add_home_outlined, 'New home', () => context.goNamed(RouteNames.createHome)),
      (Icons.chat_bubble_outline, 'Ask AI', () => context.pushNamed(RouteNames.aiChat)),
      (Icons.menu_book_outlined, 'Reading', () => context.goNamed(RouteNames.reading)),
    ];
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: actions[i].$3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    children: [
                      Icon(actions[i].$1, color: c.brass),
                      const SizedBox(height: 6),
                      Text(
                        actions[i].$2,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestRecommendation extends ConsumerWidget {
  const _LatestRecommendation({required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recommendationProvider(room.id!));
    final c = context.colors;
    final improve = rec?.placements.where((p) => p.verdict == PlacementVerdict.improve).toList();

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.goNamed(RouteNames.reading),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.brass.withValues(alpha: 0.5)),
          ),
          child: rec == null
              ? const Shimmer(child: SkeletonLines(lines: 2))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.roomName, style: AppTextStyles.display(20, c.ink)),
                    const SizedBox(height: 4),
                    Text(
                      rec.placements.isEmpty
                          ? 'No furniture placed yet. Open the planner to add some.'
                          : improve!.isEmpty
                          ? 'Every piece already sits in a supportive spot.'
                          : '${improve.length} of ${rec.placements.length} pieces could move to a better spot.',
                      style: TextStyle(color: c.muted),
                    ),
                    if (improve != null && improve.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.swap_horiz, color: c.brass, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${improve.first.label}: ${improve.first.currentLabel} → '
                              '${improve.first.suggestedDirection?.label ?? 'see reading'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _HomeChip extends StatelessWidget {
  const _HomeChip({required this.name, required this.rooms, required this.onTap});

  final String name;
  final int rooms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.home_outlined, color: c.brass),
              const Spacer(),
              Text(
                name,
                style: AppTextStyles.display(17, c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$rooms ${rooms == 1 ? 'room' : 'rooms'}',
                style: TextStyle(color: c.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.line),
          ),
          leading: Icon(Icons.crop_square, color: c.muted),
          title: Text(room.roomName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${formatNumber(room.width)} × ${formatNumber(room.height)} ${room.unit.label} · faces ${room.direction.label}',
          ),
          trailing: Icon(Icons.chevron_right, color: c.muted),
          onTap: () =>
              context.goNamed(RouteNames.furniturePlanner, pathParameters: {'roomId': room.id!}),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.brass, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
