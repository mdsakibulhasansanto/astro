import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../model/premium_status_model.dart';

/// Premium status (Supabase), Google Play Billing (in_app_purchase) and
/// server-side verification (verify-purchase Edge Function via Dio).
class SubscriptionRepo {
  SubscriptionRepo(this._client, this._dio, [InAppPurchase? iap]) : _iapOverride = iap;

  final SupabaseClient _client;
  final Dio _dio;
  final InAppPurchase? _iapOverride;

  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  Future<PremiumStatusModel> fetchStatus(String userId) async {
    try {
      final row = await _client
          .from(ApiEndpoints.profiles)
          .select('is_premium, premium_until, premium_product')
          .eq('id', userId)
          .maybeSingle();
      return row == null ? const PremiumStatusModel() : PremiumStatusModel.fromJson(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;

  Future<bool> storeAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Subscription plans from the store, cheapest first.
  Future<List<ProductDetails>> products() async {
    final res = await _iap.queryProductDetails(PremiumProducts.all);
    if (res.error != null) throw AppException(res.error!.message);
    final list = [...res.productDetails]..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return list;
  }

  /// Opens the store's purchase sheet. The result arrives on [purchases].
  Future<void> buy(ProductDetails product, String userId) async {
    final ok = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product, applicationUserName: userId),
    );
    if (!ok) throw const AppException('The store could not start the purchase.');
  }

  Future<void> restore() => _iap.restorePurchases();

  /// Asks the server to check the purchase with Google and record Premium.
  Future<void> verify(PurchaseDetails purchase) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyPurchase,
        data: {
          'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Tells the store the purchase was handled (acknowledges it on Android).
  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
  }
}
