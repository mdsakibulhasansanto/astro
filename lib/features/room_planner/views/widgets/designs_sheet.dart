import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../model/room_design_model.dart';
import '../../model/room_model.dart';
import '../../riverpod/room_planner_provider.dart';
import 'room_canvas.dart';

/// Bottom sheet listing a room's saved designs with open, rename,
/// duplicate and delete. Returns the design to open, if any.
Future<RoomDesignModel?> showDesignsSheet(BuildContext context, RoomModel room) {
  return showModalBottomSheet<RoomDesignModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(heightFactor: 0.8, child: _DesignsList(room: room)),
  );
}

class _DesignsList extends ConsumerWidget {
  const _DesignsList({required this.room});

  final RoomModel room;

  void _toast(BuildContext context, String? error, String ok) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? ok)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designsStateNotifierProvider(room.id!));
    final notifier = ref.read(designsStateNotifierProvider(room.id!).notifier);
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Saved designs', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Open a design to load it into the planner. You can undo, or save it as the room layout.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.designs.isEmpty
                ? Center(
                    child: Text(
                      state.message ?? 'No saved designs yet. Use "Save as design" in the planner.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.designs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = state.designs[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 96,
                              height: 96,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: IgnorePointer(
                                  child: RoomCanvas(room: room, items: d.items),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    '${d.items.length} pieces'
                                    '${d.kind == DesignKind.suggested ? ' · suggested' : ''}'
                                    '${d.updatedAt != null ? ' · ${formatReadableDate(d.updatedAt!.toLocal())}' : ''}',
                                    style: TextStyle(color: c.muted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Design options',
                              onSelected: (v) async {
                                switch (v) {
                                  case 'open':
                                    Navigator.of(context).pop(d);
                                  case 'rename':
                                    final name = await showTextPrompt(
                                      context,
                                      title: 'Rename design',
                                      label: 'Name',
                                      initial: d.name,
                                    );
                                    if (name == null || name.isEmpty) return;
                                    final e = await notifier.rename(d, name);
                                    if (context.mounted) _toast(context, e, 'Renamed.');
                                  case 'duplicate':
                                    final e = await notifier.duplicate(d);
                                    if (context.mounted) _toast(context, e, 'Duplicated.');
                                  case 'delete':
                                    final ok = await showConfirm(
                                      context,
                                      title: 'Delete "${d.name}"?',
                                      message: 'The room layout itself is not changed.',
                                    );
                                    if (!ok) return;
                                    final e = await notifier.delete(d);
                                    if (context.mounted) _toast(context, e, 'Design deleted.');
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'open', child: Text('Open in planner')),
                                PopupMenuItem(value: 'rename', child: Text('Rename')),
                                PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
