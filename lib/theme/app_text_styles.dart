import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 앱 전역에서 사용하는 텍스트 스타일 정의.
///
/// Google Fonts의 Inter 서체를 기반으로 하며, [AppColors]의 색상을 적용.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heroTitle = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle sectionHeader = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textOnPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}
