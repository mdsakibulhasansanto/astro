import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ai_assistant/model/ai_explanation_request_model.dart';
import '../../../ai_assistant/views/widgets/ai_explanation_card.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../../room_planner/riverpod/furniture_planner_state_notifier.dart';
import '../../../room_planner/riverpod/room_planner_provider.dart';
import '../../riverpod/recommendation_provider.dart';
import 'layout_compare.dart';
import 'placement_tile.dart';
import 'zone_card.dart';

/// Full recommendation for a room: summary, colours, furniture placement,
/// directions, decor, the nine zones and the AI reading.
class RecommendationView extends ConsumerWidget {
  const RecommendationView({super.key, required this.roomId, this.header});

  final String roomId;

  /// Shown above the content (e.g. the room picker on the Reading tab).
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(furniturePlannerStateNotifierProvider(roomId));
    final rec = ref.watch(recommendationProvider(roomId));
    final astrology = ref.watch(astrologyStateNotifierProvider);
    final c = context.colors;

    if (planner.status == PlannerStatus.error) {
      return ErrorView(
        message: planner.message ?? 'Could not load this room.',
        onRetry: ref.read(furniturePlannerStateNotifierProvider(roomId).notifier).load,
      );
    }
    if (rec == null) return const LoadingView(message: 'Reading your room…');

    final room = planner.room!;
    final request = AiExplanationRequestModel.from(
      room: room,
      recommendation: rec,
      chart: astrology.result,
      kua: astrology.kua,
    );

    Widget gap() => const SizedBox(height: 16);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        ?header,
        SectionCard(
          title: 'Your Astro Home · ${rec.roomName}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (astrology.result != null)
                Text(
                  '${astrology.result!.sunSign} Sun, ${astrology.result!.moonSign} Moon'
                  '${astrology.result!.ascendant != null ? ', ${astrology.result!.ascendant} Rising' : ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              const SizedBox(height: 6),
              Text(rec.summary),
            ],
          ),
        ),
        gap(),
        AiExplanationCard(roomId: roomId, request: request),
        gap(),
        LayoutCompare(
          roomId: roomId,
          highlight: astrology.kua == null
              ? const []
              : kuaBestDirections[astrology.kua] ?? const [],
        ),
        gap(),
        SectionCard(
          title: 'Furniture position',
          child: rec.placements.isEmpty
              ? Text('No furniture placed yet.', style: TextStyle(color: c.muted))
              : Column(
                  children: [
                    for (final p in rec.placements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PlacementTile(advice: p),
                      ),
                  ],
                ),
        ),
        gap(),
        SectionCard(
          title: 'Color theme',
          child: Column(
            children: [
              for (final s in rec.colors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.palette_outlined, color: c.brass),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s.reason),
                ),
            ],
          ),
        ),
        gap(),
        _BulletCard(
          title: 'Direction suggestions',
          icon: Icons.explore_outlined,
          lines: rec.directionTips,
        ),
        gap(),
        _BulletCard(
          title: 'Decoration ideas',
          icon: Icons.lightbulb_outline,
          lines: rec.decorIdeas,
        ),
        gap(),
        Text('The nine zones', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Laid out as they sit in your room, far wall first. ${room.baguaMethod.label} bagua.',
          style: TextStyle(color: c.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        for (final z in rec.zones)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ZoneCard(reading: z),
          ),
        const SizedBox(height: 6),
        const NoteText(
          'These suggestions follow traditional feng shui and astrology. '
          'They are for inspiration, not scientific claims.',
        ),
      ],
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.title, required this.icon, required this.lines});

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isEmpty) Text('Nothing to add yet.', style: TextStyle(color: c.muted)),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: c.jade),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
