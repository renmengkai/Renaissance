import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/song.dart';
import '../models/music_source.dart';
import '../models/playlist.dart';
import 's3_signature_service.dart';

class ConnectionTestResult {
  final bool success;
  final String? errorMessage;
  final int? statusCode;

  const ConnectionTestResult({
    required this.success,
    this.errorMessage,
    this.statusCode,
  });
}

class CloudMusicService {
  final CloudMusicConfig config;
  final http.Client _httpClient;
  QiniuS3Service? _s3Service;

  CloudMusicService({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    _initS3Service();
  }

  void _initS3Service() {
    if (config.accessKey != null &&
        config.secretKey != null &&
        config.bucketName != null &&
        config.region != null) {
      _s3Service = QiniuS3Service(
        accessKey: config.accessKey!,
        secretKey: config.secretKey!,
        region: config.region!,
        bucketName: config.bucketName!,
        endpoint: config.baseUrl,
      );

    }
  }

  /// 获取使用自定义域名的播放URL
  String getPlaybackUrl(String key) {
    if (config.customDomain != null && config.customDomain!.isNotEmpty) {
      String customDomain = config.customDomain!.replaceAll(RegExp(r'\s*$'), '');
      // 强制使用HTTP协议，因为HTTPS无法访问
      if (customDomain.startsWith('https://')) {
        customDomain = customDomain.replaceFirst('https://', 'http://');
      } else if (!customDomain.startsWith('http://')) {
        customDomain = 'http://$customDomain';
      }
      // 移除末尾的斜杠
      customDomain = customDomain.replaceAll(RegExp(r'/\s*$'), '');
      // 清理key值，移除开头的斜杠
      final cleanKey = key.startsWith('/') ? key.substring(1) : key;
      // 对文件路径进行URL编码
      final encodedKey = Uri.encodeComponent(cleanKey);
      // 生成最终的播放URL
      final playbackUrl = '$customDomain/$encodedKey';
      return playbackUrl;
    }
    return getSignedUrl(key);
  }

  bool get isS3Mode => _s3Service != null;

  String get baseUrl => config.useHttps
      ? config.baseUrl.replaceFirst('http://', 'https://')
      : config.baseUrl;

  String _normalizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return '${config.useHttps ? 'https' : 'http'}://$url';
    }
    if (config.useHttps && url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  Future<List<CloudSongInfo>> fetchMusicList() async {
    if (isS3Mode) {
      return _fetchS3MusicList();
    }
    return _fetchPublicMusicList();
  }

  Future<List<CloudSongInfo>> _fetchS3MusicList() async {
    try {
      final authHeaders = _s3Service!.getAuthHeaders(
        method: 'GET',
        path: '/',
        queryParams: {'list-type': '2'},
      );

      final url = Uri.parse('https://${_s3Service!.host}/?list-type=2');

      final response = await _httpClient.get(
        url,
        headers: {
          ...authHeaders,
          'User-Agent': 'Renaissance-Music-Player/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final xmlContent = utf8.decode(response.bodyBytes);
        return _parseS3ListResponse(xmlContent);
      } else {
        return [];
      }
    } catch (e) {

      return [];
    }
  }

  List<CloudSongInfo> _parseS3ListResponse(String xmlContent) {
    final List<CloudSongInfo> songs = [];
    final audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];

    try {
      final document = xml.XmlDocument.parse(xmlContent);
      final contents = document.findAllElements('Contents');

      for (final content in contents) {
        final keyElement = content.findElements('Key').firstOrNull;
        final sizeElement = content.findElements('Size').firstOrNull;
        final lastModifiedElement = content.findElements('LastModified').firstOrNull;

        if (keyElement != null) {
          final rawKey = keyElement.innerText;
          final decodedKey = _decodeUrl(rawKey);
          final extension = _getFileExtension(decodedKey).toLowerCase();

          if (audioExtensions.contains(extension)) {
            final signedUrl = _s3Service!.getSignedUrl(decodedKey);
            final fileName = decodedKey.split('/').last;

            songs.add(CloudSongInfo(
              key: decodedKey,
              url: signedUrl,
              fileName: fileName,
              size: sizeElement != null ? int.tryParse(sizeElement.innerText) : null,
              lastModified: lastModifiedElement != null
                  ? DateTime.tryParse(lastModifiedElement.innerText)
                  : null,
              contentType: _getContentType(extension),
            ));
          }
        }
      }

    } catch (e) {

    }

    return songs;
  }

  Future<List<CloudSongInfo>> _fetchPublicMusicList() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
        return _parseMusicList(htmlContent, baseUrl);
      } else {
        return [];
      }
    } catch (e) {

      return [];
    }
  }

  List<CloudSongInfo> _parseMusicList(String html, String baseUrl) {
    final List<CloudSongInfo> songs = [];
    final audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];

    final linkPattern = RegExp(
      r'<a[^>]+href=["' "'" r']([^"' "'" r']+)["' "'" r'][^>]*>([^<]+)</a>',
      caseSensitive: false,
    );

    for (final match in linkPattern.allMatches(html)) {
      final href = match.group(1) ?? '';
      final text = match.group(2) ?? '';

      final decodedHref = _decodeUrl(href);
      final extension = _getFileExtension(decodedHref).toLowerCase();

      if (audioExtensions.contains(extension)) {
        String fullUrl;
        if (config.customDomain != null && config.customDomain!.isNotEmpty) {
          final customDomain = config.customDomain!.replaceAll(RegExp(r'\s*/$'), '');
          final cleanHref = decodedHref.startsWith('/') ? decodedHref.substring(1) : decodedHref;
          fullUrl = '$customDomain/$cleanHref';
        } else {
          fullUrl = _normalizeUrl(decodedHref.startsWith('http')
              ? decodedHref
              : '$baseUrl/$decodedHref');
        }

        songs.add(CloudSongInfo(
          key: decodedHref,
          url: fullUrl,
          fileName: _decodeUrl(text).replaceAll('/', ''),
          contentType: _getContentType(extension),
        ));
      }
    }

    return songs;
  }

  String _decodeUrl(String url) {
    try {
      String decoded = Uri.decodeComponent(url);
      if (_containsGarbledText(decoded)) {
        final bytes = url.codeUnits;
        try {
          final latin1Decoded = latin1.decode(bytes);
          if (!_containsGarbledText(latin1Decoded) && _hasChineseChars(latin1Decoded)) {
            return latin1Decoded;
          }
        } catch (_) {}
      }
      if (decoded != url) {
        // 尝试二次解码，但需要捕获异常防止非法百分号编码
        try {
          String doubleDecoded = Uri.decodeComponent(decoded);
          if (doubleDecoded != decoded) {
            return doubleDecoded;
          }
        } catch (e) {
          // 二次解码失败，返回第一次解码的结果
        }
      }
      return decoded;
    } catch (e) {
      return url;
    }
  }

  bool _hasChineseChars(String text) {
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegex.hasMatch(text);
  }

  bool _containsGarbledText(String text) {
    final garbledPatterns = [
      'ä½\x8d³', 'ä½\x8d¥', 'æ\x9b\x87', 'æ\x88\x9b',
      '\ufffd', 'ï¿½', '?', 'Â·', 'ã\x80\x81', 'ã\x80\x8d',
    ];
    for (final pattern in garbledPatterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  String _getFileExtension(String path) {
    final parts = path.split('.');
    return parts.length > 1 ? '.${parts.last}' : '';
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.flac':
        return 'audio/flac';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'audio/mpeg';
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'User-Agent': 'Renaissance-Music-Player/1.0',
      'Accept': '*/*',
    };

    if (config.customHeaders != null) {
      headers.addAll(config.customHeaders!);
    }

    return headers;
  }

  Future<Song> createSongFromCloudInfo(CloudSongInfo info, int index, String sourceId) async {
    final fileName = info.fileName;
    String title = fileName;
    String artist = '未知艺术家';
    String album = '云音乐';

    final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final parts = nameWithoutExt.split(' - ');
    if (parts.length >= 2) {
      artist = parts[0].trim();
      title = parts[1].trim();
    } else {
      title = nameWithoutExt;
    }

    final colors = [
      '#4ECDC4',
      '#2C3E50',
      '#1E90FF',
      '#A0522D',
      '#9400D3',
      '#228B22',
      '#FF6347',
      '#191970',
    ];
    final color = colors[index % colors.length];

    // 延迟生成URL，只在点击播放时通过cloudKey生成
    // 这里使用临时URL，实际播放时会通过getSignedUrlForSong获取真实URL
    String audioUrl = 'cloud://${sourceId}/${info.key}';

    return Song(
      id: 'cloud_${sourceId}_${info.key.hashCode}',
      title: title,
      artist: artist,
      album: album,
      year: DateTime.now().year,
      coverUrl: 'assets/images/cover${(index % 3) + 1}.jpg',
      audioUrl: audioUrl,
      duration: const Duration(minutes: 3, seconds: 30),
      dominantColor: color,
      sourceType: MusicSourceType.cloud,
      sourceId: sourceId,
      cloudKey: info.key,
    );
  }

  bool get isS3Service => _s3Service != null;

  String getSignedUrl(String key) {
    if (_s3Service != null) {
      return _s3Service!.getSignedUrl(key);
    }
    return '$baseUrl/$key';
  }

  Future<List<Song>> fetchCloudSongs(String sourceId) async {
    final cloudInfos = await fetchMusicList();
    final songs = <Song>[];

    for (var i = 0; i < cloudInfos.length; i++) {
      final song = await createSongFromCloudInfo(cloudInfos[i], i, sourceId);
      songs.add(song);
    }

    return songs;
  }

  Future<Playlist> createCloudPlaylist(String sourceId, String name) async {
    final songs = await fetchCloudSongs(sourceId);
    return Playlist(
      id: 'cloud_playlist_$sourceId',
      name: name,
      description: '来自云存储',
      songs: songs,
      createdAt: DateTime.now(),
      coverUrl: 'assets/images/cover1.jpg',
    );
  }

  static Future<ConnectionTestResult> testConnection(
    String url, {
    String? accessKey,
    String? secretKey,
    String? bucketName,
    String? region,
  }) async {
    if (accessKey != null && secretKey != null && bucketName != null && region != null) {
      return _testS3Connection(url, accessKey, secretKey, bucketName, region);
    }
    return _testPublicConnection(url);
  }

  static Future<ConnectionTestResult> _testS3Connection(
    String endpoint,
    String accessKey,
    String secretKey,
    String bucketName,
    String region,
  ) async {
    try {
      final s3Service = QiniuS3Service(
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
        bucketName: bucketName,
        endpoint: endpoint,
      );

      final authHeaders = s3Service.getAuthHeaders(
        method: 'GET',
        path: '/',
        queryParams: {'list-type': '2', 'max-keys': '1'},
      );

      final url = Uri.parse('https://${s3Service.host}/?list-type=2&max-keys=1');

      final response = await http.get(
        url,
        headers: {
          ...authHeaders,
          'User-Agent': 'Renaissance-Music-Player/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const ConnectionTestResult(success: true);
      } else if (response.statusCode == 403) {
        return const ConnectionTestResult(
          success: false,
          errorMessage: '认证失败，请检查 AccessKey 和 SecretKey',
        );
      } else {
        return ConnectionTestResult(
          success: false,
          statusCode: response.statusCode,
          errorMessage: '服务器返回状态码: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      String errorMsg = '无法连接到服务器';
      if (e.osError?.errorCode == 11001 || e.osError?.errorCode == 11004) {
        errorMsg = '无法解析域名，请检查 URL 是否正确';
      }
      return ConnectionTestResult(success: false, errorMessage: errorMsg);
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: '连接失败: $e',
      );
    }
  }

  static Future<ConnectionTestResult> _testPublicConnection(String url) async {
    try {
      final normalizedUrl = url.startsWith('http') ? url : 'http://$url';
      final finalUrl = normalizedUrl.endsWith('/') ? normalizedUrl : '$normalizedUrl/';

      final response = await http.get(
        Uri.parse(finalUrl),
        headers: {
          'User-Agent': 'Renaissance-Music-Player/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 403) {
        return const ConnectionTestResult(success: true);
      } else {
        return ConnectionTestResult(
          success: false,
          statusCode: response.statusCode,
          errorMessage: '服务器返回状态码: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      String errorMsg = '无法连接到服务器';
      if (e.osError?.errorCode == 11001 || e.osError?.errorCode == 11004) {
        errorMsg = '无法解析域名，请检查 URL 是否正确';
      } else if (e.osError?.errorCode == 10061) {
        errorMsg = '连接被拒绝，服务器可能未运行';
      } else if (e.osError?.errorCode == 10060) {
        errorMsg = '连接超时，请检查网络或 URL';
      }
      return ConnectionTestResult(success: false, errorMessage: errorMsg);
    } on http.ClientException catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: '网络请求失败: ${e.message}',
      );
    } on FormatException catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: 'URL 格式不正确',
      );
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: '连接失败: $e',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
