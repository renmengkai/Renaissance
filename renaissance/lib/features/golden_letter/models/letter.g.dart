// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoldenLetterImpl _$$GoldenLetterImplFromJson(Map<String, dynamic> json) =>
    _$GoldenLetterImpl(
      id: json['id'] as String,
      songId: json['songId'] as String,
      content: json['content'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      location: json['location'] as String?,
      listenCount: (json['listenCount'] as num?)?.toInt(),
      mood: json['mood'] as String?,
    );

Map<String, dynamic> _$$GoldenLetterImplToJson(_$GoldenLetterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'songId': instance.songId,
      'content': instance.content,
      'authorName': instance.authorName,
      'createdAt': instance.createdAt.toIso8601String(),
      'location': instance.location,
      'listenCount': instance.listenCount,
      'mood': instance.mood,
    };
