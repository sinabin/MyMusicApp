import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 플레이리스트 대표 이미지 2x2 모자이크 위젯.
///
/// 곡 수에 따라 1~4장의 썸네일을 배치하며,
/// [PlaylistTile](56x56)과 [PlaylistDetailScreen](160x160)에서 공유.
class PlaylistMosaicArt extends StatelessWidget {
  /// 썸네일 URL 목록 (null 허용).
  final List<String?> thumbnailUrls;

  /// 위젯 크기 (정사각형).
  final double size;

  /// 모서리 반경.
  final double borderRadius;

  const PlaylistMosaicArt({
    super.key,
    required this.thumbnailUrls,
    this.size = 56,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final urls = thumbnailUrls.where((u) => u != null).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: urls.isEmpty ? _placeholder() : _buildGrid(urls),
      ),
    );
  }

  Widget _buildGrid(List<String?> urls) {
    if (urls.length == 1) {
      return _imageOrPlaceholder(urls[0]);
    }

    final half = size / 2;
    final cells = <Widget>[];
    for (int i = 0; i < 4; i++) {
      if (i < urls.length) {
        cells.add(SizedBox(
          width: half,
          height: half,
          child: _imageOrPlaceholder(urls[i]),
        ));
      } else {
        cells.add(SizedBox(
          width: half,
          height: half,
          child: Container(color: AppColors.primarySurface),
        ));
      }
    }

    return Wrap(children: cells);
  }

  Widget _imageOrPlaceholder(String? url) {
    if (url == null) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primarySurface,
      child: Icon(
        Icons.music_note,
        color: AppColors.primaryLight,
        size: size * 0.4,
      ),
    );
  }
}
