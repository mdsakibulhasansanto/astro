import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/supabase_provider.dart';
import '../repository/auth_repo.dart';
import 'auth_state_notifier.dart';

final authRepoProvider = Provider<AuthRepo>(
  (ref) => AuthRepo(ref.watch(supabaseClientProvider), ref.watch(dioProvider)),
);

final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(ref.watch(authRepoProvider)),
);

/// Id of the signed-in user, or null. Feature providers watch this so
/// their data resets when the user changes.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateNotifierProvider.select((s) => s.user?.id)),
);
