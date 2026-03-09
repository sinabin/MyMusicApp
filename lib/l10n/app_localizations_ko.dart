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
  String get tabHome => 'Home';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabLibrary => 'Library';

  @override
  String get searchHint => 'Search music...';

  @override
  String get searchFailed => '검색 실패';

  @override
  String get noResults => '결과 없음';

  @override
  String get retry => '다시 시도';

  @override
  String get recentDownloads => 'Recent Downloads';

  @override
  String recentDownloadsCount(int count) {
    return 'Recent Downloads ($count)';
  }

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get seeAll => 'See All >';

  @override
  String get download => 'Download Audio';

  @override
  String get downloadInProgress => '다운로드가 이미 진행 중입니다';

  @override
  String get downloadPreparing => 'Preparing download...';

  @override
  String get downloadComplete => 'Download Complete!';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String downloadSaved(String fileName) {
    return 'Saved: $fileName';
  }

  @override
  String get stream => 'Stream';

  @override
  String get streamFailed => 'Streaming failed';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get addToQueue => '바로 다음에 재생';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get addToPlaylist => '플레이리스트에 추가';

  @override
  String get favorite => '좋아요';

  @override
  String get unfavorite => '좋아요 해제';

  @override
  String get queueTitle => 'Queue';

  @override
  String queueCount(int count) {
    return 'Queue ($count)';
  }

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String get queueEmptyHint => 'Play a song to start your queue';

  @override
  String get libraryTitle => 'My Library';

  @override
  String get librarySubtitle => 'Your music collection';

  @override
  String get favorites => 'Favorites';

  @override
  String get recent => 'Recent';

  @override
  String get allSongs => 'All Songs';

  @override
  String get playlists => 'Playlists';

  @override
  String playlistsCount(int count) {
    return 'Playlists ($count)';
  }

  @override
  String get createPlaylist => 'Create';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String get noPlaylistsHint => 'Tap \"+ Create\" to make your first playlist';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverSubtitle => 'Recommendations based on your downloads';

  @override
  String get forYou => 'For You';

  @override
  String get notInterested => '관심 없음';

  @override
  String get preparingRecommendations => '새로운 추천을 준비 중입니다';

  @override
  String get downloadMoreHint => '더 많은 곡을 다운로드하면 정확한 추천이 가능해요';

  @override
  String get noDownloads => 'No downloads yet';

  @override
  String get noDownloadsHint => 'Your downloaded audio files will appear here';

  @override
  String get noPlays => 'No plays yet';

  @override
  String get noPlaysHint => 'Songs you play will appear here';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesHint => 'Tap the heart icon to add favorites';

  @override
  String get noSongs => 'No songs yet';

  @override
  String get noSongsHint => 'Download songs to build your collection';

  @override
  String get noTrackPlaying => 'No track playing';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Remove this download?';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear all play history?';

  @override
  String get settings => '설정';

  @override
  String get closePlayer => '플레이어 닫기';

  @override
  String get openFullPlayer => '전체 플레이어 열기';

  @override
  String get cancelDownload => '다운로드 취소';

  @override
  String get playQueue => '재생 큐';

  @override
  String downloadCompleteNotification(String title) {
    return '$title 다운로드 완료';
  }

  @override
  String trackCount(int count) {
    return '$count곡';
  }
}
