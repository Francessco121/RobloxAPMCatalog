import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:js' as js;

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:node_interop/node.dart' as node;
import 'package:uuid/uuid.dart';

import 'interop.dart';
import 'sqlite3.dart';

import 'api/audio.dart';
import 'api/genre.dart';
import 'utils/utils.dart';

@Component(
  selector: 'rac-root-view',
  templateUrl: 'root_view.html',
  styleUrls: ['root_view.css'],
  directives: [
    coreDirectives,
    formDirectives
  ]
)
class RootView implements OnInit, OnDestroy {
  @ViewChild('audioElement')
  html.AudioElement audioElement;

  @ViewChild('scrollContainer')
  html.Element scrollContainer;

  List<Genre> genres = [];
  List<Audio> audios = [];
  int totalAudios = 0;

  bool loading = false;

  int skip = 0;
  static const int take = 50;
  int page = 0;
  int pages = 0;
  bool prevPageDisabled = true;
  bool nextPageDisabled = true;

  Audio selectedAudio;
  int selectedGenre;

  String audioName;
  String audioDescription;
  String albumName;
  String libraryName;
  int minDuration;
  int maxDuration;
  String audioUrl;

  StreamSubscription _loggerSubscription;

  final Client _client;
  final NgZone _zone;

  RootView(this._client, this._zone) {
    // Show all log messages
    Logger.root.level = Level.ALL;

    // Route logger messages to the browser console
    _loggerSubscription = Logger.root.onRecord.listen(_onLogMessage);
  }

  @override
  Future<void> ngOnInit() async {
    await _getGenres();
    await _getAudio();
  }

  @override
  void ngOnDestroy() {
    _loggerSubscription?.cancel();
  }

  void selectAudio(Audio audio) {
    selectedAudio = audio;

    if (audioElement == null) {
      _zone.runAfterChangesObserved(() {
        _handleAudioElement();
        audioElement.volume = 0.1;
      });
    } else {
      audioElement.src = '';
      
      _handleAudioElement();
    }
  }

  Future<void> refresh() async {
    if (loading) return;

    skip = 0;
    await _getAudio();
  }

  Future<void> selectGenre(String genre) async {
    if (loading) return;

    selectedGenre = int.tryParse(genre);
    skip = 0;

    await _getAudio();
  }

  Future<void> searchGenre(int genreId) async {
    if (loading) return;

    selectedGenre = genreId;
    skip = 0;

    await _getAudio();
  }

  Future<void> searchLibrary(String libraryName) async {
    if (loading) return;

    this.libraryName = libraryName;
    skip = 0;

    await _getAudio();
  }

  Future<void> searchAlbum(String albumName) async {
    if (loading) return;

    this.albumName = albumName;
    skip = 0;

    await _getAudio();
  }

  Future<void> nextPage() async {
    if (loading) return;

    skip += take;

    await _getAudio();
  }

  Future<void> prevPage() async {
    if (loading) return;

    skip = math.max(0, skip - take);

    await _getAudio();
  }

  Future<void> randomPage() async {
    if (loading) return;

    final page = math.Random().nextInt(pages);
    skip = page * take;

    await _getAudio();
  }

  Future<void> goToPage(int page) async {
    if (loading || page == null) return;

    final newSkip = math.max(0, math.min(pages - 1, page - 1)) * take;
    if (newSkip == skip) return;

    skip = newSkip;

    await _getAudio();
  }

  Future<void> onPageEntered(html.KeyboardEvent event) async {
    if (event.key == 'Enter') {
      await goToPage(page);
    }
  }

  Future<void> _handleAudioElement() async {
    final audio = selectedAudio;
    final audioId = Uuid().v4();

    // Download the audio temporarily
    final String uri = await downloadTempAudio(
      audio.audioUrl, 
      audioId
    );

    // If the same audio is still selected, load it
    if (selectedAudio == audio) {
      // Delete other audio
      deleteAllTempAudio();

      // Add uri to storage
      storeTempAudioId(audioId);

      // Load and play
      audioElement.src = '$uri?t=${DateTime.now()}';
      audioElement.load();
      await audioElement.play();
    } else {
      deleteTempAudio(audioId);
    }
  }

  void storeTempAudioId(String id) {
    List<String> tempAudioIds = [];

    if (html.window.localStorage.containsKey('temp-audios')) {
      tempAudioIds = json.decode(html.window.localStorage['temp-audios']).cast<String>();
    }

    tempAudioIds.add(id);
    html.window.localStorage['temp-audios'] = json.encode(tempAudioIds);
  }

  void deleteAllTempAudio() {
    if (html.window.localStorage.containsKey('temp-audios')) {
      List<String> tempAudioIds = json.decode(html.window.localStorage['temp-audios']).cast<String>();
      html.window.localStorage['temp-audios'] = json.encode([]);

      for (final String id in tempAudioIds) {
        deleteTempAudio(id);
      }
    }
  }

  Future<String> downloadTempAudio(String url, String uniqueId) async {
    final completer = new Completer<String>();

    js.context.callMethod('downloadTempAudio', [url, uniqueId, js.allowInterop((uri) {
      completer.complete(uri);
    })]);

    return completer.future;
  }

  void deleteTempAudio(String uniqueId) async {
    js.context.callMethod('deleteTempAudio', [uniqueId]);
  }

  Future<void> _getGenres() async {
    loading = true;

    final database = await Database.open('music_catalog.db', openReadonly);

    genres = (await database.all('select * from Genres order by Name'))
      .map((x) => Genre(
        id: x['Id'],
        name: x['Name']
      ))
      .toList();

    await database.close();

    loading = false;
  }

  Future<void> _getAudio() async {
    if (loading) return;

    loading = true;

    final database = await Database.open('music_catalog.db', openReadonly);

    final records = await database.all(
      r'''
        select 
          audio.Id,
          audio.[Name],
          audio.[Description],
          audio.AssetId,
          audio.AbsoluteUrl,
          audio.AudioUrl,
          audio.Duration,
          audio.CreatedOn,
          audio.GenreId,
          audio.AlbumId,
          audio.LibraryId,
          genre.[Name] as GenreName,
          [library].[Name] as LibraryName,
          album.[Name] as AlbumName,
          album.[Description] as AlbumInfo
        from AudioItems as audio
        left join Genres as genre on genre.Id = audio.GenreId
        left join Libraries as [library] on [library].Id = audio.LibraryId
        left join Albums as album on album.Id = audio.AlbumId
        where   (audio.GenreId = @GenreId or @GenreId is null)
            and (album.[Name] like @AlbumName or @AlbumName is null)
            and ([library].[Name] like @LibraryName or @LibraryName is null)
            and (audio.[Name] like @Name or @Name is null)
            and (audio.[Description] like @Description or @Description is null)
            and (audio.Duration >= @MinDuration or @MinDuration is null)
            and (audio.Duration <= @MaxDuration or @MaxDuration is null)
        order by LibraryName, AlbumName, audio.[Name]
        limit @Take
        offset @Skip
      ''',
      {
        '@Skip': skip,
        '@Take': take,
        '@GenreId': selectedGenre,
        '@Name': audioName == null ? null : '%$audioName%',
        '@Description': audioDescription == null ? null : '%$audioDescription%',
        '@AlbumName': albumName == null ? null : '%$albumName%',
        '@LibraryName': libraryName == null ? null : '%$libraryName%',
        '@MinDuration': minDuration,
        '@MaxDuration': maxDuration
      }
    );

    final countRow = await database.get(
      r'''
        select count(*) as Count
        from AudioItems as audio
        left join Libraries as [library] on [library].Id = audio.LibraryId
        left join Albums as album on album.Id = audio.AlbumId
        where   (audio.GenreId = @GenreId or @GenreId is null)
            and (album.[Name] like @AlbumName or @AlbumName is null)
            and ([library].[Name] like @LibraryName or @LibraryName is null)
            and (audio.[Name] like @Name or @Name is null)
            and (audio.[Description] like @Description or @Description is null)
            and (audio.Duration >= @MinDuration or @MinDuration is null)
            and (audio.Duration <= @MaxDuration or @MaxDuration is null)
      ''',
      {
        '@GenreId': selectedGenre,
        '@Name': audioName == null ? null : '%$audioName%',
        '@Description': audioDescription == null ? null : '%$audioDescription%',
        '@AlbumName': albumName == null ? null : '%$albumName%',
        '@LibraryName': libraryName == null ? null : '%$libraryName%',
        '@MinDuration': minDuration,
        '@MaxDuration': maxDuration
      }
    );

    await database.close();

    audios = records
      .map((x) => Audio(
        id: x['Id'],
        assetId: x['AssetId'],
        name: x['Name'],
        description: x['Description'],
        absoluteUrl: x['AbsoluteUrl'],
        audioUrl: x['AudioUrl'],
        albumId: x['AlbumId'],
        albumName: x['AlbumName'],
        albumInfo: x['AlbumInfo'],
        libraryId: x['LibraryId'],
        libraryName: x['LibraryName'],
        genreId: x['GenreId'],
        genreName: x['GenreName'],
        duration: Duration(seconds: x['Duration'] ?? 0),
        createdOn: x['CreatedOn'] == null ? null : DateTime.tryParse(x['CreatedOn'])
      ))
      .toList();

    totalAudios = countRow['Count'] as int;

    prevPageDisabled = skip <= 0;
    nextPageDisabled = skip + take >= totalAudios;
    page = (skip / take).floor() + 1;
    pages = (totalAudios / take).floor() + 1;

    loading = false;
    scrollContainer.scrollTop = 0;

    // Uri uri = Uri.parse('/api/audio').replace(
    //   queryParameters: {
    //     'skip': skip.toString(),
    //     'take': take.toString(),
    //     'genreId': selectedGenre,
    //     'name': audioName,
    //     'description': audioDescription,
    //     'albumName': albumName,
    //     'libraryName': libraryName,
    //     'minDuration': minDuration == null ? null : durationTo24HourString(Duration(seconds: minDuration)),
    //     'maxDuration': maxDuration == null ? null : durationTo24HourString(Duration(seconds: maxDuration))
    //   }
    // );

    // final response = await _http.get(uri);

    // var data = json.decode(response.body);

    // totalAudios = data['total'];

    // audios = data['items']
    //   .cast<Map<String, dynamic>>()
    //   .map((x) => Audio.fromJson(x))
    //   .toList()
    //   .cast<Audio>();

    // prevPageDisabled = skip <= 0;
    // nextPageDisabled = skip + take >= totalAudios;
    // page = (skip / take).floor() + 1;
    // pages = (totalAudios / take).floor() + 1;

    // loading = false;
    // scrollContainer.scrollTop = 0;
  }

  void _onLogMessage(LogRecord record) {
    final buffer = new StringBuffer();

    // Write the prefix
    if (record.loggerName != null) {
      buffer.write('[');
      buffer.write(record.loggerName);
      buffer.write('] ');
    }

    // Write the message
    buffer.write(record.message);

    if (record.stackTrace != null) {
      buffer.write(' Stack trace: ');
      buffer.write(record.stackTrace);
    }

    // Build the message
    final String fullMessage = buffer.toString();

    if (record.level >= Level.SEVERE) {
      html.window.console.error(fullMessage);
    } else if (record.level >= Level.WARNING) {
      html.window.console.warn(fullMessage);
    } else if (record.level >= Level.INFO) {
      html.window.console.info(fullMessage);
    } else {
      html.window.console.debug(fullMessage);
    }
  }
}