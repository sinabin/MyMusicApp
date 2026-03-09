import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/local_storage.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

/// Google Play IAP를 래핑하는 프리미엄 구매 서비스.
///
/// 구매 스트림을 구독하여 구매 완료 시 [SettingsProvider.setIsPremium]을 호출하고
/// [LocalStorage]에 상태를 영속 저장.
class PremiumService {
  final LocalStorage _localStorage;
  final SettingsProvider _settingsProvider;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 프리미엄 상태 변경 콜백.
  Function(bool)? onPremiumChanged;

  PremiumService({
    required LocalStorage localStorage,
    required SettingsProvider settingsProvider,
  })  : _localStorage = localStorage,
        _settingsProvider = settingsProvider;

  /// 구매 스트림 구독 시작.
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PremiumService] IAP not available');
      return;
    }

    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('[PremiumService] Purchase stream error: $e'),
    );
  }

  /// 프리미엄 상품 정보 조회.
  Future<ProductDetails?> loadProduct() async {
    final available = await _iap.isAvailable();
    if (!available) return null;

    final response = await _iap.queryProductDetails(
      {AppConstants.premiumProductId},
    );

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[PremiumService] Product not found: ${response.notFoundIDs}');
      return null;
    }

    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  /// 프리미엄 구매 시작.
  Future<bool> buyPremium(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 이전 구매 복원 (재설치 대응).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// 구매 상태 변경 처리.
  Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // 구매 완료 처리
        await _localStorage.setIsPremium(true);
        await _settingsProvider.setIsPremium(true);
        onPremiumChanged?.call(true);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[PremiumService] Purchase error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint('[PremiumService] Purchase pending');
      }
    }
  }

  /// 리소스 해제.
  void dispose() {
    _subscription?.cancel();
  }
}
