import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../room_planner/model/room_design_model.dart';
import '../../../room_planner/riverpod/room_planner_provider.dart';
import '../../../room_planner/views/widgets/room_canvas.dart';
import '../../riverpod/recommendation_provider.dart';
import '../../../subscription/model/premium_status_model.dart';
import '../../../subscription/views/widgets/premium_gate.dart';

/// Current layout next to the suggested one, with actions to apply the
/// suggestion, save it as a design, and keep the recommendation.
class LayoutCompare extends ConsumerStatefulWidget {
  const LayoutCompare({super.key, required this.roomId, this.highlight = const []});

  final String roomId;
  final List<Compass> highlight;

  @override
  ConsumerState<LayoutCompare> createState() => _LayoutCompareState();
}

class _LayoutCompareState extends ConsumerState<LayoutCompare> {
  bool _suggested = false;
  bool _busy = false;

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _saveDesign() async {
    final layout = ref.read(suggestedLayoutProvider(widget.roomId));
    final room = ref.read(furniturePlannerStateNotifierProvider(widget.roomId)).room;
    if (layout == null || room == null) return;
    if (ref.read(designsStateNotifierProvider(widget.roomId)).designs.length >= freeDesignLimit &&
        !await requirePremium(context, ref, 'More than $freeDesignLimit designs per room')) {
      return;
    }
    if (!mounted) return;
    final name = await showTextPrompt(
      context,
      title: 'Save suggested layout',
      label: 'Design name',
      initial: '${room.roomName} · suggested',
    );
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final error = await ref
        .read(designsStateNotifierProvider(widget.roomId).notifier)
        .saveAs(name, layout, kind: DesignKind.suggested);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(error ?? 'Saved as a design.');
  }

  Future<void> _apply() async {
    if (!await requirePremium(context, ref, 'Applying the suggested layout')) return;
    final layout = ref.read(suggestedLayoutProvider(widget.roomId));
    if (layout == null) return;
    ref.read(furniturePlannerStateNotifierProvider(widget.roomId).notifier).applyLayout(layout);
    setState(() => _suggested = false);
    _toast('Suggested layout applied. Open the planner and tap Save to keep it (Undo works too).');
  }

  Future<void> _keep() async {
    final rec = ref.read(recommendationProvider(widget.roomId));
    if (rec == null) return;
    setState(() => _busy = true);
    final error = await ref
        .read(recommendationHistoryStateNotifierProvider(widget.roomId).notifier)
        .save(rec);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(error ?? 'Saved to recommendation history.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final planner = ref.watch(furniturePlannerStateNotifierProvider(widget.roomId));
    final suggested = ref.watch(suggestedLayoutProvider(widget.roomId));
    final rec = ref.watch(recommendationProvider(widget.roomId));
    final room = planner.room;
    if (room == null || suggested == null || rec == null) return const SizedBox.shrink();
    final changes = rec.improvementCount;

    return SectionCard(
      title: 'Current vs suggested layout',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Current')),
              ButtonSegment(value: true, label: Text('Suggested')),
            ],
            selected: {_suggested},
            onSelectionChanged: (s) => setState(() => _suggested = s.first),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: IgnorePointer(
              child: RoomCanvas(
                room: room,
                items: _suggested ? suggested : planner.items,
                highlightDirections: widget.highlight,
                showBagua: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            changes == 0
                ? 'Your layout already follows the rules; the suggestion is the same.'
                : _suggested
                ? '$changes ${changes == 1 ? 'piece moves' : 'pieces move'} to their suggested zones.'
                : 'Switch to Suggested to see where the rules would place things.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: changes == 0 || _busy ? null : _apply,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Apply to planner'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _saveDesign,
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Save as design'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _keep,
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Keep in history'),
              ),
              TextButton(
                onPressed: () => context.pushNamed(
                  RouteNames.recommendationHistory,
                  pathParameters: {'roomId': widget.roomId},
                ),
                child: const Text('View history'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
