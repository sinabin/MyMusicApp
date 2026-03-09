import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/playlist_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 새 플레이리스트 생성 바텀시트.
///
/// 이름과 설명을 입력받아 [PlaylistProvider.createPlaylist] 호출.
/// [CreatePlaylistSheet.show]로 표시.
class CreatePlaylistSheet extends StatefulWidget {
  const CreatePlaylistSheet({super.key});

  /// 바텀시트를 모달로 표시.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePlaylistSheet(),
    );
  }

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact();
    final desc = _descController.text.trim();

    try {
      await context.read<PlaylistProvider>().createPlaylist(
            name,
            description: desc.isEmpty ? null : desc,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl,
              AppSpacing.xxxl + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: cs.textTertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.xxs),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Playlist',
                    style: AppTextStyles.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // 이름 입력
              TextField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(color: cs.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: cs.textTertiary),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              // 설명 입력
              TextField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(color: cs.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: TextStyle(color: cs.textTertiary),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // 생성 버튼
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _nameController.text.trim().isNotEmpty
                        ? AppColors.primaryGradient
                        : null,
                    color: _nameController.text.trim().isEmpty
                        ? cs.surfaceVariant
                        : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isNotEmpty
                        ? _create
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
