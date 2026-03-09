import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color_scheme.dart';
import 'app_colors.dart';

/// Material 테마 구성 제공.
///
/// [AppColors]를 기반으로 다크 테마를 구성하며, 카드·입력 필드·스낵바 등
/// 공통 위젯 테마를 포함.
class AppTheme {
  AppTheme._();

  /// 소형 요소 (썸네일 뱃지, 프로그레스 바 등).
  static const double radiusSm = 8;

  /// 중형 요소 (타일, 카드 내 이미지 등).
  static const double radiusMd = 12;

  /// 대형 요소 (카드, 입력 필드 등).
  static const double radiusLg = 16;

  /// 최대 둥근 요소 (바텀시트 상단 등).
  static const double radiusXl = 24;

  /// Material3 기반 다크 테마 반환.
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: AppColorScheme.dark,
      );

  /// Material3 기반 라이트 테마 반환.
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colorScheme: AppColorScheme.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colorScheme.scaffoldBackground,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colorScheme.primary,
        secondary: colorScheme.secondary,
        surface: colorScheme.surface,
        error: colorScheme.error,
        onPrimary: colorScheme.textPrimary,
        onSecondary: colorScheme.textPrimary,
        onSurface: colorScheme.textPrimary,
        onError: colorScheme.textPrimary,
      ),
      extensions: [colorScheme],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: colorScheme.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: colorScheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        hintStyle: TextStyle(color: colorScheme.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceLight,
        contentTextStyle: TextStyle(color: colorScheme.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: colorScheme.primary, width: 0.5),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primarySurface,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primaryLight);
          }
          return IconThemeData(color: colorScheme.textTertiary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colorScheme.textTertiary,
            fontSize: 12,
          );
        }),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
