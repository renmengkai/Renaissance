import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:audiotagger/models/audiofile.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'cover_art_service.dart';

/// 本地音乐文件扫描服务
class LocalMusicService {
  static final List<String> _supportedExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
  ];

  static const String _musicDirectoryKey = 'music_directory_path';
  static final _tagger = Audiotagger();

  /// 获取保存的音乐文件夹路径
  static Future<String?> getSavedMusicDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_musicDirectoryKey);
  }

  /// 保存音乐文件夹路径
  static Future<void> saveMusicDirectory(String directoryPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_musicDirectoryKey, directoryPath);
  }

  /// 选择音乐文件夹
  static Future<String?> selectMusicDirectory() async {
    try {
      final String? selectedDirectory = await getDirectoryPath(
        confirmButtonText: '选择音乐文件夹',
      );
      if (selectedDirectory != null) {
        await saveMusicDirectory(selectedDirectory);
        debugPrint('Selected music directory: $selectedDirectory');
        return selectedDirectory;
      }
    } catch (e) {
      debugPrint('Error selecting directory: $e');
    }
    return null;
  }

  /// 获取音乐文件夹路径（优先使用用户选择的，否则使用默认）
  static Future<String> getMusicDirectory() async {
    final savedDir = await getSavedMusicDirectory();
    if (savedDir != null) {
      final dir = Directory(savedDir);
      if (await dir.exists()) {
        return savedDir;
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(path.join(appDir.path, 'Renaissance', 'Music'));

    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }

    return musicDir.path;
  }

  /// 扫描本地音乐文件（快速扫描，不等待封面加载）
  static Future<List<Song>> scanLocalSongs() async {
    final List<Song> songs = [];

    try {
      final musicDirPath = await getMusicDirectory();
      final musicDir = Directory(musicDirPath);

      debugPrint('Scanning music directory: $musicDirPath');

      if (!await musicDir.exists()) {
        debugPrint('Music directory does not exist');
        return songs;
      }

      await for (final entity in musicDir.list()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final song = await _createSongFromFile(entity.path, songs.length);
            songs.add(song);
            debugPrint('Found song: ${song.title} by ${song.artist}');
          }
        }
      }

      if (songs.isEmpty) {
        debugPrint('No local songs found, using fallback songs');
        return _getFallbackSongs();
      }

      debugPrint('Total songs found: ${songs.length}');
    } catch (e, stackTrace) {
      debugPrint('Error scanning local songs: $e');
      debugPrint(stackTrace.toString());
      return _getFallbackSongs();
    }

    return songs;
  }

  /// 从文件创建 Song 对象（尝试读取元数据）
  static Future<Song> _createSongFromFile(String filePath, int index) async {
    final fileName = path.basenameWithoutExtension(filePath);

    // 默认值
    String title = fileName;
    String artist = '未知艺术家';
    String album = '本地音乐';
    int year = DateTime.now().year;
    Duration duration = const Duration(minutes: 3, seconds: 30);

    // 尝试从文件名解析
    final parts = fileName.split(' - ');
    if (parts.length >= 2) {
      artist = parts[0].trim();
      title = parts[1].trim();
    }

    // 尝试读取音频元数据 (仅支持 Android)
    if (Platform.isAndroid) {
      try {
        final tag = await _tagger.readTags(
          path: filePath,
        );

        if (tag != null) {
          // 使用元数据覆盖默认值
          if (tag.title != null && tag.title!.isNotEmpty) {
            title = tag.title!;
          }
          if (tag.artist != null && tag.artist!.isNotEmpty) {
            artist = tag.artist!;
          }
          if (tag.album != null && tag.album!.isNotEmpty) {
            album = tag.album!;
          }
          if (tag.year != null && tag.year!.isNotEmpty) {
            year = int.tryParse(tag.year!) ?? year;
          }

          debugPrint('[Metadata] $title by $artist from $album ($year)');
        }

        // 读取音频时长
        final audioFile = await _tagger.readAudioFile(path: filePath);
        if (audioFile != null && audioFile.length != null) {
          duration = Duration(milliseconds: audioFile.length!);
        }
      } catch (e) {
        debugPrint('[Metadata] Could not read metadata for $filePath: $e');
      }
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

    final uniqueId = 'local_file_${filePath.hashCode}';

    return Song(
      id: uniqueId,
      title: title,
      artist: artist,
      album: album,
      year: year,
      coverUrl: 'assets/images/cover${(index % 3) + 1}.jpg',
      audioUrl: filePath,
      duration: duration,
      dominantColor: color,
      hasGoldenLetter: index < 3,
    );
  }

  /// 异步加载歌曲封面
  static Future<String> loadSongCoverArt(Song song) async {
    try {
      final coverArtService = CoverArtService();
      return await coverArtService.getCoverArt(song).timeout(
        const Duration(seconds: 10),
        onTimeout: () => song.coverUrl,
      );
    } catch (e) {
      debugPrint('Error loading cover art: $e');
      return song.coverUrl;
    }
  }

  /// 获取备选歌曲（当本地没有歌曲时使用）
  static List<Song> _getFallbackSongs() {
    return [
      Song(
        id: 'local_0',
        title: 'Summer Breeze',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/song1.wav',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#4ECDC4',
        hasGoldenLetter: true,
      ),
      Song(
        id: 'local_1',
        title: 'Midnight Dreams',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/song2.wav',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#2C3E50',
        hasGoldenLetter: true,
      ),
      Song(
        id: 'local_2',
        title: 'Ocean Waves',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/song3.wav',
        duration: const Duration(minutes: 4, seconds: 15),
        dominantColor: '#1E90FF',
        hasGoldenLetter: false,
      ),
    ];
  }

  /// 创建本地音乐播放列表
  static Future<Playlist> createLocalPlaylist() async {
    final songs = await scanLocalSongs();
    return Playlist(
      id: 'local_playlist',
      name: '本地音乐',
      description: '扫描自本地文件夹',
      songs: songs,
      createdAt: DateTime.now(),
      coverUrl: 'assets/images/cover1.jpg',
    );
  }

  /// 打开音乐文件夹（用于提示用户）
  static Future<String> getMusicDirectoryPath() async {
    return await getMusicDirectory();
  }
}
