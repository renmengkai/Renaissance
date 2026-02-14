// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      year: (json['year'] as num).toInt(),
      coverUrl: json['coverUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      dominantColor: json['dominantColor'] as String?,
      hasGoldenLetter: json['hasGoldenLetter'] as bool? ?? false,
      sourceType:
          $enumDecodeNullable(_$MusicSourceTypeEnumMap, json['sourceType']) ??
              MusicSourceType.local,
      sourceId: json['sourceId'] as String?,
      cloudKey: json['cloudKey'] as String?,
    );

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'year': instance.year,
      'coverUrl': instance.coverUrl,
      'audioUrl': instance.audioUrl,
      'duration': instance.duration.inMicroseconds,
      'dominantColor': instance.dominantColor,
      'hasGoldenLetter': instance.hasGoldenLetter,
      'sourceType': _$MusicSourceTypeEnumMap[instance.sourceType]!,
      'sourceId': instance.sourceId,
      'cloudKey': instance.cloudKey,
    };

const _$MusicSourceTypeEnumMap = {
  MusicSourceType.local: 'local',
  MusicSourceType.cloud: 'cloud',
  MusicSourceType.webdav: 'webdav',
};
