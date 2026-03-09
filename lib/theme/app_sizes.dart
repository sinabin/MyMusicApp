/// UI 컴포넌트 크기 토큰.
///
/// 썸네일·아이콘·버튼·플레이어 등 고정 크기 요소에 사용.
/// 여백·간격은 [AppSpacing] 참조.
class AppSizes {
  AppSizes._();

  // ── Thumbnails ──
  /// 40px — 소형 썸네일 (다운로드 이력 타일).
  static const double thumbnailSm = 40;

  /// 44px — 중형 썸네일 (트랙 리스트 타일).
  static const double thumbnailMd = 44;

  /// 56px — 대형 썸네일 (플레이리스트 모자이크 기본).
  static const double thumbnailLg = 56;

  /// 80px — 추천 카드 썸네일.
  static const double thumbnailXl = 80;

  /// 100px — 최근 재생 가로 리스트 아트.
  static const double thumbnailXxl = 100;

  /// 160px — 플레이리스트 상세 히어로 아트.
  static const double thumbnailHero = 160;

  // ── Icons ──
  /// 12px — 극소 아이콘 (뱃지 내 아이콘 등).
  static const double iconXxs = 12;

  /// 14px — 미니 아이콘 (태그 내 아이콘 등).
  static const double iconXs = 14;

  /// 16px — 소형 보조 아이콘.
  static const double iconSm = 16;

  /// 18px — 중소 아이콘 (섹션 헤더 액션 등).
  static const double iconMsl = 18;

  /// 20px — 중형 아이콘 (타일 내 액션 버튼).
  static const double iconMd = 20;

  /// 22px — 중대형 아이콘 (검색 바, CTA 내 아이콘).
  static const double iconMl = 22;

  /// 24px — 대형 아이콘 (AppBar 액션 등).
  static const double iconLg = 24;

  /// 28px — 특대 아이콘 (URL 입력, 플레이어 AppBar).
  static const double iconXl = 28;

  /// 32px — 초대형 아이콘 (헤더 장식, 플레이어 재생).
  static const double iconXxl = 32;

  /// 36px — 플레이어 컨트롤 (이전/다음).
  static const double iconXxxl = 36;

  /// 48px — 빈 상태 아이콘.
  static const double iconHero = 48;

  /// 64px — 빈 상태 대형 아이콘, 플레이어 placeholder.
  static const double iconJumbo = 64;

  /// 80px — 플레이어 placeholder 아이콘.
  static const double iconMega = 80;

  // ── Components ──
  /// 42px — 미니 플레이어 앨범 아트.
  static const double miniPlayerArt = 42;

  /// 48px — 최소 터치 타겟.
  static const double touchTarget = 48;

  /// 52px — 검색 바 높이.
  static const double searchBarHeight = 52;

  /// 56px — 일반 버튼 높이.
  static const double buttonHeight = 56;

  /// 62px — 미니 플레이어 높이.
  static const double miniPlayerHeight = 62;

  /// 80px — 라이브러리 퀵 카드 높이.
  static const double quickCardHeight = 80;

  // ── Player Controls ──
  /// 64px — 재생 버튼 컨테이너.
  static const double playButtonSize = 64;

  // ── SeekBar ──
  /// 4px — 시크 바 트랙 높이.
  static const double seekBarTrackHeight = 4;

  /// 6px — 시크 바 썸 반경.
  static const double seekBarThumbRadius = 6;

  /// 14px — 시크 바 오버레이 반경.
  static const double seekBarOverlayRadius = 14;

  /// 6px — 전체 플레이어 시크 바 트랙 높이.
  static const double seekBarFullTrackHeight = 6;

  /// 8px — 전체 플레이어 시크 바 썸 반경.
  static const double seekBarFullThumbRadius = 8;

  /// 18px — 전체 플레이어 시크 바 오버레이 반경.
  static const double seekBarFullOverlayRadius = 18;

  // ── Video Preview ──
  /// 120px — 비디오 프리뷰 너비.
  static const double videoPreviewWidth = 120;

  /// 68px — 비디오 프리뷰 높이.
  static const double videoPreviewHeight = 68;

  // ── Bottom Sheet Handle ──
  /// 40px — 바텀시트 핸들 바 너비.
  static const double handleWidth = 40;

  /// 4px — 바텀시트 핸들 바 높이.
  static const double handleHeight = 4;

  // ── Header Icon Container ──
  /// 32px — 화면 헤더 아이콘 컨테이너.
  static const double headerIconBox = 32;

  // ── Progress Indicator ──
  /// 2px — 인디케이터 선 두께.
  static const double strokeWidth = 2;

  /// 20px — 소형 인디케이터 크기.
  static const double indicatorSm = 20;

  /// 24px — 중형 인디케이터 크기.
  static const double indicatorMd = 24;

  // ── Misc ──
  /// 110px — 최근 재생 카드 너비.
  static const double recentPlayCardWidth = 110;

  /// 160px — 최근 재생 리스트 높이.
  static const double recentPlayListHeight = 160;

  // ── Search Result Thumbnail ──
  /// 100px — 검색 결과 썸네일 너비.
  static const double searchThumbWidth = 100;

  /// 56px — 검색 결과 썸네일 높이.
  static const double searchThumbHeight = 56;
}
