import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/lyrics_db.dart';
import '../models/lyrics_cache.dart';

/// LRCLIB API를 통해 가사를 조회하는 서비스.
///
/// 캐시 우선 조회 후, 미캐싱 시 다단계 폴백 전략으로 API 호출.
/// 결과를 [LyricsDb]에 캐싱.
class LyricsService {
  final LyricsDb _db;
  final http.Client _httpClient;

  LyricsService({required LyricsDb db, http.Client? httpClient})
      : _db = db,
        _httpClient = httpClient ?? http.Client();

  /// 가사 조회. 캐시 우선, 미캐싱 시 API 호출.
  ///
  /// [forceRefresh]가 true이면 캐시를 무시하고 재검색.
  Future<String?> getLyrics({
    required String videoId,
    required String trackName,
    String? artistName,
    bool forceRefresh = false,
  }) async {
    // 캐시 확인 (강제 갱신 시 스킵)
    if (!forceRefresh) {
      final cached = _db.getByVideoId(videoId);
      if (cached != null) {
        if (cached.notFound) return null;
        return cached.plainLyrics;
      }
    }

    // 강제 갱신 시 기존 캐시 제거
    if (forceRefresh) {
      await _db.deleteByVideoId(videoId);
    }

    // 다단계 폴백 검색
    final cleanedTitle = _cleanTitle(trackName);
    final lyrics = await _fetchWithFallback(cleanedTitle, artistName);

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

  /// 다단계 폴백 전략으로 가사 검색.
  ///
  /// 1차: 정제된 제목 + 아티스트 → 2차: "아티스트 - 제목" 분리 →
  /// 3차: 제목만 (아티스트 검증 유지) → 4차: 괄호 제거 후 검색.
  Future<String?> _fetchWithFallback(
    String cleanedTitle,
    String? artistName,
  ) async {
    // 아티스트 후보 목록 (검증용)
    final knownArtists = <String>{
      if (artistName != null && artistName.isNotEmpty) artistName,
    };

    // 1차: 정제된 제목 + 아티스트
    var result = await _searchApi(cleanedTitle,
        queryArtist: artistName, knownArtists: knownArtists);
    if (result != null) return result;

    // 2차: "아티스트 - 제목" 패턴 분리 후 검색
    final separated = _separateArtistTitle(cleanedTitle);
    if (separated != null) {
      final (extractedArtist, extractedTitle) = separated;
      knownArtists.add(extractedArtist);

      // 분리된 제목 + 기존 아티스트
      result = await _searchApi(extractedTitle,
          queryArtist: artistName, knownArtists: knownArtists);
      if (result != null) return result;

      // 분리된 제목 + 분리된 아티스트
      if (extractedArtist != artistName) {
        result = await _searchApi(extractedTitle,
            queryArtist: extractedArtist, knownArtists: knownArtists);
        if (result != null) return result;
      }
    }

    // 3차: 제목만 (API에 아티스트 미포함, 검증은 유지)
    final titleOnly = separated?.$2 ?? cleanedTitle;
    if (artistName != null && artistName.isNotEmpty) {
      result = await _searchApi(titleOnly, knownArtists: knownArtists);
      if (result != null) return result;
    }

    // 4차: 괄호 내용 전부 제거 후 검색
    final stripped = titleOnly
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s*\[[^\]]*\]'), '')
        .trim();
    if (stripped != titleOnly && stripped.isNotEmpty) {
      result = await _searchApi(stripped, knownArtists: knownArtists);
      if (result != null) return result;
    }

    return null;
  }

  /// LRCLIB API 단건 검색.
  ///
  /// [queryArtist]는 API 쿼리에 포함할 아티스트명.
  /// [knownArtists]는 결과 검증용 아티스트 후보 집합.
  /// API 쿼리에 아티스트를 생략해도 결과 검증은 수행.
  Future<String?> _searchApi(
    String trackName, {
    String? queryArtist,
    Set<String> knownArtists = const {},
  }) async {
    try {
      final queryParams = <String, String>{
        'track_name': trackName,
      };
      if (queryArtist != null && queryArtist.isNotEmpty) {
        queryParams['artist_name'] = queryArtist;
      }

      final uri = Uri.https('lrclib.net', '/api/search', queryParams);
      debugPrint('[LyricsService] Searching: $queryParams');
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'MyMusicApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[LyricsService] API returned ${response.statusCode}');
        return null;
      }

      final List<dynamic> results = json.decode(response.body);
      if (results.isEmpty) return null;

      return _pickBestLyrics(results, trackName, knownArtists);
    } catch (e) {
      debugPrint('[LyricsService] API fetch failed: $e');
      return null;
    }
  }

  /// 검색 결과 중 가장 일치하는 가사 선택.
  ///
  /// [knownArtists] 후보 중 하나라도 매칭되는 결과 우선.
  /// 아티스트가 전혀 안 맞으면 null 반환하여 엉뚱한 곡 방지.
  String? _pickBestLyrics(
    List<dynamic> results,
    String trackName,
    Set<String> knownArtists,
  ) {
    String? bestLyrics;
    double bestScore = -1;
    final hasArtistHint = knownArtists.isNotEmpty;

    for (final result in results) {
      final plain = result['plainLyrics'] as String?;
      if (plain == null || plain.isEmpty) continue;

      final resultArtist = (result['artistName'] as String?) ?? '';
      final resultTrack = (result['trackName'] as String?) ?? '';

      double score = 0;

      // 트랙명 유사도
      score += _similarity(resultTrack, trackName) * 2;

      // 아티스트명 유사도 — 후보 중 최고 점수 사용
      if (hasArtistHint) {
        double bestArtistSim = 0;
        for (final known in knownArtists) {
          final sim = _similarity(resultArtist, known);
          if (sim > bestArtistSim) bestArtistSim = sim;
        }
        score += bestArtistSim * 3;

        // 아티스트가 전혀 안 맞으면 강한 감점
        if (bestArtistSim == 0) score -= 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestLyrics = plain;
      }
    }

    // 최소 점수 미달 시 null (엉뚱한 가사 방지)
    if (bestScore < 0) {
      debugPrint('[LyricsService] No matching result (bestScore=$bestScore)');
      return null;
    }

    return bestLyrics;
  }

  /// 두 문자열 간 유사도 (0.0 ~ 1.0).
  double _similarity(String a, String b) {
    final na = _normalize(a);
    final nb = _normalize(b);

    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1.0;
    if (na.contains(nb) || nb.contains(na)) return 0.8;

    // 단어 겹침 비율 (Jaccard)
    final wordsA = na.split(RegExp(r'\s+')).toSet();
    final wordsB = nb.split(RegExp(r'\s+')).toSet();
    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    if (union.isEmpty) return 0;
    return intersection.length / union.length;
  }

  /// 비교용 문자열 정규화.
  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s가-힣]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// "아티스트 - 제목" 패턴 분리.
  ///
  /// " - " 구분자로 분리하여 (아티스트, 제목) 튜플 반환.
  /// 분리 불가 시 null 반환.
  (String, String)? _separateArtistTitle(String title) {
    final idx = title.indexOf(' - ');
    if (idx < 0) return null;

    final artistPart = title.substring(0, idx).trim();
    final titlePart = title.substring(idx + 3).trim();

    if (artistPart.isEmpty || titlePart.isEmpty) return null;

    // 아티스트에서 괄호 별명 제거 (예: "화사 (HWASA)" → "화사")
    final cleanArtist =
        artistPart.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

    return (cleanArtist.isNotEmpty ? cleanArtist : artistPart, titlePart);
  }

  /// YouTube 제목에서 불필요한 접미사·장식 제거.
  String _cleanTitle(String raw) {
    return raw
        // Official 태그 (괄호)
        .replaceAll(
            RegExp(
                r'\(Official\s*(MV|Music\s*Video|Video|Audio|Lyric\s*Video|Visualizer)\)',
                caseSensitive: false),
            '')
        // Official 태그 (대괄호)
        .replaceAll(
            RegExp(
                r'\[Official\s*(MV|Music\s*Video|Video|Audio|Lyric\s*Video|Visualizer)\]',
                caseSensitive: false),
            '')
        // 품질·형식 태그 (대괄호)
        .replaceAll(
            RegExp(r'\[(4K|HD|HQ|MV|M/V|Lyrics?|가사)\]',
                caseSensitive: false),
            '')
        // 품질·형식 태그 (괄호)
        .replaceAll(
            RegExp(r'\((4K|HD|HQ|MV|M/V|Lyrics?|가사)\)',
                caseSensitive: false),
            '')
        // 중국어 괄호
        .replaceAll(RegExp(r'【.*?】'), '')
        // 단독 MV/M/V (괄호 없이 단어 끝에 위치)
        .replaceAll(RegExp(r'\s+(?:MV|M/V)\s*$', caseSensitive: false), '')
        // feat./ft. 구문 제거
        .replaceAll(
            RegExp(r'\s*[\(\[]*\s*(?:feat\.?|ft\.?)\s+[^\)\]]*[\)\]]*',
                caseSensitive: false),
            '')
        // 따옴표 제거 (작은·큰·유니코드)
        .replaceAll(RegExp(r'''['"''""\u201C\u201D\u2018\u2019]'''), '')
        // 후행 구분자
        .replaceAll(RegExp(r'\s*[-|·]\s*$'), '')
        // 공백 정규화
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 리소스 해제.
  void dispose() {
    _httpClient.close();
  }
}
