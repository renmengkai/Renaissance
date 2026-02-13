import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/music_source.dart';
import '../models/playlist.dart';

class CloudMusicService {
  final CloudMusicConfig config;
  final http.Client _httpClient;

  CloudMusicService({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

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
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        return _parseMusicList(response.body, baseUrl);
      } else {
        debugPrint('[CloudMusicService] Failed to fetch music list: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[CloudMusicService] Error fetching music list: $e');
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
        final fullUrl = _normalizeUrl(decodedHref.startsWith('http')
            ? decodedHref
            : '$baseUrl/$decodedHref');

        songs.add(CloudSongInfo(
          key: decodedHref,
          url: fullUrl,
          fileName: _decodeUrl(text).replaceAll('/', ''),
          contentType: _getContentType(extension),
        ));
      }
    }

    debugPrint('[CloudMusicService] Found ${songs.length} audio files');
    return songs;
  }

  String _decodeUrl(String url) {
    try {
      return Uri.decodeComponent(url);
    } catch (e) {
      return url;
    }
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

    return Song(
      id: 'cloud_${sourceId}_${info.key.hashCode}',
      title: title,
      artist: artist,
      album: album,
      year: DateTime.now().year,
      coverUrl: 'assets/images/cover${(index % 3) + 1}.jpg',
      audioUrl: info.url,
      duration: const Duration(minutes: 3, seconds: 30),
      dominantColor: color,
      sourceType: MusicSourceType.cloud,
      sourceId: sourceId,
      cloudKey: info.key,
    );
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

  static Future<bool> testConnection(String url) async {
    try {
      final normalizedUrl = url.startsWith('http') ? url : 'http://$url';
      final response = await http.get(
        Uri.parse(normalizedUrl),
        headers: {
          'User-Agent': 'Renaissance-Music-Player/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[CloudMusicService] Connection test failed: $e');
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
