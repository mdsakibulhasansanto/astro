import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/supabase_provider.dart';
import '../../auth/riverpod/auth_provider.dart';
import '../repository/subscription_repo.dart';
import 'subscription_state_notifier.dart';

final subscriptionRepoProvider = Provider<SubscriptionRepo>(
  (ref) => SubscriptionRepo(ref.watch(supabaseClientProvider), ref.watch(dioProvider)),
);

final subscriptionStateNotifierProvider =
    StateNotifierProvider<SubscriptionStateNotifier, SubscriptionState>((ref) {
      final notifier = SubscriptionStateNotifier(
        ref.watch(subscriptionRepoProvider),
        ref.watch(currentUserIdProvider),
      );
      notifier.load();
      return notifier;
    });

/// True while the user has an active Premium subscription.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionStateNotifierProvider.select((s) => s.isPremium)),
);
