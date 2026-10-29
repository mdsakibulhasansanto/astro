import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/network/app_exception.dart';
import '../model/premium_status_model.dart';
import '../repository/subscription_repo.dart';

class SubscriptionState {
  const SubscriptionState({
    this.status = const PremiumStatusModel(),
    this.loading = true,
    this.storeAvailable = false,
    this.products = const [],
    this.busy = false,
    this.message,
  });

  final PremiumStatusModel status;
  final bool loading;
  final bool storeAvailable;
  final List<ProductDetails> products;

  /// A purchase or restore is in progress.
  final bool busy;
  final String? message;

  bool get isPremium => status.isActive;

  SubscriptionState copyWith({
    PremiumStatusModel? status,
    bool? loading,
    bool? storeAvailable,
    List<ProductDetails>? products,
    bool? busy,
    String? message,
  }) => SubscriptionState(
    status: status ?? this.status,
    loading: loading ?? this.loading,
    storeAvailable: storeAvailable ?? this.storeAvailable,
    products: products ?? this.products,
    busy: busy ?? this.busy,
    message: message,
  );
}

/// Premium status and the Google Play purchase flow.
class SubscriptionStateNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionStateNotifier(this._repo, this._userId) : super(const SubscriptionState()) {
    _purchaseSub = _repo.purchases.listen(_onPurchases, onError: (_) {});
  }

  final SubscriptionRepo _repo;
  final String? _userId;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      state = const SubscriptionState(loading: false);
      return;
    }
    try {
      final status = await _repo.fetchStatus(uid);
      if (mounted) state = state.copyWith(status: status, loading: false);
    } on AppException catch (e) {
      if (mounted) state = state.copyWith(loading: false, message: e.message);
    }
    final available = await _repo.storeAvailable();
    if (!mounted) return;
    state = state.copyWith(storeAvailable: available);
    if (!available) return;
    try {
      final products = await _repo.products();
      if (mounted) state = state.copyWith(products: products);
    } on AppException catch (e) {
      if (mounted) state = state.copyWith(message: e.message);
    }
  }

  Future<void> buy(ProductDetails product) async {
    final uid = _userId;
    if (uid == null || state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await _repo.buy(product, uid);
    } on AppException catch (e) {
      if (mounted) state = state.copyWith(busy: false, message: e.message);
    }
  }

  Future<void> restore() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await _repo.restore();
      // Restored purchases arrive on the purchase stream; refresh anyway.
      await Future<void>.delayed(const Duration(seconds: 2));
      await _refreshStatus();
      if (mounted) {
        state = state.copyWith(
          busy: false,
          message: state.isPremium ? 'Premium restored.' : 'No active subscription found.',
        );
      }
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, message: 'Could not restore purchases.');
    }
  }

  Future<void> _refreshStatus() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final status = await _repo.fetchStatus(uid);
      if (mounted) state = state.copyWith(status: status);
    } on AppException {
      // Keep the last known status.
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          if (mounted) state = state.copyWith(busy: true, message: 'Waiting for the store…');
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await _repo.verify(p);
            await _repo.complete(p);
            await _refreshStatus();
            if (mounted) {
              state = state.copyWith(busy: false, message: 'Welcome to Astro Home Premium!');
            }
          } on AppException catch (e) {
            if (mounted) state = state.copyWith(busy: false, message: e.message);
          }
        case PurchaseStatus.error:
          await _repo.complete(p);
          if (mounted) {
            state = state.copyWith(
              busy: false,
              message: p.error?.message ?? 'The purchase failed.',
            );
          }
        case PurchaseStatus.canceled:
          await _repo.complete(p);
          if (mounted) state = state.copyWith(busy: false);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
