import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/video_info.dart';
import '../theme/app_colors.dart';

class VideoPreviewCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoPreviewCard({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: videoInfo.thumbnailUrl,
                width: 120,
                height: 68,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceVariant,
                  highlightColor: AppColors.surfaceLight,
                  child: Container(
                    width: 120,
                    height: 68,
                    color: AppColors.surfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 68,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.music_note, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    videoInfo.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(Icons.access_time, videoInfo.formattedDuration),
                      const SizedBox(width: 8),
                      _chip(Icons.audiotrack, 'Audio'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPreviewShimmer extends StatelessWidget {
  const VideoPreviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.surfaceLight,
          child: Row(
            children: [
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: AppColors.surfaceVariant),
                    const SizedBox(height: 6),
                    Container(height: 14, width: 120, color: AppColors.surfaceVariant),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 80, color: AppColors.surfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
