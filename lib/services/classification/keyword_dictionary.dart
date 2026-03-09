import 'package:flutter/material.dart';

/// 음악 분류를 위한 키워드 사전.
///
/// 8개 카테고리별 키워드, 아이콘, 한글 레이블 매핑.
/// [TrackClassifierService]에서 곡 분류 시 참조.
class KeywordDictionary {
  KeywordDictionary._();

  /// 카테고리별 분류 키워드 매핑.
  static const Map<String, List<String>> categories = {
    'workout': [
      'workout', 'gym', 'exercise', 'fitness', 'pump', 'beast', 'grind',
      'run', 'training', 'energy', 'hype', 'intense', 'power',
      '운동', '헬스', '파워', '에너지',
    ],
    'sleep': [
      'sleep', 'lullaby', 'calm', 'ambient', 'relax', 'soothing',
      'peaceful', 'meditation', 'rain', 'asmr', 'white noise', 'gentle',
      '수면', '자장가', '편안', '힐링', '명상',
    ],
    'focus': [
      'focus', 'study', 'concentration', 'lofi', 'lo-fi', 'lo fi',
      'instrumental', 'piano', 'classical', 'jazz', 'bgm', 'productivity',
      '집중', '공부', '피아노', '클래식', '재즈',
    ],
    'commute': [
      'drive', 'driving', 'road', 'commute', 'car', 'morning', 'highway',
      '드라이브', '출퇴근', '아침',
    ],
    'chill': [
      'chill', 'vibe', 'vibes', 'lounge', 'indie', 'acoustic', 'soft',
      'mellow', 'dreamy', 'bossa', 'easy listening',
      '칠', '감성', '어쿠스틱', '인디',
    ],
    'party': [
      'party', 'club', 'dance', 'edm', 'dj', 'bass', 'drop', 'rave',
      'house', 'techno', 'electronic', 'festival', 'remix',
      '파티', '클럽', '댄스', '리믹스',
    ],
    'sad': [
      'sad', 'heartbreak', 'breakup', 'lonely', 'crying', 'miss you',
      'goodbye', 'pain', 'tears', 'sorrow', 'melancholy', 'ballad',
      '이별', '슬픈', '눈물', '그리움', '발라드', '아픔',
    ],
    'happy': [
      'happy', 'joy', 'fun', 'sunshine', 'summer', 'cheerful', 'bright',
      'upbeat', 'feel good', 'positive', 'smile', 'celebration',
      '행복', '기분전환', '신나는', '즐거운', '여름',
    ],
  };

  /// 카테고리별 아이콘 매핑.
  static const Map<String, IconData> categoryIcons = {
    'workout': Icons.fitness_center,
    'sleep': Icons.nightlight_round,
    'focus': Icons.psychology,
    'commute': Icons.directions_car,
    'chill': Icons.spa,
    'party': Icons.celebration,
    'sad': Icons.water_drop,
    'happy': Icons.wb_sunny,
  };

  /// 카테고리별 한글 레이블 매핑.
  static const Map<String, String> categoryLabels = {
    'workout': '운동',
    'sleep': '수면',
    'focus': '집중',
    'commute': '출퇴근',
    'chill': '칠',
    'party': '파티',
    'sad': '감성',
    'happy': '기분전환',
  };
}
