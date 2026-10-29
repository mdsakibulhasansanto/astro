import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../repository/profile_repo.dart';

class ProfileActionsState {
  const ProfileActionsState({this.busy = false});

  /// True while a change is being saved.
  final bool busy;
}

/// Account actions from the Profile and Settings screens.
class ProfileStateNotifier extends StateNotifier<ProfileActionsState> {
  ProfileStateNotifier(this._repo) : super(const ProfileActionsState());

  final ProfileRepo _repo;

  Future<String?> _run(Future<void> Function() action) async {
    state = const ProfileActionsState(busy: true);
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    } finally {
      if (mounted) state = const ProfileActionsState();
    }
  }

  /// Returns null on success or an error message.
  Future<String?> updateName(String name) => _run(() => _repo.updateName(name));

  /// Returns null on success or an error message. The caller signs out.
  Future<String?> deleteAccount() => _run(_repo.deleteAccount);
}
