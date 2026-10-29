import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/utils/device_timezone.dart';
import '../model/daily_reading_model.dart';
import '../repository/daily_reading_repo.dart';

enum DailyStatus { idle, loading, ready, needsChart, error }

class DailyReadingState {
  const DailyReadingState({this.status = DailyStatus.idle, this.reading, this.message});

  final DailyStatus status;
  final DailyReadingModel? reading;
  final String? message;
}

/// Today's reading for the signed-in user.
class DailyReadingStateNotifier extends StateNotifier<DailyReadingState> {
  DailyReadingStateNotifier(this._repo, {required this.hasChart, this.fallbackTimezone = 'UTC'})
    : super(const DailyReadingState());

  final DailyReadingRepo _repo;
  final bool hasChart;
  final String fallbackTimezone;

  Future<void> load() async {
    if (!hasChart) {
      state = const DailyReadingState(status: DailyStatus.needsChart);
      return;
    }
    state = DailyReadingState(status: DailyStatus.loading, reading: state.reading);
    try {
      final tz = await deviceTimezone(fallback: fallbackTimezone);
      final reading = await _repo.fetchFor(DateTime.now(), tz);
      if (mounted) state = DailyReadingState(status: DailyStatus.ready, reading: reading);
    } on AppException catch (e) {
      if (mounted) {
        state = DailyReadingState(
          status: DailyStatus.error,
          reading: state.reading,
          message: e.message,
        );
      }
    }
  }
}

class ReadingHistoryState {
  const ReadingHistoryState({this.loading = true, this.readings = const [], this.message});

  final bool loading;
  final List<DailyReadingModel> readings;
  final String? message;
}

/// Past daily readings, newest first.
class ReadingHistoryStateNotifier extends StateNotifier<ReadingHistoryState> {
  ReadingHistoryStateNotifier(this._repo, this._userId) : super(const ReadingHistoryState());

  final DailyReadingRepo _repo;
  final String? _userId;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      state = const ReadingHistoryState(loading: false);
      return;
    }
    try {
      final list = await _repo.history(uid);
      if (mounted) state = ReadingHistoryState(loading: false, readings: list);
    } on AppException catch (e) {
      if (mounted) state = ReadingHistoryState(loading: false, message: e.message);
    }
  }
}
