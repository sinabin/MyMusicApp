import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../screens/login_webview_screen.dart';
import '../theme/app_colors.dart';

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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 32 + MediaQuery.of(context).viewPadding.bottom),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save location
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Save Location',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.settings.savePath.isEmpty
                                  ? 'Not set'
                                  : settings.settings.savePath,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
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
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Tap play mode
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Play All on Tap',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Play all tracks starting from tapped song',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.settings.playAllOnTap,
                        onChanged: (value) =>
                            settings.setPlayAllOnTap(value),
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

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

  Widget _buildLoginSection(BuildContext context, SettingsProvider settings) {
    final isLoggedIn = settings.settings.isLoggedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLoggedIn ? Icons.check_circle : Icons.account_circle_outlined,
              color: isLoggedIn ? AppColors.success : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YouTube Login',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoggedIn
                        ? settings.settings.userEmail ?? 'Logged in'
                        : 'Required for age-restricted content',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: isLoggedIn
              ? OutlinedButton.icon(
                  onPressed: () => settings.logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('YouTube Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
        ),
      ],
    );
  }
}
