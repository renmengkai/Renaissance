// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MusicSourceImpl _$$MusicSourceImplFromJson(Map<String, dynamic> json) =>
    _$MusicSourceImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$MusicSourceTypeEnumMap, json['type']),
      isEnabled: json['isEnabled'] as bool,
      cloudProvider:
          $enumDecodeNullable(_$CloudProviderEnumMap, json['cloudProvider']),
      baseUrl: json['baseUrl'] as String?,
      bucketName: json['bucketName'] as String?,
      customHeaders: json['customHeaders'] as String?,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
      songCount: (json['songCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MusicSourceImplToJson(_$MusicSourceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$MusicSourceTypeEnumMap[instance.type]!,
      'isEnabled': instance.isEnabled,
      'cloudProvider': _$CloudProviderEnumMap[instance.cloudProvider],
      'baseUrl': instance.baseUrl,
      'bucketName': instance.bucketName,
      'customHeaders': instance.customHeaders,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
      'songCount': instance.songCount,
    };

const _$MusicSourceTypeEnumMap = {
  MusicSourceType.local: 'local',
  MusicSourceType.cloud: 'cloud',
};

const _$CloudProviderEnumMap = {
  CloudProvider.qiniu: 'qiniu',
  CloudProvider.aliyun: 'aliyun',
  CloudProvider.tencent: 'tencent',
  CloudProvider.custom: 'custom',
};

_$CloudMusicConfigImpl _$$CloudMusicConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$CloudMusicConfigImpl(
      provider: $enumDecode(_$CloudProviderEnumMap, json['provider']),
      baseUrl: json['baseUrl'] as String,
      bucketName: json['bucketName'] as String?,
      accessKey: json['accessKey'] as String?,
      secretKey: json['secretKey'] as String?,
      region: json['region'] as String?,
      customHeaders: (json['customHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      useHttps: json['useHttps'] as bool? ?? true,
      enableCache: json['enableCache'] as bool? ?? false,
      cacheExpireDays: (json['cacheExpireDays'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$$CloudMusicConfigImplToJson(
        _$CloudMusicConfigImpl instance) =>
    <String, dynamic>{
      'provider': _$CloudProviderEnumMap[instance.provider]!,
      'baseUrl': instance.baseUrl,
      'bucketName': instance.bucketName,
      'accessKey': instance.accessKey,
      'secretKey': instance.secretKey,
      'region': instance.region,
      'customHeaders': instance.customHeaders,
      'useHttps': instance.useHttps,
      'enableCache': instance.enableCache,
      'cacheExpireDays': instance.cacheExpireDays,
    };

_$CloudSongInfoImpl _$$CloudSongInfoImplFromJson(Map<String, dynamic> json) =>
    _$CloudSongInfoImpl(
      key: json['key'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      size: (json['size'] as num?)?.toInt(),
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
      contentType: json['contentType'] as String?,
    );

Map<String, dynamic> _$$CloudSongInfoImplToJson(_$CloudSongInfoImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'url': instance.url,
      'fileName': instance.fileName,
      'size': instance.size,
      'lastModified': instance.lastModified?.toIso8601String(),
      'contentType': instance.contentType,
    };
