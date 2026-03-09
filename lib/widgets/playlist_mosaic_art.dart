import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_theme.dart';

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
    this.size = AppSizes.thumbnailLg,
    this.borderRadius = AppTheme.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final urls = thumbnailUrls.where((u) => u != null).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: urls.isEmpty ? _placeholder(context) : _buildGrid(context, urls),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<String?> urls) {
    if (urls.length == 1) {
      return _imageOrPlaceholder(context, urls[0]);
    }

    final half = size / 2;
    final cells = <Widget>[];
    for (int i = 0; i < 4; i++) {
      if (i < urls.length) {
        cells.add(SizedBox(
          width: half,
          height: half,
          child: _imageOrPlaceholder(context, urls[i]),
        ));
      } else {
        cells.add(SizedBox(
          width: half,
          height: half,
          child: _placeholder(context),
        ));
      }
    }

    return Wrap(children: cells);
  }

  /// 로컬 파일 우선, 네트워크 URL 폴백으로 썸네일 반환.
  Widget _imageOrPlaceholder(BuildContext context, String? url) {
    if (url == null) return _placeholder(context);
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(context),
      errorWidget: (_, _, _) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      color: cs.primarySurface,
      child: Icon(
        Icons.music_note,
        color: cs.primaryLight,
        size: size * 0.4,
      ),
    );
  }
}
