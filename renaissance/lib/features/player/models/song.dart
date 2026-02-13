import 'package:freezed_annotation/freezed_annotation.dart';
import 'music_source.dart';

part 'song.freezed.dart';
part 'song.g.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String album,
    required int year,
    required String coverUrl,
    required String audioUrl,
    required Duration duration,
    String? dominantColor,
    @Default(false) bool hasGoldenLetter,
    @Default(MusicSourceType.local) MusicSourceType sourceType,
    String? sourceId,
    String? cloudKey,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

// 歌曲数据列表
final List<Song> sampleSongs = [];
