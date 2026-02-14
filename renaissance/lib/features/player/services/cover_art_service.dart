import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../../core/services/storage_service.dart';
import '../models/song.dart';

/// 封面缓存元数据
class CoverCacheMetadata {
  final String songId;
  final String artist;
  final String title;
  final String cachePath;
  final DateTime cachedAt;
  final String source; // 封面来源: 'embedded', 'itunes', 'deezer', 'spotify', 'musicbrainz', 'lastfm', 'default'

  CoverCacheMetadata({
    required this.songId,
    required this.artist,
    required this.title,
    required this.cachePath,
    required this.cachedAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'artist': artist,
    'title': title,
    'cachePath': cachePath,
    'cachedAt': cachedAt.toIso8601String(),
    'source': source,
  };

  factory CoverCacheMetadata.fromJson(Map<String, dynamic> json) => CoverCacheMetadata(
    songId: json['songId'],
    artist: json['artist'],
    title: json['title'],
    cachePath: json['cachePath'],
    cachedAt: DateTime.parse(json['cachedAt']),
    source: json['source'],
  );
}

/// 封面获取服务
/// 负责从多个来源获取歌曲封面图片
class CoverArtService {
  static final CoverArtService _instance = CoverArtService._internal();
  factory CoverArtService() => _instance;
  CoverArtService._internal();

  Directory? _cacheDir;

  final Map<String, String> _memoryCache = {};

  // 缓存元数据持久化存储键
  static const String _cacheMetadataKey = 'cover_cache_metadata';

  // 正在进行的封面加载任务
  final Map<String, Future<String?>> _pendingLoads = {};

  // 封面加载控制
  bool _isPaused = false;
  final List<Song> _pendingSongs = [];

  // 暂停封面加载（音乐播放时调用）
  void pauseLoading() {
    _isPaused = true;
    debugPrint('[CoverArtService] Cover loading paused');
  }

  // 恢复封面加载（音乐缓存足够时调用）
  void resumeLoading() {
    if (!_isPaused) return;
    _isPaused = false;
    debugPrint('[CoverArtService] Cover loading resumed, pending: ${_pendingSongs.length}');

    // 处理等待中的歌曲
    final songsToLoad = List<Song>.from(_pendingSongs);
    _pendingSongs.clear();

    // 延迟加载等待中的歌曲
    if (songsToLoad.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        for (final song in songsToLoad) {
          _loadCloudSongCoverAsync(song, _generateCacheFileName(song));
        }
      });
    }
  }

  Future<void> _initCacheDir() async {
    if (_cacheDir != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'Renaissance', 'CoverCache'));

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  /// 获取缓存元数据
  Future<Map<String, CoverCacheMetadata>> _loadCacheMetadata() async {
    try {
      final jsonStr = StorageService.getString(_cacheMetadataKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = json.decode(jsonStr);
        return data.map((key, value) =>
            MapEntry(key, CoverCacheMetadata.fromJson(value)));
      }
    } catch (e) {
      debugPrint('[CoverArtService] Error loading cache metadata: $e');
    }
    return {};
  }

  /// 保存缓存元数据
  Future<void> _saveCacheMetadata(Map<String, CoverCacheMetadata> metadata) async {
    try {
      final data = metadata.map((key, value) => MapEntry(key, value.toJson()));
      await StorageService.setString(_cacheMetadataKey, json.encode(data));
    } catch (e) {
      debugPrint('[CoverArtService] Error saving cache metadata: $e');
    }
  }

  /// 获取歌曲封面
  /// 优先级：1.内存缓存 2.磁盘缓存 3.音频文件内嵌封面 4.在线搜索 5.默认封面
  Future<String> getCoverArt(Song song) async {
    await _initCacheDir();

    final cacheKey = _generateCacheFileName(song);

    // 1. 检查内存缓存
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    final cachePath = path.join(_cacheDir!.path, cacheKey);

    // 2. 检查磁盘缓存
    if (await File(cachePath).exists()) {
      _memoryCache[cacheKey] = cachePath;
      return cachePath;
    }

    // 3. 检查缓存元数据（用于云存储歌曲）
    final metadata = await _loadCacheMetadata();
    if (metadata.containsKey(cacheKey)) {
      final meta = metadata[cacheKey]!;
      if (await File(meta.cachePath).exists()) {
        _memoryCache[cacheKey] = meta.cachePath;
        return meta.cachePath;
      }
    }

    // 云存储歌曲使用异步加载策略
    if (song.audioUrl.startsWith('http://') || song.audioUrl.startsWith('https://')) {
      // 立即返回默认封面，同时在后台加载真实封面
      final defaultCover = _getDefaultCoverPath(song);
      _memoryCache[cacheKey] = defaultCover;

      // 异步加载真实封面（如果不在加载中）
      _loadCloudSongCoverAsync(song, cacheKey);

      return defaultCover;
    }

    // 本地歌曲：尝试提取内嵌封面
    final embeddedCover = await _extractEmbeddedCover(song.audioUrl);
    if (embeddedCover != null) {
      await _saveCoverToCache(embeddedCover, cachePath);
      _memoryCache[cacheKey] = cachePath;
      return cachePath;
    }

    // 本地歌曲：尝试在线搜索
    final onlineCover = await _searchOnlineCover(song);
    if (onlineCover != null) {
      await _saveCoverToCache(onlineCover, cachePath);
      _memoryCache[cacheKey] = cachePath;
      return cachePath;
    }

    final defaultCover = _getDefaultCoverPath(song);
    _memoryCache[cacheKey] = defaultCover;
    return defaultCover;
  }

  // 封面加载完成回调
  void Function(Song song, String coverPath)? onCoverLoaded;

  /// 异步加载云存储歌曲封面
  Future<void> _loadCloudSongCoverAsync(Song song, String cacheKey) async {
    // 如果暂停了，将歌曲加入等待队列
    if (_isPaused) {
      if (!_pendingSongs.any((s) => s.id == song.id)) {
        _pendingSongs.add(song);
        debugPrint('[CoverArtService] Loading paused, added ${song.title} to pending queue');
      }
      return;
    }

    // 避免重复加载
    if (_pendingLoads.containsKey(cacheKey)) {
      return;
    }

    final loadFuture = _loadCloudSongCoverInternal(song, cacheKey);
    _pendingLoads[cacheKey] = loadFuture;

    try {
      final result = await loadFuture;
      if (result != null) {
        debugPrint('[CoverArtService] Async loaded cover for ${song.title} from $result');
        // 通知回调封面已加载
        if (onCoverLoaded != null) {
          final coverPath = _memoryCache[cacheKey];
          if (coverPath != null && !coverPath.startsWith('assets/')) {
            onCoverLoaded!(song, coverPath);
          }
        }
      }
    } catch (e) {
      debugPrint('[CoverArtService] Error async loading cover for ${song.title}: $e');
    } finally {
      _pendingLoads.remove(cacheKey);
    }
  }

  /// 内部方法：加载云存储歌曲封面
  Future<String?> _loadCloudSongCoverInternal(Song song, String cacheKey) async {
    try {
      final onlineCover = await _searchOnlineCover(song);
      if (onlineCover != null) {
        final cachePath = path.join(_cacheDir!.path, cacheKey);
        await _saveCoverToCache(onlineCover, cachePath);
        _memoryCache[cacheKey] = cachePath;

        // 更新缓存元数据
        final metadata = await _loadCacheMetadata();
        metadata[cacheKey] = CoverCacheMetadata(
          songId: song.id,
          artist: song.artist,
          title: song.title,
          cachePath: cachePath,
          cachedAt: DateTime.now(),
          source: 'online',
        );
        await _saveCacheMetadata(metadata);

        return 'online';
      }
    } catch (e) {
      debugPrint('[CoverArtService] Error loading cloud song cover: $e');
    }
    return null;
  }

  /// 预加载多个歌曲的封面
  Future<void> preloadCovers(List<Song> songs) async {
    await _initCacheDir();

    debugPrint('[CoverArtService] Starting preload for ${songs.length} songs');
    final stopwatch = Stopwatch()..start();

    int cloudSongCount = 0;
    int localSongCount = 0;
    int cachedCount = 0;

    // 先加载所有本地歌曲封面
    for (final song in songs) {
      final cacheKey = _generateCacheFileName(song);

      // 跳过已缓存的
      if (_memoryCache.containsKey(cacheKey)) {
        cachedCount++;
        continue;
      }

      final cachePath = path.join(_cacheDir!.path, cacheKey);
      if (await File(cachePath).exists()) {
        _memoryCache[cacheKey] = cachePath;
        cachedCount++;
        continue;
      }

      // 检查缓存元数据
      final metadata = await _loadCacheMetadata();
      if (metadata.containsKey(cacheKey) && await File(metadata[cacheKey]!.cachePath).exists()) {
        _memoryCache[cacheKey] = metadata[cacheKey]!.cachePath;
        cachedCount++;
        continue;
      }

      // 云存储歌曲：只使用默认封面，不阻塞预加载
      if (song.audioUrl.startsWith('http://') || song.audioUrl.startsWith('https://')) {
        cloudSongCount++;
        final defaultCover = _getDefaultCoverPath(song);
        _memoryCache[cacheKey] = defaultCover;
        continue;
      }

      localSongCount++;

      // 本地歌曲：尝试提取内嵌封面
      final embeddedCover = await _extractEmbeddedCover(song.audioUrl);
      if (embeddedCover != null) {
        await _saveCoverToCache(embeddedCover, cachePath);
        _memoryCache[cacheKey] = cachePath;
        continue;
      }

      // 本地歌曲：尝试在线搜索（限制数量避免太慢）
      if (localSongCount <= 10) { // 只预加载前10首本地歌曲的在线封面
        final onlineCover = await _searchOnlineCover(song);
        if (onlineCover != null) {
          await _saveCoverToCache(onlineCover, cachePath);
          _memoryCache[cacheKey] = cachePath;
          continue;
        }
      }

      final defaultCover = _getDefaultCoverPath(song);
      _memoryCache[cacheKey] = defaultCover;
    }

    stopwatch.stop();
    debugPrint('[CoverArtService] Preload completed in ${stopwatch.elapsedMilliseconds}ms, '
        'cloud songs: $cloudSongCount, local songs: $localSongCount, cached: $cachedCount');

    // 异步加载云存储歌曲封面（不阻塞）
    _preloadCloudSongsAsync(songs);
  }

  /// 异步预加载云存储歌曲封面
  Future<void> _preloadCloudSongsAsync(List<Song> songs) async {
    final cloudSongs = songs.where((s) =>
        s.audioUrl.startsWith('http://') || s.audioUrl.startsWith('https://')).toList();

    if (cloudSongs.isEmpty) return;

    debugPrint('[CoverArtService] Starting async preload for ${cloudSongs.length} cloud songs');
    final stopwatch = Stopwatch()..start();

    int loadedCount = 0;
    int failedCount = 0;

    // 分批处理，每批5首，避免同时发起太多请求
    const batchSize = 5;
    for (int i = 0; i < cloudSongs.length; i += batchSize) {
      final batch = cloudSongs.skip(i).take(batchSize).toList();
      final futures = batch.map((song) async {
        final cacheKey = _generateCacheFileName(song);

        // 检查是否已经有缓存
        final cachePath = path.join(_cacheDir!.path, cacheKey);
        if (await File(cachePath).exists()) {
          _memoryCache[cacheKey] = cachePath;
          return true;
        }

        // 检查缓存元数据
        final metadata = await _loadCacheMetadata();
        if (metadata.containsKey(cacheKey) && await File(metadata[cacheKey]!.cachePath).exists()) {
          _memoryCache[cacheKey] = metadata[cacheKey]!.cachePath;
          return true;
        }

        // 避免重复加载
        if (_pendingLoads.containsKey(cacheKey)) {
          return false;
        }

        try {
          final result = await _loadCloudSongCoverInternal(song, cacheKey);
          return result != null;
        } catch (e) {
          return false;
        }
      });

      final results = await Future.wait(futures);
      loadedCount += results.where((r) => r).length;
      failedCount += results.where((r) => !r).length;

      // 每批之间添加小延迟，避免请求过于频繁
      if (i + batchSize < cloudSongs.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    stopwatch.stop();
    debugPrint('[CoverArtService] Async preload completed in ${stopwatch.elapsedMilliseconds}ms, '
        'loaded: $loadedCount, failed: $failedCount');
  }

  /// 检查歌曲封面是否已缓存（包括异步加载中的）
  Future<bool> isCoverCached(Song song) async {
    final cacheKey = _generateCacheFileName(song);

    // 检查内存缓存
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      // 如果是默认封面，检查是否正在加载中
      if (cached.startsWith('assets/')) {
        return !_pendingLoads.containsKey(cacheKey);
      }
      return true;
    }

    // 检查磁盘缓存
    await _initCacheDir();
    final cachePath = path.join(_cacheDir!.path, cacheKey);
    if (await File(cachePath).exists()) {
      return true;
    }

    // 检查缓存元数据
    final metadata = await _loadCacheMetadata();
    if (metadata.containsKey(cacheKey)) {
      return await File(metadata[cacheKey]!.cachePath).exists();
    }

    return false;
  }

  /// 同步获取内存缓存中的封面路径（不阻塞，立即返回）
  /// 返回 null 表示不在内存缓存中
  String? getCoverFromMemoryCache(Song song) {
    final cacheKey = _generateCacheFileName(song);
    return _memoryCache[cacheKey];
  }

  /// 获取封面的缓存状态信息
  Future<CoverCacheInfo> getCoverCacheInfo(Song song) async {
    final cacheKey = _generateCacheFileName(song);

    // 检查内存缓存
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      if (!cached.startsWith('assets/')) {
        return CoverCacheInfo(
          isCached: true,
          cachePath: cached,
          isDefault: false,
          isLoading: false,
        );
      }
    }

    // 检查磁盘缓存
    await _initCacheDir();
    final cachePath = path.join(_cacheDir!.path, cacheKey);
    if (await File(cachePath).exists()) {
      return CoverCacheInfo(
        isCached: true,
        cachePath: cachePath,
        isDefault: false,
        isLoading: false,
      );
    }

    // 检查缓存元数据
    final metadata = await _loadCacheMetadata();
    if (metadata.containsKey(cacheKey)) {
      final meta = metadata[cacheKey]!;
      if (await File(meta.cachePath).exists()) {
        return CoverCacheInfo(
          isCached: true,
          cachePath: meta.cachePath,
          isDefault: false,
          isLoading: false,
        );
      }
    }

    // 检查是否正在加载中
    final isLoading = _pendingLoads.containsKey(cacheKey);

    return CoverCacheInfo(
      isCached: false,
      cachePath: null,
      isDefault: true,
      isLoading: isLoading,
    );
  }

  /// 清除指定歌曲的封面缓存
  Future<void> clearCacheForSong(Song song) async {
    final cacheKey = _generateCacheFileName(song);
    _memoryCache.remove(cacheKey);

    // 从元数据中移除
    final metadata = await _loadCacheMetadata();
    if (metadata.containsKey(cacheKey)) {
      metadata.remove(cacheKey);
      await _saveCacheMetadata(metadata);
    }

    // 删除缓存文件
    await _initCacheDir();
    final cachePath = path.join(_cacheDir!.path, cacheKey);
    final file = File(cachePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 从音频文件提取元数据和封面
  Future<Uint8List?> _extractEmbeddedCover(String audioPath) async {
    try {
      if (audioPath.startsWith('assets/')) {
        return null;
      }

      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        return null;
      }

      final file = File(audioPath);
      if (!await file.exists()) {
        return null;
      }

      // 手动解析音频文件提取封面
      return await _manualExtractCover(file);
    } catch (e) {
      return null;
    }
  }

  /// 手动提取封面（备用方案）
  Future<Uint8List?> _manualExtractCover(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = path.extension(file.path).toLowerCase();

      switch (ext) {
        case '.mp3':
          return _extractMp3Cover(bytes);
        case '.flac':
          return _extractFlacCover(bytes);
        case '.m4a':
        case '.mp4':
          return _extractMp4Cover(bytes);
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 从MP3文件提取ID3标签中的封面
  Uint8List? _extractMp3Cover(Uint8List bytes) {
    try {
      final apicPattern = [0x41, 0x50, 0x49, 0x43];

      for (int i = 0; i < bytes.length - 4; i++) {
        if (bytes[i] == apicPattern[0] &&
            bytes[i + 1] == apicPattern[1] &&
            bytes[i + 2] == apicPattern[2] &&
            bytes[i + 3] == apicPattern[3]) {

          int offset = i + 10;
          offset++;

          while (offset < bytes.length && bytes[offset] != 0) {
            offset++;
          }
          offset++;
          offset++;

          while (offset < bytes.length && bytes[offset] != 0) {
            offset++;
          }
          offset++;

          int endOffset = offset;
          while (endOffset < bytes.length - 4) {
            if ((bytes[endOffset] >= 0x41 && bytes[endOffset] <= 0x5A) ||
                (bytes[endOffset] >= 0x30 && bytes[endOffset] <= 0x39)) {
              bool isFrameHeader = true;
              for (int j = 1; j < 4; j++) {
                final byte = bytes[endOffset + j];
                if (!((byte >= 0x41 && byte <= 0x5A) ||
                      (byte >= 0x30 && byte <= 0x39))) {
                  isFrameHeader = false;
                  break;
                }
              }
              if (isFrameHeader) break;
            }
            endOffset++;
          }

          if (endOffset > offset) {
            return Uint8List.sublistView(bytes, offset, endOffset);
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 从FLAC文件提取封面
  Uint8List? _extractFlacCover(Uint8List bytes) {
    try {
      int offset = 4;

      while (offset < bytes.length - 4) {
        final blockType = bytes[offset] & 0x7F;
        final isLastBlock = (bytes[offset] & 0x80) != 0;

        final blockSize = (bytes[offset + 1] << 16) |
                         (bytes[offset + 2] << 8) |
                         bytes[offset + 3];

        if (blockType == 6) {
          int pictureOffset = offset + 4;
          pictureOffset += 4;

          final mimeLength = (bytes[pictureOffset] << 24) |
                            (bytes[pictureOffset + 1] << 16) |
                            (bytes[pictureOffset + 2] << 8) |
                            bytes[pictureOffset + 3];
          pictureOffset += 4 + mimeLength;

          final descLength = (bytes[pictureOffset] << 24) |
                            (bytes[pictureOffset + 1] << 16) |
                            (bytes[pictureOffset + 2] << 8) |
                            bytes[pictureOffset + 3];
          pictureOffset += 4 + descLength;

          pictureOffset += 16;

          final dataLength = (bytes[pictureOffset] << 24) |
                            (bytes[pictureOffset + 1] << 16) |
                            (bytes[pictureOffset + 2] << 8) |
                            bytes[pictureOffset + 3];
          pictureOffset += 4;

          if (pictureOffset + dataLength <= bytes.length) {
            return Uint8List.sublistView(bytes, pictureOffset, pictureOffset + dataLength);
          }
        }

        offset += 4 + blockSize;

        if (isLastBlock) break;
      }
    } catch (e) {
    }
    return null;
  }

  /// 从MP4/M4A文件提取封面
  Uint8List? _extractMp4Cover(Uint8List bytes) {
    try {
      return _findMp4Atom(bytes, 'covr');
    } catch (e) {
    }
    return null;
  }

  Uint8List? _findMp4Atom(Uint8List bytes, String atomName) {
    int offset = 0;

    if (bytes.length > 8) {
      final ftypSize = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
      final ftypName = String.fromCharCodes(bytes.sublist(4, 8));
      if (ftypName == 'ftyp' && ftypSize > 0 && ftypSize < bytes.length) {
        offset = ftypSize;
      }
    }

    while (offset < bytes.length - 8) {
      final size = (bytes[offset] << 24) | (bytes[offset + 1] << 16) |
                   (bytes[offset + 2] << 8) | bytes[offset + 3];
      final name = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));

      if (size == 0 || size > bytes.length - offset) break;

      if (name == atomName) {
        final dataOffset = offset + 8 + 8;
        if (dataOffset < offset + size) {
          return Uint8List.sublistView(bytes, dataOffset, offset + size);
        }
      }

      if (name == 'moov' || name == 'udta' || name == 'meta') {
        final result = _findMp4Atom(
          Uint8List.sublistView(bytes, offset + 8, offset + size),
          atomName
        );
        if (result != null) return result;
      }

      offset += size;
    }

    return null;
  }

  /// 在线搜索封面（带超时控制）
  Future<Uint8List?> _searchOnlineCover(Song song) async {
    // 按优先级排列的搜索源
    final sources = [
      ('iTunes', _searchFromITunes),
      ('Deezer', _searchFromDeezer),
      ('Spotify', _searchFromSpotify),
      ('MusicBrainz', _searchFromMusicBrainz),
      ('LastFm', _searchFromLastFm),
    ];

    for (final (name, source) in sources) {
      try {
        final cover = await source(song).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        if (cover != null) {
          return cover;
        }
      } catch (e) {
      }
    }

    return null;
  }

  /// 从 iTunes API 搜索封面（最可靠）
  Future<Uint8List?> _searchFromITunes(Song song) async {
    try {
      // 构建搜索查询
      String query;
      if (song.artist != '未知艺术家' && song.artist.isNotEmpty) {
        query = '${song.artist} ${song.title}';
      } else {
        query = song.title;
      }

      final encodedQuery = Uri.encodeQueryComponent(query);
      final searchUrl = 'https://itunes.apple.com/search?term=$encodedQuery&media=music&limit=5';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'User-Agent': 'RenaissanceMusicApp/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          // 尝试找到最佳匹配
          for (final result in results) {
            final artistName = result['artistName'] as String?;
            final trackName = result['trackName'] as String?;
            var artworkUrl = result['artworkUrl100'] as String?;

            if (artworkUrl != null) {
              // 获取高清封面 (600x600)
              artworkUrl = artworkUrl.replaceAll('100x100', '600x600');

              final imageResponse = await http.get(Uri.parse(artworkUrl));
              if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                return imageResponse.bodyBytes;
              }
            }
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 从 Deezer API 搜索封面
  Future<Uint8List?> _searchFromDeezer(Song song) async {
    try {
      String query;
      if (song.artist != '未知艺术家' && song.artist.isNotEmpty) {
        query = '${song.artist} ${song.title}';
      } else {
        query = song.title;
      }

      final encodedQuery = Uri.encodeQueryComponent(query);
      final searchUrl = 'https://api.deezer.com/search?q=$encodedQuery&limit=5';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'User-Agent': 'RenaissanceMusicApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List?;

        if (results != null && results.isNotEmpty) {
          for (final result in results) {
            var coverUrl = result['album']?['cover_big'] as String?;
            if (coverUrl == null) {
              coverUrl = result['album']?['cover_medium'] as String?;
            }

            if (coverUrl != null) {
              coverUrl = coverUrl.replaceAll(r'\/', '/');

              final imageResponse = await http.get(Uri.parse(coverUrl));
              if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                return imageResponse.bodyBytes;
              }
            }
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 从 Spotify 搜索封面（通过公开 API）
  Future<Uint8List?> _searchFromSpotify(Song song) async {
    try {
      String query;
      if (song.artist != '未知艺术家' && song.artist.isNotEmpty) {
        query = 'track:${song.title} artist:${song.artist}';
      } else {
        query = 'track:${song.title}';
      }

      final encodedQuery = Uri.encodeQueryComponent(query);
      final searchUrl = 'https://api.spotify.com/v1/search?q=$encodedQuery&type=track&limit=5';

      // 注意：Spotify API 需要 access token，这里尝试使用公开端点
      // 如果失败，跳过此源
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'User-Agent': 'RenaissanceMusicApp/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']?['items'] as List?;

        if (tracks != null && tracks.isNotEmpty) {
          for (final track in tracks) {
            final images = track['album']?['images'] as List?;
            if (images != null && images.isNotEmpty) {
              // 找到中等尺寸的图片
              String? imageUrl;
              for (final image in images) {
                final height = image['height'] as int?;
                if (height != null && height >= 300 && height <= 640) {
                  imageUrl = image['url'] as String?;
                  break;
                }
              }
              // 如果没找到中等尺寸，使用第一张
              imageUrl ??= images.first['url'] as String?;

              if (imageUrl != null) {
                final imageResponse = await http.get(Uri.parse(imageUrl));
                if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                  return imageResponse.bodyBytes;
                }
              }
            }
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 从 MusicBrainz 搜索封面
  Future<Uint8List?> _searchFromMusicBrainz(Song song) async {
    try {
      String query;
      if (song.artist != '未知艺术家' && song.artist.isNotEmpty) {
        query = '${song.title} AND artist:${song.artist}';
      } else {
        query = song.title;
      }

      final encodedQuery = Uri.encodeQueryComponent(query);
      final searchUrl = 'https://musicbrainz.org/ws/2/recording/?query=$encodedQuery&fmt=json&limit=3';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'User-Agent': 'RenaissanceMusicApp/1.0 (https://github.com/renaissance)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recordings = data['recordings'] as List?;

        if (recordings != null && recordings.isNotEmpty) {
          for (final recording in recordings) {
            final releases = recording['releases'] as List?;
            if (releases != null && releases.isNotEmpty) {
              final releaseId = releases.first['id'] as String?;
              if (releaseId != null) {
                final coverUrl = 'https://coverartarchive.org/release/$releaseId/front-500';

                final coverResponse = await http.get(
                  Uri.parse(coverUrl),
                  headers: {'User-Agent': 'RenaissanceMusicApp/1.0'},
                );

                if (coverResponse.statusCode == 200 && coverResponse.bodyBytes.isNotEmpty) {
                  return coverResponse.bodyBytes;
                }
              }
            }
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 从 Last.fm 搜索封面
  Future<Uint8List?> _searchFromLastFm(Song song) async {
    try {
      if (song.artist == '未知艺术家' || song.artist.isEmpty) {
        return null;
      }

      final artist = Uri.encodeQueryComponent(song.artist);
      final album = Uri.encodeQueryComponent(song.album.isNotEmpty ? song.album : song.title);
      final searchUrl = 'https://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=demo&artist=$artist&album=$album&format=json';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'User-Agent': 'RenaissanceMusicApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final album = data['album'];
        final images = album?['image'] as List?;

        if (images != null) {
          // 找最大尺寸的图片
          String? imageUrl;
          for (final image in images.reversed) {
            final url = image['#text'] as String?;
            final size = image['size'] as String?;
            if (url != null && url.isNotEmpty) {
              imageUrl = url;
              if (size == 'extralarge' || size == 'mega') break;
            }
          }

          if (imageUrl != null && imageUrl.isNotEmpty) {
            final imageResponse = await http.get(Uri.parse(imageUrl));
            if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
              return imageResponse.bodyBytes;
            }
          }
        }
      }
    } catch (e) {
    }
    return null;
  }

  /// 生成缓存文件名
  String _generateCacheFileName(Song song) {
    final identifier = '${song.artist}_${song.title}_${song.album}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u4e00-\u9fa5]'), '_')
        .toLowerCase();
    return '${identifier}_cover.jpg';
  }

  /// 保存封面到缓存
  Future<void> _saveCoverToCache(Uint8List imageData, String cachePath) async {
    try {
      final image = img.decodeImage(imageData);
      if (image != null) {
        final resized = img.copyResize(image, width: 500);
        final jpegData = img.encodeJpg(resized, quality: 85);

        final file = File(cachePath);
        await file.writeAsBytes(jpegData);
      } else {
        final file = File(cachePath);
        await file.writeAsBytes(imageData);
      }
    } catch (e) {
      try {
        final file = File(cachePath);
        await file.writeAsBytes(imageData);
      } catch (_) {}
    }
  }

  /// 获取默认封面路径
  String _getDefaultCoverPath(Song song) {
    final index = song.id.hashCode.abs() % 3;
    return 'assets/images/cover${index + 1}.jpg';
  }

  /// 清除封面缓存
  Future<void> clearCache() async {
    await _initCacheDir();

    // 清除内存缓存
    _memoryCache.clear();

    // 清除缓存元数据
    await _saveCacheMetadata({});

    // 删除所有缓存文件
    try {
      final files = await _cacheDir!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
    }
  }

  /// 清除过期的缓存（超过30天的缓存）
  Future<int> clearExpiredCache({int maxAgeDays = 30}) async {
    await _initCacheDir();

    int clearedCount = 0;
    final metadata = await _loadCacheMetadata();
    final now = DateTime.now();
    final maxAge = Duration(days: maxAgeDays);

    final expiredKeys = <String>[];

    for (final entry in metadata.entries) {
      final age = now.difference(entry.value.cachedAt);
      if (age > maxAge) {
        // 删除缓存文件
        try {
          final file = File(entry.value.cachePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
        }
        expiredKeys.add(entry.key);
        clearedCount++;
      }
    }

    // 从元数据中移除过期项
    for (final key in expiredKeys) {
      metadata.remove(key);
      _memoryCache.remove(key);
    }
    await _saveCacheMetadata(metadata);

    return clearedCount;
  }

  /// 获取缓存统计信息
  Future<CoverCacheStats> getCacheStats() async {
    await _initCacheDir();

    final metadata = await _loadCacheMetadata();
    int totalSize = 0;
    int fileCount = 0;

    try {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;
        }
      }
    } catch (e) {
    }

    return CoverCacheStats(
      fileCount: fileCount,
      totalSizeBytes: totalSize,
      memoryCacheCount: _memoryCache.length,
      metadataCount: metadata.length,
    );
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    await _initCacheDir();

    int totalSize = 0;
    try {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
    }

    return totalSize;
  }
}

/// 封面缓存信息
class CoverCacheInfo {
  final bool isCached;
  final String? cachePath;
  final bool isDefault;
  final bool isLoading;

  CoverCacheInfo({
    required this.isCached,
    this.cachePath,
    required this.isDefault,
    required this.isLoading,
  });
}

/// 封面缓存统计
class CoverCacheStats {
  final int fileCount;
  final int totalSizeBytes;
  final int memoryCacheCount;
  final int metadataCount;

  CoverCacheStats({
    required this.fileCount,
    required this.totalSizeBytes,
    required this.memoryCacheCount,
    required this.metadataCount,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  String toString() {
    return 'CoverCacheStats(files: $fileCount, size: $formattedSize, memory: $memoryCacheCount, metadata: $metadataCount)';
  }
}
