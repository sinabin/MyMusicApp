/// 4px 그리드 기반 여백·간격 토큰.
///
/// 화면 패딩, 위젯 사이 간격, 섹션 구분 등에 사용.
/// [AppSizes]는 컴포넌트 크기, [AppSpacing]은 여백에 특화.
class AppSpacing {
  AppSpacing._();

  /// 2px — 미세 간격 (상태 도트, 텍스트 줄 사이 등).
  static const double xxs = 2;

  /// 4px — 최소 간격 (인접 요소 사이 좁은 여백).
  static const double xs = 4;

  /// 8px — 소형 간격 (관련 요소 간 기본 여백).
  static const double sm = 8;

  /// 12px — 중형 간격 (타일 내부 패딩, 아이콘-텍스트 간격).
  static const double md = 12;

  /// 16px — 대형 간격 (섹션 내부 여백, 카드 패딩).
  static const double lg = 16;

  /// 20px — 시트·모달 내부 여백.
  static const double xl = 20;

  /// 24px — 화면 가장자리 수평 여백.
  static const double xxl = 24;

  /// 32px — 주요 섹션 구분 여백.
  static const double xxxl = 32;

  /// 40px — 대형 영역 구분 (빈 상태 패딩 등).
  static const double xxxxl = 40;

  /// 48px — 히어로 영역 패딩.
  static const double hero = 48;
}
