import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recommendation.dart';
import '../models/video_info.dart';
import '../services/youtube_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// 추천 곡 상세 정보 바텀시트.
///
/// [Recommendation]의 기본 정보를 즉시 표시하고,
/// [YouTubeService]를 통해 추가 메타데이터(아티스트·키워드)를 비동기 로드.
class RecommendationDetailSheet extends StatefulWidget {
  /// 표시할 추천 데이터.
  final Recommendation recommendation;

  /// 다운로드 버튼 콜백.
  final VoidCallback onDownload;

  /// 스트리밍 재생 콜백. 완료 시 Future가 resolve.
  final Future<void> Function()? onStream;

  /// 다운로드 진행 중 여부.
  final bool isDownloading;

  const RecommendationDetailSheet({
    super.key,
    required this.recommendation,
    required this.onDownload,
    this.onStream,
    this.isDownloading = false,
  });

  /// 바텀시트 표시.
  static void show(
    BuildContext context, {
    required Recommendation recommendation,
    required VoidCallback onDownload,
    Future<void> Function()? onStream,
    bool isDownloading = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendationDetailSheet(
        recommendation: recommendation,
        onDownload: onDownload,
        onStream: onStream,
        isDownloading: isDownloading,
      ),
    );
  }

  @override
  State<RecommendationDetailSheet> createState() =>
      _RecommendationDetailSheetState();
}

class _RecommendationDetailSheetState
    extends State<RecommendationDetailSheet> {
  VideoInfo? _videoInfo;
  bool _isLoading = true;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  /// 스트리밍 재생 요청 처리.
  Future<void> _handleStream() async {
    setState(() => _isStreaming = true);
    try {
      await widget.onStream!();
    } finally {
      if (mounted) setState(() => _isStreaming = false);
    }
  }

  /// YouTube API를 통해 추가 메타데이터 조회.
  Future<void> _fetchDetails() async {
    try {
      final yt = context.read<YouTubeService>();
      final info = await yt.fetchVideoInfo(widget.recommendation.videoId);
      if (mounted) {
        setState(() {
          _videoInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.xxs),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: rec.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.music_note,
                          color: AppColors.textTertiary, size: AppSizes.iconHero),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.music_note,
                          color: AppColors.textTertiary, size: AppSizes.iconHero),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 제목
            Text(
              rec.title,
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: 10),

            // 채널명
            _infoRow(Icons.person_outline, rec.channelName),
            const SizedBox(height: AppSpacing.xs),

            // 재생 시간
            if (rec.duration != null) ...[
              _infoRow(Icons.access_time, FormatUtils.duration(rec.duration!)),
              const SizedBox(height: AppSpacing.xs),
            ],

            // 추천 소스
            _infoRow(Icons.auto_awesome, _sourceLabel(rec.source)),
            const SizedBox(height: AppSpacing.sm),

            // 추천 사유 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rec.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),

            // 추가 메타데이터 (비동기 로드)
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: SizedBox(
                    width: AppSizes.indicatorMd,
                    height: AppSizes.indicatorMd,
                    child: const CircularProgressIndicator(
                      strokeWidth: AppSizes.strokeWidth,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (_videoInfo != null) ...[
              if (_videoInfo!.artistName != null) ...[
                _infoRow(Icons.mic_outlined, _videoInfo!.artistName!),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (_videoInfo!.keywords != null &&
                  _videoInfo!.keywords!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildTags(_videoInfo!.keywords!),
              ],
            ],

            const SizedBox(height: AppSpacing.xl),

            // 스트리밍 듣기 버튼
            if (widget.onStream != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isStreaming ? null : _handleStream,
                    icon: _isStreaming
                        ? SizedBox(
                            width: AppSizes.iconMsl,
                            height: AppSizes.iconMsl,
                            child: const CircularProgressIndicator(
                              strokeWidth: AppSizes.strokeWidth,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_circle_outline),
                    label: Text(
                        _isStreaming ? '불러오는 중...' : '스트리밍 듣기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary,
                      disabledBackgroundColor:
                          AppColors.surfaceVariant.withValues(alpha: 0.5),
                      disabledForegroundColor: AppColors.textTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // 다운로드 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isDownloading
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onDownload();
                      },
                icon: widget.isDownloading
                    ? SizedBox(
                        width: AppSizes.iconMsl,
                        height: AppSizes.iconMsl,
                        child: const CircularProgressIndicator(
                          strokeWidth: AppSizes.strokeWidth,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label:
                    Text(widget.isDownloading ? '다운로드 중...' : '다운로드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primaryDark.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 아이콘 + 텍스트 정보 행.
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: AppSizes.iconSm),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// 키워드 태그 목록.
  Widget _buildTags(List<String> keywords) {
    final display = keywords.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tag, color: AppColors.textTertiary, size: AppSizes.iconSm),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '태그',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: display
              .map((tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// 추천 소스 유형의 한글 레이블 반환.
  String _sourceLabel(RecommendationSource source) {
    switch (source) {
      case RecommendationSource.related:
        return '관련 영상 기반 추천';
      case RecommendationSource.channel:
        return '채널 기반 추천';
      case RecommendationSource.search:
        return '검색 기반 추천';
    }
  }
}
