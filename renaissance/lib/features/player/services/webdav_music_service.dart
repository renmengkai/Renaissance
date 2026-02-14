import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/song.dart';
import '../models/music_source.dart';
import '../../../core/utils/platform_utils.dart';

class WebDAVMusicService {
  final MusicSource source;
  final String? _username;
  final String? _password;
  final String _baseUrl;

  static const List<String> _supportedExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
  ];

  WebDAVMusicService({
    required this.source,
  })  : _username = source.accessKey,
        _password = source.secretKey,
        _baseUrl = source.baseUrl ?? '';

  Map<String, String> get _authHeaders {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {
      'Authorization': 'Basic $credentials',
    };
  }

  String _getWebDAVUrl(String path) {
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final targetPath = path.startsWith('/') ? path : '/$path';
    return '$base$targetPath';
  }

  Future<List<String>> listFiles(String path) async {
    try {
      final url = _getWebDAVUrl(path);
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers.addAll({
        ..._authHeaders,
        'Depth': '1',
        'Content-Type': 'application/xml',
      });
      
      final response = await client.send(request).timeout(const Duration(seconds: 30));
      final body = await http.Response.fromStream(response);

      if (response.statusCode == 207) {
        final document = XmlDocument.parse(body.body);
        final List<String> files = [];

        for (final responseElement in document.findAllElements('D:response')) {
          final href = responseElement.findElements('D:href').firstOrNull?.innerText;
          if (href == null) continue;

          final isCollection = responseElement.findElements('D:collection').isNotEmpty;
          final fileName = Uri.parse(href).pathSegments.last;

          if (!isCollection) {
            final ext = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
            if (_supportedExtensions.contains(ext)) {
              files.add(href);
            }
          }
        }

        return files;
      } else {

        return [];
      }
    } catch (e) {

      return [];
    }
  }

  Future<List<Song>> scanSongs() async {
    final List<Song> songs = [];
    final webdavPath = source.webdavPath ?? '/';

    final files = await listFiles(webdavPath);

    for (int i = 0; i < files.length; i++) {
      final fileUrl = files[i];
      final fileName = Uri.parse(fileUrl).pathSegments.last;
      final title = fileName.substring(0, fileName.lastIndexOf('.'));

      final parts = title.split(' - ');
      String songTitle = title;
      String artist = '未知艺术家';

      if (parts.length >= 2) {
        artist = parts[0].trim();
        songTitle = parts.sublist(1).join(' - ').trim();
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
      final color = colors[i % colors.length];

      final uniqueId = 'webdav_${fileUrl.hashCode}';

      songs.add(Song(
        id: uniqueId,
        title: songTitle,
        artist: artist,
        album: source.name,
        year: DateTime.now().year,
        coverUrl: 'assets/images/cover${(i % 3) + 1}.jpg',
        audioUrl: fileUrl,
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: color,
        hasGoldenLetter: i < 3,
        sourceType: MusicSourceType.webdav,
        sourceId: source.id,
      ));
    }

    return songs;
  }

  Future<bool> testConnection() async {
    try {
      final url = _getWebDAVUrl(source.webdavPath ?? '/');
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers.addAll({
        ..._authHeaders,
        'Depth': '0',
      });
      
      final response = await client.send(request).timeout(const Duration(seconds: 10));
      return response.statusCode == 207 || response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  static Future<ConnectionTestResult> testConnection2(
    String url,
    String? username,
    String? password,
  ) async {
    try {
      final credentials = base64Encode(utf8.encode('${username ?? ""}:${password ?? ""}'));
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Basic $credentials',
        'Depth': '0',
      });
      
      final response = await client.send(request).timeout(const Duration(seconds: 10));

      if (response.statusCode == 207 || response.statusCode == 200) {
        return ConnectionTestResult(
          success: true,
          message: '连接成功',
        );
      } else if (response.statusCode == 401) {
        return ConnectionTestResult(
          success: false,
          message: '用户名或密码错误',
        );
      } else {
        return ConnectionTestResult(
          success: false,
          message: '连接失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        message: '连接失败: $e',
      );
    }
  }
}

class ConnectionTestResult {
  final bool success;
  final String message;

  ConnectionTestResult({
    required this.success,
    required this.message,
  });
}
