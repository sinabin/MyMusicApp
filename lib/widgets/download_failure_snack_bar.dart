import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';

/// 다운로드 실패 안내 스낵바 표시 유틸리티.
///
/// [DownloadProvider.lastErrorMessage]의 문구를 검색·디스커버·아티스트 탐색 화면에서
/// 동일한 형태로 노출하기 위해 사용. 성공 스낵바(체크 아이콘)와 시각적으로 대칭.
abstract final class DownloadFailureSnackBar {
  /// [context]의 [ScaffoldMessenger]에 [title] 다운로드 실패와 [message] 원인 표시.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    final cs = AppColorScheme.of(context);
    final headline = title == null ? '다운로드 실패' : '$title 다운로드 실패';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: cs.error, size: AppSizes.iconMd),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$headline · $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
