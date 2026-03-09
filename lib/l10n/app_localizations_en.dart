// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

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
  String get searchFailed => 'Search failed';

  @override
  String get noResults => 'No results found';

  @override
  String get retry => 'Retry';

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
  String get downloadInProgress => 'A download is already in progress';

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
  String get addToQueue => 'Play next';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Remove favorite';

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
  String get notInterested => 'Not interested';

  @override
  String get preparingRecommendations => 'Preparing new recommendations';

  @override
  String get downloadMoreHint =>
      'Download more songs for better recommendations';

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
  String get settings => 'Settings';

  @override
  String get closePlayer => 'Close player';

  @override
  String get openFullPlayer => 'Open full player';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get playQueue => 'Play queue';

  @override
  String downloadCompleteNotification(String title) {
    return '$title downloaded';
  }

  @override
  String trackCount(int count) {
    return '$count songs';
  }
}
