import 'package:flutter/material.dart';
import 'download_item.dart';

/// 자동 생성 플레이리스트 모델.
///
/// [KeywordDictionary] 기반 분류 결과로 동적 생성.
/// Hive 저장 안 함 (매 실행 시 재생성).
class AutoPlaylist {
  /// 카테고리 식별자 (workout, sleep, focus 등).
  final String category;

  /// 한글 레이블 (운동, 수면, 집중 등).
  final String label;

  /// 카테고리 아이콘.
  final IconData icon;

  /// 분류된 곡 목록.
  final List<DownloadItem> tracks;

  const AutoPlaylist({
    required this.category,
    required this.label,
    required this.icon,
    required this.tracks,
  });
}
