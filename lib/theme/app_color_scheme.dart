import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 테마별 색상 스킴을 정의하는 ThemeExtension.
///
/// Dark/Light 테마 전환 시 모든 커스텀 색상을 한 번에 교체.
/// [AppColors]의 정적 값은 다크 모드 기본값으로 유지하되,
/// 새로운 코드에서는 `AppColorScheme.of(context).xxx`로 접근.
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color scaffoldBackground;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceLight;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySurface;
  final Color secondary;
  final Color error;
  final Color success;
  final Color warning;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color divider;

  const AppColorScheme({
    required this.scaffoldBackground,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceLight,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySurface,
    required this.secondary,
    required this.error,
    required this.success,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.divider,
  });

  /// 현재 테마에서 [AppColorScheme] 조회.
  static AppColorScheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorScheme>()!;

  /// 다크 테마 색상.
  static const dark = AppColorScheme(
    scaffoldBackground: AppColors.scaffoldBackground,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    surfaceLight: AppColors.surfaceLight,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    primarySurface: AppColors.primarySurface,
    secondary: AppColors.secondary,
    error: AppColors.error,
    success: AppColors.success,
    warning: AppColors.warning,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textDisabled: AppColors.textDisabled,
    border: AppColors.border,
    divider: AppColors.divider,
  );

  /// 라이트 테마 색상.
  static const light = AppColorScheme(
    scaffoldBackground: Color(0xFFF5F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F5),
    surfaceLight: Color(0xFFE8E8F0),
    primary: Color(0xFF7B2FFF),
    primaryDark: Color(0xFF5B1FCC),
    primaryLight: Color(0xFF9D5FFF),
    primarySurface: Color(0xFFEDE0FF),
    secondary: Color(0xFF00A888),
    error: Color(0xFFD32F4C),
    success: Color(0xFF2E7D50),
    warning: Color(0xFFE6A33E),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF5A5A72),
    textTertiary: Color(0xFF8888A0),
    textDisabled: Color(0xFFBBBBCC),
    border: Color(0xFFE0E0EA),
    divider: Color(0xFFEAEAF0),
  );

  @override
  AppColorScheme copyWith({
    Color? scaffoldBackground,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceLight,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primarySurface,
    Color? secondary,
    Color? error,
    Color? success,
    Color? warning,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? divider,
  }) {
    return AppColorScheme(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySurface: primarySurface ?? this.primarySurface,
      secondary: secondary ?? this.secondary,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
