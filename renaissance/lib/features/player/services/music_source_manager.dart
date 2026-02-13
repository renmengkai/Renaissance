import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/music_source.dart';
import '../models/playlist.dart';
import 'local_music_service.dart';
import 'cloud_music_service.dart';
import '../../../core/services/storage_service.dart';

class MusicSourceManager extends StateNotifier<List<MusicSource>> {
  static const String _sourcesKey = 'music_sources';
  static const String _activeSourceKey = 'active_music_source';

  final Map<String, CloudMusicService> _cloudServices = {};

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

  Future<List<Song>> getSongsFromSource(MusicSource source) async {
    if (!source.isEnabled) {
      return [];
    }

    switch (source.type) {
      case MusicSourceType.local:
        return await LocalMusicService.scanLocalSongs();

      case MusicSourceType.cloud:
        if (source.baseUrl == null) {
          return [];
        }
        final config = CloudMusicConfig(
          provider: source.cloudProvider ?? CloudProvider.custom,
          baseUrl: source.baseUrl!,
          bucketName: source.bucketName,
          customHeaders: source.customHeaders != null
              ? Map<String, String>.from(jsonDecode(source.customHeaders!))
              : null,
        );
        final service = _getOrCreateCloudService(config);
        return await service.fetchCloudSongs(source.id);
    }
  }

  Future<Playlist> getPlaylistFromSource(MusicSource source) async {
    final songs = await getSongsFromSource(source);

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
    }
  }

  Future<List<Song>> getAllSongs() async {
    final List<Song> allSongs = [];

    for (final source in state.where((s) => s.isEnabled)) {
      final songs = await getSongsFromSource(source);
      allSongs.addAll(songs);
    }

    return allSongs;
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final List<Playlist> playlists = [];

    for (final source in state.where((s) => s.isEnabled)) {
      final playlist = await getPlaylistFromSource(source);
      playlists.add(playlist);
    }

    return playlists;
  }

  Future<bool> testCloudConnection(String url) async {
    return await CloudMusicService.testConnection(url);
  }

  Future<MusicSource> addCloudSource({
    required String name,
    required String baseUrl,
    CloudProvider? provider,
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
      customHeaders: customHeaders != null ? jsonEncode(customHeaders) : null,
    );

    await addSource(source);
    return source;
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
