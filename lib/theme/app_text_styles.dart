import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전역에서 사용하는 텍스트 스타일 정의.
///
/// Google Fonts의 Inter 서체를 기반으로 하며, 색상은 포함하지 않음.
/// 테마의 기본 텍스트 색상(onSurface)을 상속받으며,
/// 필요 시 `.copyWith(color: cs.textSecondary)` 등으로 명시.
/// heroTitle(32) > screenTitle(24) > titleLarge(20) > sectionHeader(18)
/// > buttonText(17) > inputText(16) > subtitle(15) > body(14)
/// > tileTitle(14,w500) > bodySmall(13) > caption(12) > overline(10).
class AppTextStyles {
  AppTextStyles._();

  /// 히어로 영역 대형 타이틀.
  static TextStyle heroTitle = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// 화면 타이틀 (AppBar 등).
  static TextStyle screenTitle = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  /// 대형 타이틀 (전체 플레이어 곡명, 시트 헤더 등).
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// 섹션 헤더.
  static TextStyle sectionHeader = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// 버튼 라벨.
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  /// 텍스트 입력 필드.
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// 부제목·설명.
  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  /// 본문.
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// 타일 항목 제목 (트랙·플레이리스트 타일 등).
  static TextStyle tileTitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// 소형 본문 (리스트 타이틀 등).
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// 캡션·메타 정보.
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// 오버라인·배지 라벨.
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
