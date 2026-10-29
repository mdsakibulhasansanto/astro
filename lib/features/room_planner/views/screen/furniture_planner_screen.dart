import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../model/layout_checks.dart';
import '../../riverpod/furniture_planner_state_notifier.dart';
import '../../riverpod/room_planner_provider.dart';
import '../widgets/designs_sheet.dart';
import '../widgets/furniture_catalog_sheet.dart';
import '../widgets/room_canvas.dart';
import '../../../subscription/model/premium_status_model.dart';
import '../../../subscription/views/widgets/premium_gate.dart';

enum _MenuAction { saveDesign, openDesigns, exportPng, exportPdf }

/// Interactive Room Planner for one room: zoom, undo/redo, colours,
/// collision warnings, saved designs and export.
class FurniturePlannerScreen extends ConsumerStatefulWidget {
  const FurniturePlannerScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<FurniturePlannerScreen> createState() => _FurniturePlannerScreenState();
}

class _FurniturePlannerScreenState extends ConsumerState<FurniturePlannerScreen> {
  bool _showKua = true;
  bool _showBagua = false;
  bool _exporting = false;
  final _zoom = TransformationController();
  final _planKey = GlobalKey();

  FurniturePlannerStateNotifier get _notifier =>
      ref.read(furniturePlannerStateNotifierProvider(widget.roomId).notifier);

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    final error = await _notifier.save();
    if (mounted) _toast(error ?? 'Layout saved.');
  }

  Future<void> _add() async {
    final type = await showFurnitureCatalog(context);
    if (type != null) _notifier.addItem(type);
  }

  Future<void> _rename(String key, String current) async {
    final label = await showTextPrompt(context, title: 'Rename', label: 'Label', initial: current);
    if (label != null) _notifier.rename(key, label);
  }

  void _zoomBy(double factor) {
    final current = _zoom.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 4.0);
    final size = context.size ?? const Size(400, 600);
    final center = Offset(size.width / 2, size.height / 2.6);
    final m = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(target, target, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    _zoom.value = target == 1 ? Matrix4.identity() : m;
  }

  Future<void> _onMenu(_MenuAction action) async {
    final state = ref.read(furniturePlannerStateNotifierProvider(widget.roomId));
    final room = state.room!;
    switch (action) {
      case _MenuAction.saveDesign:
        final count = ref.read(designsStateNotifierProvider(widget.roomId)).designs.length;
        if (count >= freeDesignLimit &&
            !await requirePremium(context, ref, 'More than $freeDesignLimit designs per room')) {
          return;
        }
        if (!mounted) return;
        final name = await showTextPrompt(
          context,
          title: 'Save as design',
          label: 'Design name',
          initial: '${room.roomName} design',
        );
        if (name == null || name.isEmpty || !mounted) return;
        final error = await ref
            .read(designsStateNotifierProvider(widget.roomId).notifier)
            .saveAs(name, state.items);
        if (mounted) _toast(error ?? 'Design saved.');
      case _MenuAction.openDesigns:
        final design = await showDesignsSheet(context, room);
        if (design != null) {
          _notifier.applyLayout(design.items);
          if (mounted) _toast('Loaded "${design.name}". Tap Save to keep it as the room layout.');
        }
      case _MenuAction.exportPng:
      case _MenuAction.exportPdf:
        await _export(pdf: action == _MenuAction.exportPdf);
    }
  }

  Future<void> _export({required bool pdf}) async {
    final state = ref.read(furniturePlannerStateNotifierProvider(widget.roomId));
    final repo = ref.read(layoutExportRepoProvider);
    final room = state.room!;
    _notifier.select(null);
    _zoom.value = Matrix4.identity();
    setState(() => _exporting = true);
    // Let the plan repaint without selection before capturing it.
    await WidgetsBinding.instance.endOfFrame;
    try {
      final png = await repo.capturePng(_planKey);
      final title = '${room.roomName} · Astro Home';
      if (pdf) {
        final bytes = await repo.buildPdf(
          title: room.roomName,
          subtitle:
              '${room.width} × ${room.height} ${room.unit.label} · faces ${room.direction.label} · '
              '${room.baguaMethod.label} bagua',
          planPng: png,
          notes: [for (final i in state.items) '${i.label}: ${i.type.label}'],
        );
        await repo.share(
          bytes,
          fileName: '${room.roomName}.pdf',
          mime: 'application/pdf',
          text: title,
        );
      } else {
        await repo.share(png, fileName: '${room.roomName}.png', mime: 'image/png', text: title);
      }
    } on AppException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Asks before leaving with unsaved changes.
  Future<void> _onPopBlocked() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save your layout?'),
        content: const Text('You have changes that are not saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (save == null || !mounted) return;
    if (save) {
      final error = await _notifier.save();
      if (!mounted) return;
      if (error != null) {
        _toast(error);
        return;
      }
    }
    if (mounted) _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.planner);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(furniturePlannerStateNotifierProvider(widget.roomId));
    final kua = ref.watch(astrologyStateNotifierProvider.select((s) => s.kua));
    final c = context.colors;
    final room = state.room;
    final overlapping = state.overlapping;

    return PopScope(
      // Unsaved edits are kept until the user decides.
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(room?.roomName ?? 'Room planner'),
          actions: [
            if (room != null) ...[
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: state.canUndo ? _notifier.undo : null,
              ),
              IconButton(
                tooltip: 'Redo',
                icon: const Icon(Icons.redo),
                onPressed: state.canRedo ? _notifier.redo : null,
              ),
              TextButton(
                onPressed: state.isDirty && !state.isSaving ? _save : null,
                child: Text(state.isSaving ? 'Saving…' : 'Save'),
              ),
              PopupMenuButton<Object>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v is _MenuAction) {
                    _onMenu(v);
                  } else if (v == 'setup') {
                    context.pushNamed(
                      RouteNames.roomSetup,
                      pathParameters: {'roomId': widget.roomId},
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'setup',
                    child: ListTile(leading: Icon(Icons.tune), title: Text('Room setup')),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.saveDesign,
                    child: ListTile(
                      leading: Icon(Icons.bookmark_add_outlined),
                      title: Text('Save as design'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.openDesigns,
                    child: ListTile(
                      leading: Icon(Icons.collections_bookmark_outlined),
                      title: Text('Saved designs'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.exportPng,
                    child: ListTile(
                      leading: Icon(Icons.image_outlined),
                      title: Text('Share as image'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.exportPdf,
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Share as PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ],
          bottom: _exporting
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: switch (state.status) {
          PlannerStatus.initial || PlannerStatus.loading => const LoadingView(),
          PlannerStatus.error => ErrorView(
            message: state.message ?? 'Could not load this room.',
            onRetry: _notifier.load,
          ),
          PlannerStatus.ready => Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line),
                  ),
                  child: Stack(
                    children: [
                      // Pinch to zoom; one finger on empty space pans,
                      // on a piece it moves the piece.
                      InteractiveViewer(
                        transformationController: _zoom,
                        minScale: 1,
                        maxScale: 4,
                        child: RepaintBoundary(
                          key: _planKey,
                          child: Container(
                            color: c.surface,
                            padding: const EdgeInsets.all(8),
                            child: RoomCanvas(
                              room: room!,
                              items: state.items,
                              selectedKey: state.selectedKey,
                              overlapping: overlapping,
                              highlightDirections: _showKua && kua != null
                                  ? kuaBestDirections[kua] ?? const []
                                  : const [],
                              showBagua: _showBagua,
                              onSelect: _notifier.select,
                              onGestureStart: (_) => _notifier.beginGesture(),
                              onMove: _notifier.moveBy,
                              onResize: _notifier.resizeBy,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _ZoomControls(
                          onIn: () => _zoomBy(1.5),
                          onOut: () => _zoomBy(1 / 1.5),
                          onReset: () => _zoom.value = Matrix4.identity(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Toolbar(
                state: state,
                overlapCount: overlapping.length,
                showKua: _showKua,
                hasKua: kua != null,
                onToggleKua: (v) => setState(() => _showKua = v),
                showBagua: _showBagua,
                onToggleBagua: (v) => setState(() => _showBagua = v),
                onAdd: _add,
                onRotate: () => _notifier.rotate(state.selectedKey!),
                onRename: () => _rename(state.selectedKey!, state.selected!.label),
                onDelete: () => _notifier.delete(state.selectedKey!),
                onColor: (hex) => _notifier.setColor(state.selectedKey!, hex),
                onRecommend: () => context.pushNamed(
                  RouteNames.recommendation,
                  pathParameters: {'roomId': widget.roomId},
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onIn, required this.onOut, required this.onReset});

  final VoidCallback onIn;
  final VoidCallback onOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget btn(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
    );
    return Container(
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.add, 'Zoom in', onIn),
          btn(Icons.remove, 'Zoom out', onOut),
          btn(Icons.fit_screen_outlined, 'Fit', onReset),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.state,
    required this.overlapCount,
    required this.showKua,
    required this.hasKua,
    required this.onToggleKua,
    required this.showBagua,
    required this.onToggleBagua,
    required this.onAdd,
    required this.onRotate,
    required this.onRename,
    required this.onDelete,
    required this.onColor,
    required this.onRecommend,
  });

  final PlannerState state;
  final int overlapCount;
  final bool showKua;
  final bool hasKua;
  final ValueChanged<bool> onToggleKua;
  final bool showBagua;
  final ValueChanged<bool> onToggleBagua;
  final VoidCallback onAdd;
  final VoidCallback onRotate;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<String?> onColor;
  final VoidCallback onRecommend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = state.selected;
    final room = state.room!;
    final zone = sel == null
        ? null
        : room.mapper.zoneAt(room.baguaMethod, sel.centerX, sel.centerY);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (overlapCount > 0) ...[
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: c.fire),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$overlapCount pieces overlap. Move the ones outlined in red apart.',
                      style: TextStyle(color: c.fire, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              sel == null
                  ? 'Drag a piece to move it, the dot to resize. Pinch or use + and − to zoom. '
                        'The thick edge is its back.'
                  : '${sel.label} · ${zone!.label} zone',
              style: TextStyle(
                color: sel == null ? c.muted : c.ink,
                fontWeight: sel == null ? FontWeight.w400 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            if (sel != null) ...[
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Swatch(color: null, selected: sel.color == null, onTap: () => onColor(null)),
                    for (final (hex, name) in furnitureColors)
                      _Swatch(
                        color: hex,
                        name: name,
                        selected: sel.color?.toUpperCase() == hex.toUpperCase(),
                        onTap: () => onColor(hex),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (sel != null) ...[
                  OutlinedButton.icon(
                    onPressed: onRotate,
                    icon: const Icon(Icons.rotate_90_degrees_cw_outlined, size: 18),
                    label: const Text('Rotate'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Rename'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, size: 18, color: c.fire),
                    label: const Text('Delete'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add furniture'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRecommend,
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('Recommendations'),
                  ),
                ],
              ],
            ),
            if (hasKua)
              SwitchListTile(
                value: showKua,
                onChanged: onToggleKua,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: c.jade,
                title: const Text('Show my best directions'),
              ),
            SwitchListTile(
              value: showBagua,
              onChanged: onToggleBagua,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: c.jade,
              title: const Text('Show bagua zones'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap, this.name});

  final String? color;
  final String? name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = color == null
        ? c.surface
        : Color(int.parse('FF${color!.substring(1)}', radix: 16));
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: name ?? 'Default',
        child: Semantics(
          button: true,
          selected: selected,
          label: name ?? 'Default colour',
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? c.brass : c.line, width: selected ? 3 : 1),
              ),
              child: color == null
                  ? Icon(Icons.format_color_reset, size: 16, color: c.muted)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
