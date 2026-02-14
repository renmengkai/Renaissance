import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_source.freezed.dart';
part 'music_source.g.dart';

enum MusicSourceType {
  local,
  cloud,
  webdav,
}

enum CloudProvider {
  qiniu,
  aliyun,
  tencent,
  xunlei,
  custom,
}

enum WebDAVProvider {
  aliyunDrive,
  teambition,
  terabox,
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
    WebDAVProvider? webdavProvider,
    String? baseUrl,
    String? customDomain,
    String? bucketName,
    String? accessKey,
    String? secretKey,
    String? region,
    String? customHeaders,
    String? webdavPath,
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
    String? customDomain,
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
      case CloudProvider.xunlei:
        return '迅雷云盘';
      case CloudProvider.custom:
        return '自定义云存储';
    }
  }

  static String getExampleUrl(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'https://bucket-name.s3.region.qiniucs.com';
      case CloudProvider.aliyun:
        return 'https://oss-cn-hangzhou.aliyuncs.com';
      case CloudProvider.tencent:
        return 'https://cos.ap-guangzhou.myqcloud.com';
      case CloudProvider.xunlei:
        return 'https://xlyunapi.xunlei.com';
      case CloudProvider.custom:
        return 'https://your-cdn.example.com';
    }
  }

  static String getExampleBucket(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'bucket-name';
      case CloudProvider.aliyun:
        return 'your-bucket-name';
      case CloudProvider.tencent:
        return 'your-bucket-name';
      case CloudProvider.xunlei:
        return 'personal';
      case CloudProvider.custom:
        return 'your-bucket-name';
    }
  }

  static String getExampleRegion(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'region';
      case CloudProvider.aliyun:
        return 'cn-hangzhou';
      case CloudProvider.tencent:
        return 'ap-guangzhou';
      case CloudProvider.xunlei:
        return 'cn';
      case CloudProvider.custom:
        return 'auto';
    }
  }

  static CloudProvider detectProviderFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('qiniu') ||
        lowerUrl.contains('gdipper') ||
        lowerUrl.contains('clouddn.com') ||
        lowerUrl.contains('qiniudn.com') ||
        lowerUrl.contains('qiniucs.com')) {
      return CloudProvider.qiniu;
    } else if (lowerUrl.contains('aliyun') || lowerUrl.contains('oss-cn')) {
      return CloudProvider.aliyun;
    } else if (lowerUrl.contains('myqcloud') || lowerUrl.contains('cos.')) {
      return CloudProvider.tencent;
    } else if (lowerUrl.contains('xunlei') || lowerUrl.contains('xlyunapi')) {
      return CloudProvider.xunlei;
    }
    return CloudProvider.custom;
  }

  static bool requiresAuth(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
      case CloudProvider.aliyun:
      case CloudProvider.tencent:
      case CloudProvider.xunlei:
        return true;
      case CloudProvider.custom:
        return false;
    }
  }

  static String getOfficialWebsite(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'https://www.qiniu.com';
      case CloudProvider.aliyun:
        return 'https://www.aliyun.com/product/oss';
      case CloudProvider.tencent:
        return 'https://cloud.tencent.com/product/cos';
      case CloudProvider.xunlei:
        return 'https://www.xunlei.com';
      case CloudProvider.custom:
        return '';
    }
  }

  static String getAuthGuide(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.qiniu:
        return 'AccessKey 和 SecretKey 可在七牛云控制台 → 个人中心 → 密钥管理中获取';
      case CloudProvider.aliyun:
        return 'AccessKey 和 SecretKey 可在阿里云控制台 → 头像 → AccessKey 管理中获取';
      case CloudProvider.tencent:
        return 'AccessKey 和 SecretKey 可在腾讯云控制台 → 访问管理 → 密钥管理中获取';
      case CloudProvider.xunlei:
        return 'AccessKey 和 SecretKey 可在迅雷云盘开发者平台获取';
      case CloudProvider.custom:
        return '根据自定义云存储服务商的指引获取认证信息';
    }
  }

  /// 从S3端点URL解析存储桶和区域信息
  /// 支持格式：
  /// - 七牛云: https://bucket-name.s3.region.qiniucs.com
  /// - 阿里云: https://bucket-name.oss-region.aliyuncs.com 或 https://oss-region.aliyuncs.com/bucket-name
  /// - 腾讯云: https://bucket-name.cos.region.myqcloud.com 或 https://cos.region.myqcloud.com/bucket-name
  /// - 虚拟主机格式: https://bucket-name.s3.region.provider.com
  static ({String? bucket, String? region}) parseBucketAndRegionFromUrl(String url) {
    if (url.isEmpty) return (bucket: null, region: null);

    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      String? bucket;
      String? region;

      // 七牛云格式: bucket-name.s3.region.qiniucs.com
      if (host.contains('qiniucs.com') || host.contains('qiniu')) {
        final parts = host.split('.');
        if (parts.length >= 4) {
          // 查找 s3 的位置
          final s3Index = parts.indexOf('s3');
          if (s3Index > 0 && s3Index + 1 < parts.length) {
            bucket = parts.sublist(0, s3Index).join('.');
            region = parts[s3Index + 1];
          } else if (parts.length >= 4) {
            // 尝试其他格式: bucket.s3.region.xxx.com
            bucket = parts[0];
            region = parts[2];
          }
        }
      }
      // 阿里云格式: bucket-name.oss-region.aliyuncs.com 或 oss-region.aliyuncs.com
      else if (host.contains('aliyuncs.com') || host.contains('aliyun')) {
        if (host.startsWith('oss-')) {
          // 路径格式: oss-region.aliyuncs.com/bucket-name
          final match = RegExp(r'oss-([^.]+)\.aliyuncs\.com').firstMatch(host);
          if (match != null) {
            region = match.group(1);
          }
          if (pathSegments.isNotEmpty) {
            bucket = pathSegments.first;
          }
        } else {
          // 虚拟主机格式: bucket-name.oss-region.aliyuncs.com
          final parts = host.split('.');
          if (parts.length >= 3) {
            bucket = parts[0];
            final ossPart = parts[1];
            if (ossPart.startsWith('oss-')) {
              region = ossPart.substring(4);
            }
          }
        }
      }
      // 腾讯云格式: bucket-name.cos.region.myqcloud.com 或 cos.region.myqcloud.com
      else if (host.contains('myqcloud.com') || host.contains('qcloud')) {
        if (host.startsWith('cos.')) {
          // 路径格式: cos.region.myqcloud.com/bucket-name
          final match = RegExp(r'cos\.([^.]+)\.myqcloud\.com').firstMatch(host);
          if (match != null) {
            region = match.group(1);
          }
          if (pathSegments.isNotEmpty) {
            bucket = pathSegments.first;
          }
        } else {
          // 虚拟主机格式: bucket-name.cos.region.myqcloud.com
          final parts = host.split('.');
          if (parts.length >= 4 && parts[1] == 'cos') {
            bucket = parts[0];
            region = parts[2];
          }
        }
      }
      // 迅雷云盘格式: https://xlyunapi.xunlei.com
      else if (host.contains('xunlei.com') || host.contains('xlyunapi')) {
        // 迅雷云盘通常使用固定的API地址，存储桶默认为个人存储
        bucket = 'personal';
        region = 'cn';
      }
      // 通用S3格式: bucket-name.s3.region.amazonaws.com 或 bucket-name.s3-region.amazonaws.com
      else if (host.contains('s3')) {
        final parts = host.split('.');
        if (parts.length >= 4) {
          final s3Index = parts.indexWhere((p) => p.startsWith('s3'));
          if (s3Index > 0) {
            bucket = parts.sublist(0, s3Index).join('.');
            final s3Part = parts[s3Index];
            if (s3Part.contains('-')) {
              region = s3Part.split('-').skip(1).join('-');
            } else if (s3Index + 1 < parts.length) {
              region = parts[s3Index + 1];
            }
          }
        }
      }

      return (bucket: bucket, region: region);
    } catch (e) {
      return (bucket: null, region: null);
    }
  }
}
