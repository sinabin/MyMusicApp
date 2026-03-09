// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MyMusicApp';

  @override
  String get tabHome => '홈';

  @override
  String get tabDiscover => '추천';

  @override
  String get tabLibrary => '보관함';

  @override
  String get searchHint => '음악 검색...';

  @override
  String get searchFailed => '검색 실패';

  @override
  String get noResults => '결과 없음';

  @override
  String get retry => '다시 시도';

  @override
  String get recentDownloads => '최근 다운로드';

  @override
  String recentDownloadsCount(int count) {
    return '최근 다운로드 ($count)';
  }

  @override
  String get recentlyPlayed => '최근 재생';

  @override
  String get seeAll => '모두 보기 >';

  @override
  String get download => '오디오 다운로드';

  @override
  String get downloadInProgress => '다운로드가 이미 진행 중입니다';

  @override
  String get downloadPreparing => '다운로드 준비 중...';

  @override
  String get downloadComplete => '다운로드 완료!';

  @override
  String get downloadFailed => '다운로드 실패';

  @override
  String downloadSaved(String fileName) {
    return '저장됨: $fileName';
  }

  @override
  String get stream => '스트리밍';

  @override
  String get streamFailed => '스트리밍 실패';

  @override
  String get play => '재생';

  @override
  String get pause => '일시정지';

  @override
  String get previous => '이전';

  @override
  String get next => '다음';

  @override
  String get shuffle => '셔플';

  @override
  String get repeat => '반복';

  @override
  String get addToQueue => '바로 다음에 재생';

  @override
  String get addedToQueue => '현재 재생리스트에 추가했어요';

  @override
  String get addToPlaylist => '플레이리스트에 추가';

  @override
  String get favorite => '좋아요';

  @override
  String get unfavorite => '좋아요 해제';

  @override
  String get queueTitle => '현재 재생리스트';

  @override
  String queueCount(int count) {
    return '현재 재생리스트 ($count)';
  }

  @override
  String get queueEmpty => '현재 재생리스트가 비어 있어요';

  @override
  String get queueEmptyHint => '곡을 재생하면 여기에 표시돼요';

  @override
  String get libraryTitle => '내 보관함';

  @override
  String get librarySubtitle => '내 음악 컬렉션';

  @override
  String get favorites => '좋아요 목록';

  @override
  String get recent => '최근';

  @override
  String get allSongs => '전체 곡';

  @override
  String get playlists => '플레이리스트';

  @override
  String playlistsCount(int count) {
    return '플레이리스트 ($count)';
  }

  @override
  String get createPlaylist => '만들기';

  @override
  String get noPlaylists => '플레이리스트가 없어요';

  @override
  String get noPlaylistsHint => '\"+ 만들기\"를 눌러 첫 플레이리스트를 만들어보세요';

  @override
  String get discoverTitle => '추천';

  @override
  String get discoverSubtitle => '다운로드한 곡 기반 추천';

  @override
  String get forYou => '맞춤 추천';

  @override
  String get notInterested => '관심 없음';

  @override
  String get preparingRecommendations => '새로운 추천을 준비 중입니다';

  @override
  String get downloadMoreHint => '더 많은 곡을 다운로드하면 정확한 추천이 가능해요';

  @override
  String get noDownloads => '다운로드한 곡이 없어요';

  @override
  String get noDownloadsHint => '다운로드한 곡이 여기에 표시돼요';

  @override
  String get noPlays => '재생 기록이 없어요';

  @override
  String get noPlaysHint => '재생한 곡이 여기에 표시돼요';

  @override
  String get noFavorites => '좋아요한 곡이 없어요';

  @override
  String get noFavoritesHint => '하트를 눌러 좋아요를 추가하세요';

  @override
  String get noSongs => '곡이 없어요';

  @override
  String get noSongsHint => '곡을 다운로드해서 컬렉션을 만들어보세요';

  @override
  String get noTrackPlaying => '재생 중인 곡 없음';

  @override
  String get delete => '삭제';

  @override
  String get deleteConfirm => '이 다운로드를 삭제할까요?';

  @override
  String get cancel => '취소';

  @override
  String get clear => '지우기';

  @override
  String get clearHistory => '기록 삭제';

  @override
  String get clearHistoryConfirm => '모든 재생 기록을 삭제할까요?';

  @override
  String get settings => '설정';

  @override
  String get closePlayer => '플레이어 닫기';

  @override
  String get openFullPlayer => '전체 플레이어 열기';

  @override
  String get cancelDownload => '다운로드 취소';

  @override
  String get playQueue => '현재 재생리스트';

  @override
  String downloadCompleteNotification(String title) {
    return '$title 다운로드 완료';
  }

  @override
  String trackCount(int count) {
    return '$count곡';
  }
}
