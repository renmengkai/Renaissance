import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_source.freezed.dart';
part 'music_source.g.dart';

enum MusicSourceType {
  local,
  cloud,
}

enum CloudProvider {
  qiniu,
  aliyun,
  tencent,
  custom,
}

@freezed
class MusicSource with _$MusicSource {
  const factory MusicSource({
    required String id,
    required String name,
    required MusicSourceType type,
    required bool isEnabled,
    CloudProvider? cloudProvider,
    String? baseUrl,
    String? bucketName,
    String? customHeaders,
    DateTime? lastSyncTime,
    @Default(0) int songCount,
  }) = _MusicSource;

  factory MusicSource.fromJson(Map<String, dynamic> json) =>
      _$MusicSourceFromJson(json);
}

@freezed
class CloudMusicConfig with _$CloudMusicConfig {
  const factory CloudMusicConfig({
    required CloudProvider provider,
    required String baseUrl,
    String? bucketName,
    String? accessKey,
    String? secretKey,
    String? region,
    Map<String, String>? customHeaders,
    @Default(true) bool useHttps,
    @Default(false) bool enableCache,
    @Default(30) int cacheExpireDays,
  }) = _CloudMusicConfig;

  factory CloudMusicConfig.fromJson(Map<String, dynamic> json) =>
      _$CloudMusicConfigFromJson(json);
}

@freezed
class CloudSongInfo with _$CloudSongInfo {
  const factory CloudSongInfo({
    required String key,
    required String url,
    required String fileName,
    int? size,
    DateTime? lastModified,
    String? contentType,
  }) = _CloudSongInfo;

  factory CloudSongInfo.fromJson(Map<String, dynamic> json) =>
      _$CloudSongInfoFromJson(json);
}

class CloudProviderHelper {
  static String getDisplayName(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return '七牛云';
      case CloudProvider.aliyun:
        return '阿里云 OSS';
      case CloudProvider.tencent:
        return '腾讯云 COS';
      case CloudProvider.custom:
        return '自定义云存储';
    }
  }

  static String getExampleUrl(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'http://xxx.sabkt.gdipper.com';
      case CloudProvider.aliyun:
        return 'https://oss-cn-hangzhou.aliyuncs.com';
      case CloudProvider.tencent:
        return 'https://cos.ap-guangzhou.myqcloud.com';
      case CloudProvider.custom:
        return 'https://your-cdn.example.com';
    }
  }

  static CloudProvider detectProviderFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('qiniu') ||
        lowerUrl.contains('gdipper') ||
        lowerUrl.contains('clouddn.com') ||
        lowerUrl.contains('qiniudn.com')) {
      return CloudProvider.qiniu;
    } else if (lowerUrl.contains('aliyun') || lowerUrl.contains('oss-cn')) {
      return CloudProvider.aliyun;
    } else if (lowerUrl.contains('myqcloud') || lowerUrl.contains('cos.')) {
      return CloudProvider.tencent;
    }
    return CloudProvider.custom;
  }
}
