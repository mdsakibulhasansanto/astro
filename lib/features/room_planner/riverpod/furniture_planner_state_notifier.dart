import 'dart:math' as math;

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/furniture_catalog.dart';
import '../../../core/network/app_exception.dart';
import '../model/furniture_model.dart';
import '../model/layout_checks.dart';
import '../model/room_model.dart';
import '../repository/room_planner_repo.dart';

enum PlannerStatus { initial, loading, ready, error }

class PlannerState {
  const PlannerState({
    this.status = PlannerStatus.initial,
    this.room,
    this.items = const [],
    this.removedIds = const {},
    this.selectedKey,
    this.isDirty = false,
    this.isSaving = false,
    this.canUndo = false,
    this.canRedo = false,
    this.message,
  });

  final PlannerStatus status;
  final RoomModel? room;
  final List<FurnitureModel> items;

  /// Saved pieces that are no longer in the layout (deleted on save).
  final Set<String> removedIds;
  final String? selectedKey;

  /// True when the layout has changes not yet saved.
  final bool isDirty;
  final bool isSaving;
  final bool canUndo;
  final bool canRedo;
  final String? message;

  FurnitureModel? get selected {
    for (final i in items) {
      if (i.localKey == selectedKey) return i;
    }
    return null;
  }

  /// Pieces that collide with another piece (rugs excluded).
  Set<String> get overlapping => overlappingKeys(items);

  PlannerState copyWith({
    PlannerStatus? status,
    RoomModel? room,
    List<FurnitureModel>? items,
    Set<String>? removedIds,
    String? Function()? selectedKey,
    bool? isDirty,
    bool? isSaving,
    bool? canUndo,
    bool? canRedo,
    String? message,
  }) => PlannerState(
    status: status ?? this.status,
    room: room ?? this.room,
    items: items ?? this.items,
    removedIds: removedIds ?? this.removedIds,
    selectedKey: selectedKey != null ? selectedKey() : this.selectedKey,
    isDirty: isDirty ?? this.isDirty,
    isSaving: isSaving ?? this.isSaving,
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    message: message,
  );
}

/// Interactive layout of one room: add, drag, rotate, resize, recolour and
/// delete furniture with undo/redo, then save. Works in relative
/// coordinates (0–1).
class FurniturePlannerStateNotifier extends StateNotifier<PlannerState> {
  FurniturePlannerStateNotifier(this._repo, this.roomId) : super(const PlannerState());

  final RoomPlannerRepo _repo;
  final String roomId;
  int _keySeq = 0;

  /// Ids of pieces stored in the database at the last load or save.
  Set<String> _savedIds = {};
  final List<List<FurnitureModel>> _undo = [];
  final List<List<FurnitureModel>> _redo = [];
  static const _historyLimit = 60;

  /// Smallest piece, as a share of the room side.
  static const _minSize = 0.04;

  String _newKey() => 'new-${DateTime.now().microsecondsSinceEpoch}-${_keySeq++}';

  Future<void> load() async {
    state = state.copyWith(status: PlannerStatus.loading);
    try {
      final results = await Future.wait([_repo.fetchRoom(roomId), _repo.fetchFurniture(roomId)]);
      if (!mounted) return;
      final items = results[1] as List<FurnitureModel>;
      _savedIds = {for (final i in items) ?i.id};
      _undo.clear();
      _redo.clear();
      state = PlannerState(
        status: PlannerStatus.ready,
        room: results[0] as RoomModel,
        items: items,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(status: PlannerStatus.error, message: e.message);
    }
  }

  /// Picks up edits made on Room Setup. Pieces keep their relative spots.
  void updateRoom(RoomModel room) {
    state = state.copyWith(room: room);
  }

  void select(String? key) => state = state.copyWith(selectedKey: () => key);

  // ----------------------------------------------------------------- history

  void _snapshot() {
    _undo.add(state.items);
    if (_undo.length > _historyLimit) _undo.removeAt(0);
    _redo.clear();
  }

  /// Applies a new list of items. [record] stores the previous layout for undo.
  void _setItems(List<FurnitureModel> items, {bool record = true, String? Function()? select}) {
    if (record) _snapshot();
    final ids = {for (final i in items) ?i.id};
    state = state.copyWith(
      items: items,
      removedIds: _savedIds.difference(ids),
      selectedKey: select,
      isDirty: true,
      canUndo: _undo.isNotEmpty,
      canRedo: _redo.isNotEmpty,
    );
  }

  /// Call when a drag or resize starts, so the whole gesture undoes at once.
  void beginGesture() {
    _snapshot();
    state = state.copyWith(canUndo: true, canRedo: false);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(state.items);
    final previous = _undo.removeLast();
    _setItems(previous, record: false, select: () => null);
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(state.items);
    final next = _redo.removeLast();
    _setItems(next, record: false, select: () => null);
  }

  // ----------------------------------------------------------------- editing

  FurnitureModel? _find(String key) {
    for (final i in state.items) {
      if (i.localKey == key) return i;
    }
    return null;
  }

  void _replace(FurnitureModel item, {bool record = true}) {
    _setItems([
      for (final i in state.items) i.localKey == item.localKey ? item : i,
    ], record: record);
  }

  void addItem(FurnitureType type) {
    final room = state.room;
    if (room == null) return;
    final ftToUnit = room.unit.perFoot;
    final w = math.min(type.widthFt * ftToUnit / room.width, 1.0);
    final h = math.min(type.depthFt * ftToUnit / room.height, 1.0);
    final key = _newKey();
    final count = state.items.where((i) => i.type == type).length;
    final item = FurnitureModel(
      localKey: key,
      roomId: roomId,
      type: type,
      label: count == 0 ? type.label : '${type.label} ${count + 1}',
      x: (1 - w) / 2,
      y: (1 - h) / 2,
      width: w,
      height: h,
    );
    _setItems([...state.items, item], select: () => key);
  }

  /// Moves by a relative delta, keeping the piece inside the room.
  /// Part of a gesture: call [beginGesture] first.
  void moveBy(String key, double dx, double dy) {
    final i = _find(key);
    if (i == null) return;
    _replace(
      i.copyWith(x: (i.x + dx).clamp(0.0, 1 - i.width), y: (i.y + dy).clamp(0.0, 1 - i.height)),
      record: false,
    );
  }

  /// Grows or shrinks from the bottom-right corner. Part of a gesture.
  void resizeBy(String key, double dw, double dh) {
    final i = _find(key);
    if (i == null) return;
    _replace(
      i.copyWith(
        width: (i.width + dw).clamp(_minSize, 1 - i.x),
        height: (i.height + dh).clamp(_minSize, 1 - i.y),
      ),
      record: false,
    );
  }

  /// Turns a piece 90° clockwise around its center. Its footprint swaps
  /// width and depth, converted between the room's two sides.
  void rotate(String key) {
    final i = _find(key);
    final room = state.room;
    if (i == null || room == null) return;
    final ratio = room.width / room.height;
    final w = math.min(i.height / ratio, 1.0);
    final h = math.min(i.width * ratio, 1.0);
    _replace(
      i.copyWith(
        width: w,
        height: h,
        x: (i.centerX - w / 2).clamp(0.0, 1 - w),
        y: (i.centerY - h / 2).clamp(0.0, 1 - h),
        rotation: (i.rotation + 90) % 360,
      ),
    );
  }

  void rename(String key, String label) {
    final i = _find(key);
    if (i == null || label.trim().isEmpty) return;
    _replace(i.copyWith(label: label.trim()));
  }

  /// Sets the fill colour (`#RRGGBB`), or clears it with null.
  void setColor(String key, String? color) {
    final i = _find(key);
    if (i == null || i.color == color) return;
    _replace(i.copyWith(color: () => color));
  }

  void delete(String key) {
    if (_find(key) == null) return;
    _setItems(state.items.where((x) => x.localKey != key).toList(), select: () => null);
  }

  /// Replaces the whole layout (a saved or suggested design). Undoable.
  void applyLayout(List<FurnitureModel> layout) {
    _setItems([for (final i in layout) i.cloneFor(roomId, _newKey())], select: () => null);
  }

  /// Returns null on success, or an error message.
  Future<String?> save() async {
    if (!state.isDirty) return null;
    state = state.copyWith(isSaving: true);
    try {
      final stored = await _repo.saveFurniture(
        roomId: roomId,
        items: state.items,
        removedIds: state.removedIds,
      );
      if (!mounted) return null;
      _savedIds = {for (final i in stored) ?i.id};
      _undo.clear();
      _redo.clear();
      state = state.copyWith(
        items: stored,
        removedIds: const {},
        selectedKey: () => null,
        isDirty: false,
        isSaving: false,
        canUndo: false,
        canRedo: false,
      );
      return null;
    } on AppException catch (e) {
      if (!mounted) return e.message;
      state = state.copyWith(isSaving: false, message: e.message);
      return e.message;
    }
  }
}
