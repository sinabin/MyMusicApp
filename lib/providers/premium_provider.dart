import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/settings_provider.dart';
import '../services/premium_service.dart';

/// 프리미엄 구매 상태를 관리하는 Provider.
///
/// [SettingsProvider.settings.isPremium]을 참조하여 UI에 프리미엄 상태를 노출하고,
/// [PremiumService]에 구매·복원 동작을 위임.
class PremiumProvider extends ChangeNotifier {
  final PremiumService _service;
  final SettingsProvider _settingsProvider;

  ProductDetails? _product;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _error;
  bool _disposed = false;

  PremiumProvider({
    required PremiumService service,
    required SettingsProvider settingsProvider,
  })  : _service = service,
        _settingsProvider = settingsProvider {
    _service.onPremiumChanged = (_) {
      _isPurchasing = false;
      _isRestoring = false;
      _error = null;
      notifyListeners();
    };
    _loadProduct();
  }

  /// 프리미엄 구매 여부.
  bool get isPremium => _settingsProvider.settings.isPremium;

  /// 상품 정보.
  ProductDetails? get product => _product;

  /// 구매 진행 중 여부.
  bool get isPurchasing => _isPurchasing;

  /// 복원 진행 중 여부.
  bool get isRestoring => _isRestoring;

  /// 에러 메시지.
  String? get error => _error;

  /// 상품 정보 로드.
  Future<void> _loadProduct() async {
    _product = await _service.loadProduct();
    notifyListeners();
  }

  /// 프리미엄 구매 시작.
  Future<void> purchase() async {
    if (_isPurchasing || isPremium) return;

    if (_product == null) {
      _error = '상품 정보를 불러올 수 없습니다';
      notifyListeners();
      return;
    }

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final started = await _service.buyPremium(_product!);
      if (!started) {
        _isPurchasing = false;
        _error = '구매를 시작할 수 없습니다';
        notifyListeners();
      }
    } catch (e) {
      _isPurchasing = false;
      _error = '구매 중 오류가 발생했습니다';
      debugPrint('[PremiumProvider] Purchase error: $e');
      notifyListeners();
    }
  }

  /// 이전 구매 복원.
  Future<void> restore() async {
    if (_isRestoring) return;

    _isRestoring = true;
    _error = null;
    notifyListeners();

    try {
      await _service.restorePurchases();
      // 복원 결과는 _handlePurchaseUpdate에서 처리
      // 일정 시간 후에도 복원 안되면 자동 해제
      Future.delayed(const Duration(seconds: 10), () {
        if (!_disposed && _isRestoring) {
          _isRestoring = false;
          notifyListeners();
        }
      });
    } catch (e) {
      _isRestoring = false;
      _error = '구매 복원 중 오류가 발생했습니다';
      debugPrint('[PremiumProvider] Restore error: $e');
      notifyListeners();
    }
  }

  /// 디버그용 프리미엄 토글.
  Future<void> debugTogglePremium() async {
    await _settingsProvider.setIsPremium(!isPremium);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
