import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/lyrics_db.dart';
import '../models/lyrics_cache.dart';

/// LRCLIB API를 통해 가사를 조회하는 서비스.
///
/// 캐시 우선 조회 후, 미캐싱 시 API 호출. 결과를 [LyricsDb]에 캐싱.
class LyricsService {
  final LyricsDb _db;
  final http.Client _httpClient;

  LyricsService({required LyricsDb db, http.Client? httpClient})
      : _db = db,
        _httpClient = httpClient ?? http.Client();

  /// 가사 조회. 캐시 우선, 미캐싱 시 API 호출.
  Future<String?> getLyrics({
    required String videoId,
    required String trackName,
    String? artistName,
  }) async {
    // 캐시 확인
    final cached = _db.getByVideoId(videoId);
    if (cached != null) {
      if (cached.notFound) return null;
      return cached.plainLyrics;
    }

    // API 조회
    final cleanedTitle = _cleanTitle(trackName);
    final lyrics = await _fetchFromApi(cleanedTitle, artistName);

    // 캐싱
    await _db.save(LyricsCache(
      videoId: videoId,
      trackName: cleanedTitle,
      artistName: artistName,
      plainLyrics: lyrics,
      notFound: lyrics == null,
    ));

    return lyrics;
  }

  /// LRCLIB API에서 가사 검색.
  Future<String?> _fetchFromApi(String trackName, String? artistName) async {
    try {
      final queryParams = <String, String>{
        'track_name': trackName,
      };
      if (artistName != null && artistName.isNotEmpty) {
        queryParams['artist_name'] = artistName;
      }

      final uri = Uri.https('lrclib.net', '/api/search', queryParams);
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'MyMusicApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[LyricsService] API returned ${response.statusCode}');
        return null;
      }

      final List<dynamic> results = json.decode(response.body);
      if (results.isEmpty) return null;

      // 첫 번째 결과에서 plainLyrics 추출
      for (final result in results) {
        final plain = result['plainLyrics'] as String?;
        if (plain != null && plain.isNotEmpty) {
          return plain;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[LyricsService] API fetch failed: $e');
      return null;
    }
  }

  /// YouTube 제목에서 불필요한 접미사 제거.
  String _cleanTitle(String raw) {
    return raw
        .replaceAll(
            RegExp(
                r'\(Official\s*(MV|Music\s*Video|Video|Audio|Lyric\s*Video|Visualizer)\)',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(
                r'\[Official\s*(MV|Music\s*Video|Video|Audio|Lyric\s*Video|Visualizer)\]',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'\[(4K|HD|HQ|MV|M/V|Lyrics?|가사)\]',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'\((4K|HD|HQ|MV|M/V|Lyrics?|가사)\)',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'【.*?】'), '')
        .replaceAll(RegExp(r'\s*[-|·]\s*$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 리소스 해제.
  void dispose() {
    _httpClient.close();
  }
}
