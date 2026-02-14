import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/music_source.dart';
import '../models/playlist.dart';
import 'local_music_service.dart';
import 'cloud_music_service.dart' show ConnectionTestResult, CloudMusicService, CloudMusicConfig;
import 'webdav_music_service.dart' hide ConnectionTestResult;
import '../../../core/services/storage_service.dart';

class MusicSourceManager extends StateNotifier<List<MusicSource>> {
  static const String _sourcesKey = 'music_sources';
  static const String _activeSourceKey = 'active_music_source';

  final Map<String, CloudMusicService> _cloudServices = {};
  final Map<String, WebDAVMusicService> _webdavServices = {};

  MusicSourceManager() : super([]) {
    _loadSources();
  }

  Future<void> _loadSources() async {
    final sourcesJson = StorageService.getStringList(_sourcesKey);
    if (sourcesJson != null && sourcesJson.isNotEmpty) {
      state = sourcesJson
          .map((json) => MusicSource.fromJson(jsonDecode(json)))
          .toList();
    } else {
      // 默认只启用本地音乐
      state = [
        MusicSource(
          id: 'local_default',
          name: '本地音乐',
          type: MusicSourceType.local,
          isEnabled: true,
        ),
      ];
    }
  }

  Future<void> _saveSources() async {
    final sourcesJson = state.map((s) => jsonEncode(s.toJson())).toList();
    await StorageService.setStringList(_sourcesKey, sourcesJson);
  }

  Future<void> addSource(MusicSource source) async {
    state = [...state, source];
    await _saveSources();
  }

  Future<void> removeSource(String sourceId) async {
    state = state.where((s) => s.id != sourceId).toList();
    _cloudServices.remove(sourceId);
    await _saveSources();
  }

  Future<void> updateSource(MusicSource source) async {
    state = state.map((s) => s.id == source.id ? source : s).toList();
    await _saveSources();
  }

  Future<void> toggleSource(String sourceId, bool enabled) async {
    state = state.map((s) {
      if (s.id == sourceId) {
        return s.copyWith(isEnabled: enabled);
      }
      return s;
    }).toList();
    await _saveSources();
  }

  MusicSource? getActiveSource() {
    final activeId = StorageService.getString(_activeSourceKey);
    if (activeId != null) {
      return state.where((s) => s.id == activeId).firstOrNull;
    }
    return state.where((s) => s.isEnabled).firstOrNull;
  }

  Future<void> setActiveSource(String sourceId) async {
    await StorageService.setString(_activeSourceKey, sourceId);
  }

  CloudMusicService _getOrCreateCloudService(CloudMusicConfig config) {
    final key = config.baseUrl;
    if (!_cloudServices.containsKey(key)) {
      _cloudServices[key] = CloudMusicService(config: config);
    }
    return _cloudServices[key]!;
  }

  Future<List<Song>> getSongsFromSource(MusicSource source, {int page = 0, int pageSize = 20}) async {
    if (!source.isEnabled) {
      return [];
    }

    switch (source.type) {
      case MusicSourceType.local:
        // 本地音乐也支持分页
        final allSongs = await LocalMusicService.scanLocalSongs();
        final startIndex = page * pageSize;
        if (startIndex >= allSongs.length) {
          return [];
        }
        final endIndex = (startIndex + pageSize).clamp(0, allSongs.length);
        return allSongs.sublist(startIndex, endIndex);

      case MusicSourceType.cloud:
        if (source.baseUrl == null) {
          return [];
        }
        final config = CloudMusicConfig(
          provider: source.cloudProvider ?? CloudProvider.custom,
          baseUrl: source.baseUrl!,
          customDomain: source.customDomain,
          bucketName: source.bucketName,
          accessKey: source.accessKey,
          secretKey: source.secretKey,
          region: source.region,
          customHeaders: source.customHeaders != null
              ? Map<String, String>.from(jsonDecode(source.customHeaders!))
              : null,
        );
        final service = _getOrCreateCloudService(config);
        return await service.fetchCloudSongs(source.id, page: page, pageSize: pageSize);

      case MusicSourceType.webdav:
        if (source.baseUrl == null) {
          return [];
        }
        final webdavService = _getOrCreateWebDAVService(source);
        return await webdavService.scanSongs(page: page, pageSize: pageSize);
    }
  }

  WebDAVMusicService _getOrCreateWebDAVService(MusicSource source) {
    final key = source.id;
    if (!_webdavServices.containsKey(key)) {
      _webdavServices[key] = WebDAVMusicService(source: source);
    }
    return _webdavServices[key]!;
  }

  Future<Playlist> getPlaylistFromSource(MusicSource source, {int page = 0, int pageSize = 20}) async {
    final songs = await getSongsFromSource(source, page: page, pageSize: pageSize);

    switch (source.type) {
      case MusicSourceType.local:
        return Playlist(
          id: 'playlist_${source.id}',
          name: source.name,
          description: '本地音乐文件夹',
          songs: songs,
          createdAt: DateTime.now(),
          coverUrl: 'assets/images/cover1.jpg',
        );

      case MusicSourceType.cloud:
        return Playlist(
          id: 'playlist_${source.id}',
          name: source.name,
          description: '云存储: ${source.baseUrl ?? ""}',
          songs: songs,
          createdAt: DateTime.now(),
          coverUrl: 'assets/images/cover1.jpg',
        );

      case MusicSourceType.webdav:
        return Playlist(
          id: 'playlist_${source.id}',
          name: source.name,
          description: 'WebDAV: ${source.baseUrl ?? ""}',
          songs: songs,
          createdAt: DateTime.now(),
          coverUrl: 'assets/images/cover1.jpg',
        );
    }
  }

  Future<List<Song>> getAllSongs({int page = 0, int pageSize = 20}) async {
    final List<Song> allSongs = [];
    final stopwatch = Stopwatch()..start();

    for (final source in state.where((s) => s.isEnabled)) {
      final sourceStopwatch = Stopwatch()..start();
      final songs = await getSongsFromSource(source, page: page, pageSize: pageSize);
      sourceStopwatch.stop();
      debugPrint('[MusicSourceManager] Loaded ${songs.length} songs from ${source.name} (${source.type}) in ${sourceStopwatch.elapsedMilliseconds}ms');
      allSongs.addAll(songs);
    }

    stopwatch.stop();
    debugPrint('[MusicSourceManager] Total loaded ${allSongs.length} songs from all sources in ${stopwatch.elapsedMilliseconds}ms');
    return allSongs;
  }

  Future<List<Playlist>> getAllPlaylists({int page = 0, int pageSize = 20}) async {
    final List<Playlist> playlists = [];

    for (final source in state.where((s) => s.isEnabled)) {
      final playlist = await getPlaylistFromSource(source, page: page, pageSize: pageSize);
      playlists.add(playlist);
    }

    return playlists;
  }

  Future<ConnectionTestResult> testCloudConnection(
    String url, {
    String? accessKey,
    String? secretKey,
    String? bucketName,
    String? region,
  }) async {
    return await CloudMusicService.testConnection(
      url,
      accessKey: accessKey,
      secretKey: secretKey,
      bucketName: bucketName,
      region: region,
    );
  }

  Future<MusicSource> addCloudSource({
    required String name,
    required String baseUrl,
    String? customDomain,
    CloudProvider? provider,
    String? bucketName,
    String? accessKey,
    String? secretKey,
    String? region,
    Map<String, String>? customHeaders,
  }) async {
    final detectedProvider = provider ?? CloudProviderHelper.detectProviderFromUrl(baseUrl);

    final source = MusicSource(
      id: 'cloud_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: MusicSourceType.cloud,
      isEnabled: true,
      cloudProvider: detectedProvider,
      baseUrl: baseUrl,
      customDomain: customDomain,
      bucketName: bucketName,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
      customHeaders: customHeaders != null ? jsonEncode(customHeaders) : null,
    );

    await addSource(source);
    return source;
  }

  Future<String> getSignedUrlForSong(Song song) async {
    // WebDAV 不需要签名，直接返回原始 URL
    if (song.sourceType == MusicSourceType.webdav) {
      return song.audioUrl;
    }

    if (song.sourceType != MusicSourceType.cloud || song.cloudKey == null || song.sourceId == null) {
      return song.audioUrl;
    }

    final source = state.where((s) => s.id == song.sourceId).firstOrNull;
    if (source == null || source.type != MusicSourceType.cloud) {
      return song.audioUrl;
    }

    final config = CloudMusicConfig(
      provider: source.cloudProvider ?? CloudProvider.custom,
      baseUrl: source.baseUrl!,
      customDomain: source.customDomain,
      bucketName: source.bucketName,
      accessKey: source.accessKey,
      secretKey: source.secretKey,
      region: source.region,
    );

    final service = _getOrCreateCloudService(config);
    // 直接调用getPlaybackUrl方法，不需要await，因为它是同步方法
    final signedUrl = service.getPlaybackUrl(song.cloudKey!);
    return signedUrl;
  }

  @override
  void dispose() {
    for (final service in _cloudServices.values) {
      service.dispose();
    }
    super.dispose();
  }
}

final musicSourceManagerProvider =
    StateNotifierProvider<MusicSourceManager, List<MusicSource>>((ref) {
  return MusicSourceManager();
});

final activeSourceProvider = Provider<MusicSource?>((ref) {
  final manager = ref.watch(musicSourceManagerProvider.notifier);
  return manager.getActiveSource();
});

final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  final manager = ref.watch(musicSourceManagerProvider.notifier);
  return await manager.getAllSongs();
});

final allPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final manager = ref.watch(musicSourceManagerProvider.notifier);
  return await manager.getAllPlaylists();
});
