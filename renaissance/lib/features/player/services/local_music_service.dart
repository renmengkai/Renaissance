import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:audiotagger/models/audiofile.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'cover_art_service.dart';
import '../../../core/utils/platform_utils.dart';

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
  static const String _selectedFilesKey = 'selected_files_paths';
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

  /// 保存选择的文件路径列表
  static Future<void> _saveSelectedFiles(List<String?> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final validPaths = paths.whereType<String>().toList();
    await prefs.setStringList(_selectedFilesKey, validPaths);
  }

  /// 获取保存的文件路径列表
  static Future<List<String>> _getSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedFilesKey) ?? [];
  }

  /// 选择音乐文件夹/文件
  static Future<String?> selectMusicDirectory() async {
    if (PlatformUtils.isMobile) {
      return await _selectMusicFilesMobile();
    }
    return await _selectMusicDirectoryDesktop();
  }

  /// 移动端：选择音乐文件
  static Future<String?> _selectMusicFilesMobile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        await _saveSelectedFiles(result.paths);
        return result.paths.first;
      }
    } catch (e) {
    }
    return null;
  }

  /// 桌面端：选择音乐文件夹
  static Future<String?> _selectMusicDirectoryDesktop() async {
    try {
      final String? selectedDirectory = await getDirectoryPath(
        confirmButtonText: '选择音乐文件夹',
      );
      if (selectedDirectory != null) {
        await saveMusicDirectory(selectedDirectory);
        return selectedDirectory;
      }
    } catch (e) {
    }
    return null;
  }

  /// 获取音乐文件夹路径
  static Future<String> getMusicDirectory() async {
    if (PlatformUtils.isAndroid) {
      final extDir = Directory('/storage/emulated/0/Music');
      if (await extDir.exists()) return extDir.path;
    }

    if (PlatformUtils.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(path.join(appDir.path, 'Music'));
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir.path;
    }

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

  /// 扫描本地音乐文件
  static Future<List<Song>> scanLocalSongs() async {
    final List<Song> songs = [];

    try {
      if (PlatformUtils.isMobile) {
        return await _scanMobileSongs();
      }

      final musicDirPath = await getMusicDirectory();
      final musicDir = Directory(musicDirPath);

      if (!await musicDir.exists()) {
        return songs;
      }

      await for (final entity in musicDir.list()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final song = await _createSongFromFile(entity.path, songs.length);
            songs.add(song);
          }
        }
      }

      if (songs.isEmpty) {
        return _getFallbackSongs();
      }

      return songs;
    } catch (e) {
      return _getFallbackSongs();
    }
  }

  /// 移动端扫描歌曲
  static Future<List<Song>> _scanMobileSongs() async {
    final List<Song> songs = [];

    final savedPaths = await _getSavedFiles();
    if (savedPaths.isNotEmpty) {
      for (final filePath in savedPaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final ext = path.extension(filePath).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final song = await _createSongFromFile(filePath, songs.length);
            songs.add(song);
          }
        }
      }
    }

    if (PlatformUtils.isAndroid) {
      try {
        final musicDirPath = await getMusicDirectory();
        final musicDir = Directory(musicDirPath);

        if (await musicDir.exists()) {
          await for (final entity in musicDir.list()) {
            if (entity is File) {
              final ext = path.extension(entity.path).toLowerCase();
              if (_supportedExtensions.contains(ext)) {
                final song = await _createSongFromFile(entity.path, songs.length);
                if (!songs.any((s) => s.audioUrl == song.audioUrl)) {
                  songs.add(song);
                }
              }
            }
          }
        }
      } catch (e) {
      }
    }

    if (songs.isEmpty) {
      return _getFallbackSongs();
    }

    return songs;
  }

  /// 从文件创建 Song 对象
  static Future<Song> _createSongFromFile(String filePath, int index) async {
    final fileName = path.basenameWithoutExtension(filePath);

    String title = fileName;
    String artist = '未知艺术家';
    String album = '本地音乐';
    int year = DateTime.now().year;
    Duration duration = const Duration(minutes: 3, seconds: 30);

    final parts = fileName.split(' - ');
    if (parts.length >= 2) {
      artist = parts[0].trim();
      title = parts[1].trim();
    }

    if (Platform.isAndroid) {
      try {
        final tag = await _tagger.readTags(
          path: filePath,
        );

        if (tag != null) {
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
        }

        final audioFile = await _tagger.readAudioFile(path: filePath);
        if (audioFile != null && audioFile.length != null) {
          duration = Duration(milliseconds: audioFile.length!);
        }
      } catch (e) {
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
      return song.coverUrl;
    }
  }

  /// 获取备选歌曲
  static List<Song> _getFallbackSongs() {
    return [
      Song(
        id: 'local_0',
        title: 'Gentle Rain',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/eryliaa-gentle-rain-for-relaxation-and-sleep-337279.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#4ECDC4',
        hasGoldenLetter: true,
      ),
      Song(
        id: 'local_1',
        title: 'Ocean Waves',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/richardmultimedia-ocean-waves-250310.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#2C3E50',
        hasGoldenLetter: true,
      ),
      Song(
        id: 'local_2',
        title: 'Forest Birds',
        artist: '本地音乐',
        album: '本地专辑',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/empressnefertitimumbi-forest-bird-harmonies-258412.mp3',
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

  /// 打开音乐文件夹
  static Future<String> getMusicDirectoryPath() async {
    return await getMusicDirectory();
  }
}
