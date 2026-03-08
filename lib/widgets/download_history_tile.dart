import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../models/download_item.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

class DownloadHistoryTile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onDelete;

  const DownloadHistoryTile({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Music icon
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(
                Icons.music_note,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${FormatUtils.fileSize(item.fileSize)} - ${FormatUtils.date(item.downloadDate)}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                Share.shareXFiles([XFile(item.filePath)]);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}
