import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/supabase_provider.dart';
import '../repository/profile_repo.dart';
import 'profile_state_notifier.dart';

final profileRepoProvider = Provider<ProfileRepo>(
  (ref) => ProfileRepo(ref.watch(supabaseClientProvider), ref.watch(dioProvider)),
);

final profileStateNotifierProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileActionsState>(
      (ref) => ProfileStateNotifier(ref.watch(profileRepoProvider)),
    );
