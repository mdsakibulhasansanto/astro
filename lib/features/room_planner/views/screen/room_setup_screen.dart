import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/constants/furniture_catalog.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bagua_mapper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../model/room_model.dart';
import '../../riverpod/homes_state_notifier.dart';
import '../../riverpod/room_planner_provider.dart';
import '../widgets/compass_dialog.dart';

const _roomSuggestions = ['Bedroom', 'Living Room', 'Kitchen', 'Office Room', 'Study Room'];

/// Add Room (with [homeId]) or Room Setup for an existing room ([roomId]).
class RoomSetupScreen extends ConsumerWidget {
  const RoomSetupScreen({super.key, this.homeId, this.roomId})
    : assert(homeId != null || roomId != null);

  final String? homeId;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homes = ref.watch(homesStateNotifierProvider);
    final isEdit = roomId != null;
    final title = isEdit ? 'Room setup' : 'Add room';

    if (homes.status != HomesStatus.ready) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: homes.status == HomesStatus.error
            ? ErrorView(
                message: homes.message ?? 'Could not load your rooms.',
                onRetry: ref.read(homesStateNotifierProvider.notifier).load,
              )
            : const LoadingView(),
      );
    }
    final existing = isEdit ? homes.roomById(roomId!) : null;
    if (isEdit && existing == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const ErrorView(message: 'This room no longer exists.'),
      );
    }
    return _RoomForm(
      title: title,
      initial: existing ?? RoomModel(homeId: homeId!, roomName: '', width: 12, height: 10),
    );
  }
}

class _RoomForm extends ConsumerStatefulWidget {
  const _RoomForm({required this.title, required this.initial});

  final String title;
  final RoomModel initial;

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.roomName);
  late final _width = TextEditingController(text: formatNumber(widget.initial.width));
  late final _depth = TextEditingController(text: formatNumber(widget.initial.height));
  late MeasurementUnit _unit = widget.initial.unit;
  late Compass _direction = widget.initial.direction;
  late DoorPosition _door = widget.initial.doorPosition;
  late WindowPosition _window = widget.initial.windowPosition;
  late BaguaMethod _method = widget.initial.baguaMethod;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _depth.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final room = widget.initial.copyWith(
      roomName: _name.text,
      width: double.parse(_width.text.trim()),
      height: double.parse(_depth.text.trim()),
      unit: _unit,
      direction: _direction,
      doorPosition: _door,
      windowPosition: _window,
      baguaMethod: _method,
    );
    try {
      final saved = await ref.read(homesStateNotifierProvider.notifier).saveRoom(room);
      if (!mounted) return;
      final planner = furniturePlannerStateNotifierProvider(saved.id!);
      if (ref.exists(planner)) ref.read(planner.notifier).updateRoom(saved);
      if (widget.initial.id == null) {
        context.goNamed(RouteNames.furniturePlanner, pathParameters: {'roomId': saved.id!});
      } else {
        context.pop();
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (min, max) = _unit == MeasurementUnit.ft ? (4.0, 60.0) : (1.2, 18.0);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Room name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.requiredText(v, 'Room name'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in _roomSuggestions)
                  ActionChip(label: Text(s), onPressed: () => setState(() => _name.text = s)),
              ],
            ),
            const SizedBox(height: 16),
            _Label('Measurement unit'),
            SegmentedButton<MeasurementUnit>(
              segments: const [
                ButtonSegment(value: MeasurementUnit.ft, label: Text('Feet')),
                ButtonSegment(value: MeasurementUnit.m, label: Text('Meters')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() {
                final next = s.first;
                if (next == _unit) return;
                // Convert the typed sizes so the room stays the same.
                final factor = next.perFoot / _unit.perFoot;
                for (final ctrl in [_width, _depth]) {
                  final v = double.tryParse(ctrl.text.trim());
                  if (v != null) ctrl.text = formatNumber((v * factor * 10).round() / 10);
                }
                _unit = next;
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _width,
                    decoration: InputDecoration(
                      labelText: 'Width (${_unit.label})',
                      helperText: 'Along the door wall',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.numberInRange(min, max, 'Width'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _depth,
                    decoration: InputDecoration(
                      labelText: 'Depth (${_unit.label})',
                      helperText: 'Door to far wall',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.numberInRange(min, max, 'Depth'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Compass>(
              // Rebuilt when the phone compass sets a new value.
              key: ValueKey(_direction),
              initialValue: _direction,
              decoration: const InputDecoration(
                labelText: 'Compass direction',
                helperText: 'The direction you face as you walk in. Use a compass app at the door.',
                helperMaxLines: 2,
              ),
              items: [
                for (final d in Compass.values) DropdownMenuItem(value: d, child: Text(d.label)),
              ],
              onChanged: (v) => setState(() => _direction = v ?? Compass.n),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final dir = await showCompassDialog(context);
                  if (dir != null) setState(() => _direction = dir);
                },
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Use phone compass'),
              ),
            ),
            const SizedBox(height: 8),
            _Label('Door position on the door wall'),
            SegmentedButton<DoorPosition>(
              segments: [
                for (final d in DoorPosition.values) ButtonSegment(value: d, label: Text(d.label)),
              ],
              selected: {_door},
              onSelectionChanged: (s) => setState(() => _door = s.first),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WindowPosition>(
              initialValue: _window,
              decoration: const InputDecoration(labelText: 'Window position'),
              items: [
                for (final w in WindowPosition.values)
                  DropdownMenuItem(value: w, child: Text(w.label)),
              ],
              onChanged: (v) => setState(() => _window = v ?? WindowPosition.top),
            ),
            const SizedBox(height: 16),
            _Label('Bagua method'),
            SegmentedButton<BaguaMethod>(
              segments: [
                for (final m in BaguaMethod.values) ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _method == BaguaMethod.door
                  ? 'Door method: the grid lines up with the entrance. Career is always by the door.'
                  : 'Compass method: each zone follows its real compass direction.',
              style: TextStyle(color: c.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save room'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.muted),
    ),
  );
}
