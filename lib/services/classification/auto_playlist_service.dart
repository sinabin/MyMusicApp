import 'package:flutter/material.dart';

import '../../models/auto_playlist.dart';
import '../../models/download_item.dart';
import 'keyword_dictionary.dart';
import 'track_classifier_service.dart';

/// 자동 플레이리스트를 생성하는 서비스.
///
/// [TrackClassifierService]의 분류 결과에서 3곡 이상 카테고리만
/// [AutoPlaylist]로 변환.
class AutoPlaylistService {
  final TrackClassifierService _classifier;

  AutoPlaylistService(this._classifier);

  /// 다운로드 목록에서 자동 플레이리스트 생성. 3곡 이상 카테고리만 반환.
  List<AutoPlaylist> generatePlaylists(List<DownloadItem> items) {
    final classified = _classifier.classifyAll(items);
    final playlists = <AutoPlaylist>[];

    for (final entry in classified.entries) {
      if (entry.value.length >= 3) {
        final category = entry.key;
        playlists.add(AutoPlaylist(
          category: category,
          label: KeywordDictionary.categoryLabels[category] ?? category,
          icon: KeywordDictionary.categoryIcons[category] ?? Icons.music_note,
          tracks: entry.value,
        ));
      }
    }

    // 곡 수 내림차순 정렬
    playlists.sort((a, b) => b.tracks.length.compareTo(a.tracks.length));
    return playlists;
  }
}
