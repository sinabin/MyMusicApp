import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../screens/login_webview_screen.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 앱 설정(오디오 품질·저장 경로·YouTube 로그인)을 표시하는 바텀시트 위젯.
///
/// [SettingsProvider]를 구독하여 설정 변경 사항을 실시간 반영.
/// [SettingsBottomSheet.show]를 호출하여 표시.
class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  /// 설정 바텀시트를 모달로 표시.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl,
              AppSpacing.xxxl + MediaQuery.of(context).viewPadding.bottom),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              final cs = AppColorScheme.of(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: AppSizes.handleWidth,
                    height: AppSizes.handleHeight,
                    decoration: BoxDecoration(
                      color: cs.textTertiary,
                      borderRadius: BorderRadius.circular(AppSpacing.xxs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '설정',
                        style: AppTextStyles.titleLarge,
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save location
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, color: cs.textSecondary, size: AppSizes.iconMd),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '저장 위치',
                              style: AppTextStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              settings.settings.savePath.isEmpty
                                  ? '설정되지 않음'
                                  : settings.settings.savePath,
                              style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final path = await FilePicker.platform.getDirectoryPath();
                          if (path != null) {
                            settings.setSavePath(path);
                          }
                        },
                        child: const Text('변경'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: cs.divider),
                  const SizedBox(height: AppSpacing.lg),

                  // Tap play mode
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline,
                          color: cs.textSecondary, size: AppSizes.iconMd),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '탭하여 전체 재생',
                              style: AppTextStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '선택한 곡부터 목록 전체를 이어서 재생',
                              style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.settings.playAllOnTap,
                        onChanged: (value) =>
                            settings.setPlayAllOnTap(value),
                        activeTrackColor: cs.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: cs.divider),
                  const SizedBox(height: AppSpacing.lg),

                  // Theme mode
                  Row(
                    children: [
                      Icon(Icons.palette_outlined,
                          color: cs.textSecondary, size: AppSizes.iconMd),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '테마',
                              style: AppTextStyles.tileTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              _themeModeLabel(settings.settings.themeMode),
                              style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto, size: AppSizes.iconSm),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: AppSizes.iconSm),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: AppSizes.iconSm),
                          ),
                        ],
                        selected: {settings.settings.themeMode},
                        onSelectionChanged: (modes) =>
                            settings.setThemeMode(modes.first),
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: cs.divider),
                  const SizedBox(height: AppSpacing.lg),

                  // YouTube Login
                  _buildLoginSection(context, settings),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '시스템 설정에 따름',
      ThemeMode.light => '라이트 모드',
      ThemeMode.dark => '다크 모드',
    };
  }

  Widget _buildLoginSection(BuildContext context, SettingsProvider settings) {
    final cs = AppColorScheme.of(context);
    final isLoggedIn = settings.settings.isLoggedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLoggedIn ? Icons.check_circle : Icons.account_circle_outlined,
              color: isLoggedIn ? cs.success : cs.textSecondary,
              size: AppSizes.iconMd,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YouTube 로그인',
                    style: AppTextStyles.tileTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isLoggedIn
                        ? settings.settings.userEmail ?? '로그인됨'
                        : '연령 제한 콘텐츠 재생 시 필요',
                    style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: isLoggedIn
              ? OutlinedButton.icon(
                  onPressed: () => settings.logout(),
                  icon: const Icon(Icons.logout, size: AppSizes.iconMsl),
                  label: const Text('로그아웃'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginWebviewScreen(),
                      ),
                    );
                    if (result != null && result['success'] == true) {
                      settings.setLoggedIn(true, email: result['email'] as String?);
                    }
                  },
                  icon: const Icon(Icons.login, size: AppSizes.iconMsl),
                  label: const Text('YouTube 로그인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
        ),
      ],
    );
  }
}
