import 'package:meta/meta.dart';

class Audio {
  int id;
  int assetId;
  String name;
  String description;
  String absoluteUrl;
  String audioUrl;
  Duration duration;
  int genreId;
  String genreName;
  int libraryId;
  String libraryName;
  int albumId;
  String albumName;
  String albumInfo;
  DateTime createdOn;

  Audio({
    @required this.id,
    @required this.assetId,
    @required this.name,
    @required this.description,
    @required this.absoluteUrl,
    @required this.audioUrl,
    @required this.duration,
    @required this.genreId,
    @required this.genreName,
    @required this.libraryId,
    @required this.libraryName,
    @required this.albumId,
    @required this.albumName,
    @required this.albumInfo,
    @required this.createdOn
  });
}