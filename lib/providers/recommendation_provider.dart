import 'package:flutter/foundation.dart';
import '../data/dismissed_recommendation_db.dart';
import '../models/recommendation.dart';
import '../services/recommendation/recommendation_service.dart';

/// 추천 목록의 상태 관리 및 30분 TTL 캐싱을 담당하는 Provider.
///
/// [RecommendationService]를 통해 추천을 생성하고,
/// [DismissedRecommendationDb]를 통해 dismiss 기록을 관리.
class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _service;
  final DismissedRecommendationDb _dismissedDb;

  List<Recommendation>? _cached;
  DateTime? _cachedAt;
  bool _isLoading = false;
  String? _error;

  static const _cacheTtl = Duration(minutes: 30);

  RecommendationProvider({
    required RecommendationService service,
    required DismissedRecommendationDb dismissedDb,
  })  : _service = service,
        _dismissedDb = dismissedDb;

  /// 로딩 상태.
  bool get isLoading => _isLoading;

  /// 에러 메시지.
  String? get error => _error;

  /// 추천 목록.
  List<Recommendation> get items => _cached ?? [];

  /// 추천 목록 조회. 캐시 유효 시 캐시 반환.
  Future<void> loadRecommendations({bool force = false}) async {
    if (!force && _isCacheValid()) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cached = await _service.buildRecommendations();
      _cachedAt = DateTime.now();
    } catch (e) {
      debugPrint('[RecommendationProvider] Error: $e');
      _error = '추천을 불러올 수 없습니다';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 캐시 무효화. 다음 탭 진입 시 자동 갱신.
  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  /// 현재 리스트에서 특정 videoId 즉시 제거 (낙관적 UI 갱신).
  void removeFromCurrent(String videoId) {
    _cached?.removeWhere((r) => r.videoId == videoId);
    notifyListeners();
  }

  /// 추천 항목 dismiss 처리.
  Future<void> dismiss(String videoId) async {
    await _dismissedDb.add(videoId);
    removeFromCurrent(videoId);
    invalidateCache();
  }

  /// 캐시 유효성 검사.
  bool _isCacheValid() {
    return _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl;
  }
}
