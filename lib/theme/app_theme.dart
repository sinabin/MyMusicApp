import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Material 테마 구성 제공.
///
/// [AppColors]를 기반으로 다크 테마를 구성하며, 카드·입력 필드·스낵바 등
/// 공통 위젯 테마를 포함.
class AppTheme {
  AppTheme._();

  /// Material3 기반 다크 테마 반환.
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 0.5),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySurface,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryLight);
        }
        return const IconThemeData(color: AppColors.textTertiary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        );
      }),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
