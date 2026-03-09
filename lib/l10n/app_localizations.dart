import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L? of(BuildContext context) {
    return Localizations.of<L>(context, L);
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'MyMusicApp'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ko, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabDiscover.
  ///
  /// In ko, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabLibrary.
  ///
  /// In ko, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'Search music...'**
  String get searchHint;

  /// No description provided for @searchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색 실패'**
  String get searchFailed;

  /// No description provided for @noResults.
  ///
  /// In ko, this message translates to:
  /// **'결과 없음'**
  String get noResults;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @recentDownloads.
  ///
  /// In ko, this message translates to:
  /// **'Recent Downloads'**
  String get recentDownloads;

  /// No description provided for @recentDownloadsCount.
  ///
  /// In ko, this message translates to:
  /// **'Recent Downloads ({count})'**
  String recentDownloadsCount(int count);

  /// No description provided for @recentlyPlayed.
  ///
  /// In ko, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @seeAll.
  ///
  /// In ko, this message translates to:
  /// **'See All >'**
  String get seeAll;

  /// No description provided for @download.
  ///
  /// In ko, this message translates to:
  /// **'Download Audio'**
  String get download;

  /// No description provided for @downloadInProgress.
  ///
  /// In ko, this message translates to:
  /// **'다운로드가 이미 진행 중입니다'**
  String get downloadInProgress;

  /// No description provided for @downloadPreparing.
  ///
  /// In ko, this message translates to:
  /// **'Preparing download...'**
  String get downloadPreparing;

  /// No description provided for @downloadComplete.
  ///
  /// In ko, this message translates to:
  /// **'Download Complete!'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadSaved.
  ///
  /// In ko, this message translates to:
  /// **'Saved: {fileName}'**
  String downloadSaved(String fileName);

  /// No description provided for @stream.
  ///
  /// In ko, this message translates to:
  /// **'Stream'**
  String get stream;

  /// No description provided for @streamFailed.
  ///
  /// In ko, this message translates to:
  /// **'Streaming failed'**
  String get streamFailed;

  /// No description provided for @play.
  ///
  /// In ko, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ko, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @previous.
  ///
  /// In ko, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @shuffle.
  ///
  /// In ko, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In ko, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @addToQueue.
  ///
  /// In ko, this message translates to:
  /// **'바로 다음에 재생'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In ko, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @addToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'플레이리스트에 추가'**
  String get addToPlaylist;

  /// No description provided for @favorite.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 해제'**
  String get unfavorite;

  /// No description provided for @queueTitle.
  ///
  /// In ko, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueCount.
  ///
  /// In ko, this message translates to:
  /// **'Queue ({count})'**
  String queueCount(int count);

  /// No description provided for @queueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'Queue is empty'**
  String get queueEmpty;

  /// No description provided for @queueEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'Play a song to start your queue'**
  String get queueEmptyHint;

  /// No description provided for @libraryTitle.
  ///
  /// In ko, this message translates to:
  /// **'My Library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Your music collection'**
  String get librarySubtitle;

  /// No description provided for @favorites.
  ///
  /// In ko, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In ko, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @allSongs.
  ///
  /// In ko, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// No description provided for @playlists.
  ///
  /// In ko, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @playlistsCount.
  ///
  /// In ko, this message translates to:
  /// **'Playlists ({count})'**
  String playlistsCount(int count);

  /// No description provided for @createPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'Create'**
  String get createPlaylist;

  /// No description provided for @noPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylists;

  /// No description provided for @noPlaylistsHint.
  ///
  /// In ko, this message translates to:
  /// **'Tap \"+ Create\" to make your first playlist'**
  String get noPlaylistsHint;

  /// No description provided for @discoverTitle.
  ///
  /// In ko, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Recommendations based on your downloads'**
  String get discoverSubtitle;

  /// No description provided for @forYou.
  ///
  /// In ko, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @notInterested.
  ///
  /// In ko, this message translates to:
  /// **'관심 없음'**
  String get notInterested;

  /// No description provided for @preparingRecommendations.
  ///
  /// In ko, this message translates to:
  /// **'새로운 추천을 준비 중입니다'**
  String get preparingRecommendations;

  /// No description provided for @downloadMoreHint.
  ///
  /// In ko, this message translates to:
  /// **'더 많은 곡을 다운로드하면 정확한 추천이 가능해요'**
  String get downloadMoreHint;

  /// No description provided for @noDownloads.
  ///
  /// In ko, this message translates to:
  /// **'No downloads yet'**
  String get noDownloads;

  /// No description provided for @noDownloadsHint.
  ///
  /// In ko, this message translates to:
  /// **'Your downloaded audio files will appear here'**
  String get noDownloadsHint;

  /// No description provided for @noPlays.
  ///
  /// In ko, this message translates to:
  /// **'No plays yet'**
  String get noPlays;

  /// No description provided for @noPlaysHint.
  ///
  /// In ko, this message translates to:
  /// **'Songs you play will appear here'**
  String get noPlaysHint;

  /// No description provided for @noFavorites.
  ///
  /// In ko, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesHint.
  ///
  /// In ko, this message translates to:
  /// **'Tap the heart icon to add favorites'**
  String get noFavoritesHint;

  /// No description provided for @noSongs.
  ///
  /// In ko, this message translates to:
  /// **'No songs yet'**
  String get noSongs;

  /// No description provided for @noSongsHint.
  ///
  /// In ko, this message translates to:
  /// **'Download songs to build your collection'**
  String get noSongsHint;

  /// No description provided for @noTrackPlaying.
  ///
  /// In ko, this message translates to:
  /// **'No track playing'**
  String get noTrackPlaying;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'Remove this download?'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In ko, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearHistory.
  ///
  /// In ko, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In ko, this message translates to:
  /// **'Are you sure you want to clear all play history?'**
  String get clearHistoryConfirm;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @closePlayer.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 닫기'**
  String get closePlayer;

  /// No description provided for @openFullPlayer.
  ///
  /// In ko, this message translates to:
  /// **'전체 플레이어 열기'**
  String get openFullPlayer;

  /// No description provided for @cancelDownload.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 취소'**
  String get cancelDownload;

  /// No description provided for @playQueue.
  ///
  /// In ko, this message translates to:
  /// **'재생 큐'**
  String get playQueue;

  /// No description provided for @downloadCompleteNotification.
  ///
  /// In ko, this message translates to:
  /// **'{title} 다운로드 완료'**
  String downloadCompleteNotification(String title);

  /// No description provided for @trackCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡'**
  String trackCount(int count);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ko':
      return LKo();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
