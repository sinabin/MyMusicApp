/// 애니메이션 지속 시간 토큰.
///
/// UI 트랜지션, 페이드, 스태거 딜레이 등에 사용.
class AppDurations {
  AppDurations._();

  // ── Base durations ──
  /// 200ms — 빠른 전환 (fadeIn, 상태 변경).
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms — 기본 전환 (패널 열기/닫기, 리스트 아이템).
  static const Duration normal = Duration(milliseconds: 300);

  /// 400ms — 느린 전환 (bounce, elastic).
  static const Duration slow = Duration(milliseconds: 400);

  /// 600ms — 강조 전환 (히어로 슬라이드, 섹션 진입).
  static const Duration emphasis = Duration(milliseconds: 600);

  /// 1200ms — 반복 펄스 (로딩 인디케이터).
  static const Duration pulse = Duration(milliseconds: 1200);

  // ── Stagger delays ──
  /// 30ms — 빠른 스태거 (검색 결과 리스트).
  static const int staggerFastMs = 30;

  /// 50ms — 기본 스태거 (일반 리스트 아이템).
  static const int staggerMs = 50;

  /// 100ms — 느린 스태거 (섹션 간 딜레이).
  static const int staggerSlowMs = 100;

  /// 300ms — 스태거 최대 누적 (빠른 리스트).
  static const int staggerMaxMs = 300;

  /// 500ms — 스태거 최대 누적 (긴 리스트).
  static const int staggerMaxLongMs = 500;
}
