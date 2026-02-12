import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/song.dart';

/// 封面获取服务
/// 负责从多个来源获取歌曲封面图片
class CoverArtService {
  static final CoverArtService _instance = CoverArtService._internal();
  factory CoverArtService() => _instance;
  CoverArtService._internal();

  // 缓存目录
  Directory? _cacheDir;

  // 初始化缓存目录
  Future<void> _initCacheDir() async {
    if (_cacheDir != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'Renaissance', 'CoverCache'));

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  /// 获取歌曲封面
  /// 优先级：1.音频文件内嵌封面 2.在线搜索 3.默认封面
  Future<String> getCoverArt(Song song) async {
    await _initCacheDir();

    // 生成缓存文件名
    final cacheFileName = _generateCacheFileName(song);
    final cachePath = path.join(_cacheDir!.path, cacheFileName);

    // 检查缓存
    if (await File(cachePath).exists()) {
      debugPrint('Using cached cover for: ${song.title}');
      return cachePath;
    }

    // 1. 尝试从音频文件提取封面
    final embeddedCover = await _extractEmbeddedCover(song.audioUrl);
    if (embeddedCover != null) {
      await _saveCoverToCache(embeddedCover, cachePath);
      debugPrint('Extracted embedded cover for: ${song.title}');
      return cachePath;
    }

    // 2. 尝试在线搜索封面
    final onlineCover = await _searchOnlineCover(song);
    if (onlineCover != null) {
      await _saveCoverToCache(onlineCover, cachePath);
      debugPrint('Found online cover for: ${song.title}');
      return cachePath;
    }

    // 3. 返回默认封面
    debugPrint('Using default cover for: ${song.title}');
    return _getDefaultCoverPath(song);
  }

  /// 生成缓存文件名
  String _generateCacheFileName(Song song) {
    // 使用歌曲信息生成唯一标识
    final identifier = '${song.artist}_${song.title}_${song.album}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u4e00-\u9fa5]'), '_')
        .toLowerCase();
    return '${identifier}_cover.jpg';
  }

  /// 从音频文件提取内嵌封面
  Future<Uint8List?> _extractEmbeddedCover(String audioPath) async {
    try {
      // 检查是否是本地文件路径
      if (audioPath.startsWith('assets/')) {
        return null;
      }

      final file = File(audioPath);
      if (!await file.exists()) {
        return null;
      }

      // 读取音频文件并提取封面
      final bytes = await file.readAsBytes();
      final ext = path.extension(audioPath).toLowerCase();

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
      debugPrint('Error extracting embedded cover: $e');
      return null;
    }
  }

  /// 从MP3文件提取ID3标签中的封面
  Uint8List? _extractMp3Cover(Uint8List bytes) {
    try {
      // 查找ID3标签
      // ID3v2.3 和 ID3v2.4 中封面的帧标识是 APIC
      final apicPattern = [0x41, 0x50, 0x49, 0x43]; // "APIC"

      for (int i = 0; i < bytes.length - 4; i++) {
        if (bytes[i] == apicPattern[0] &&
            bytes[i + 1] == apicPattern[1] &&
            bytes[i + 2] == apicPattern[2] &&
            bytes[i + 3] == apicPattern[3]) {

          // 找到APIC帧，跳过帧头和文本编码字节
          int offset = i + 10; // 帧头(4) + 大小(4) + 标志(2)

          // 跳过文本编码字节
          offset++;

          // 跳过MIME类型（以null结尾）
          while (offset < bytes.length && bytes[offset] != 0) {
            offset++;
          }
          offset++; // 跳过null

          // 跳过图片类型字节
          offset++;

          // 跳过描述（以null结尾）
          while (offset < bytes.length && bytes[offset] != 0) {
            offset++;
          }
          offset++; // 跳过null

          // 查找图片数据的结束位置（下一个帧或标签结束）
          int endOffset = offset;
          while (endOffset < bytes.length - 4) {
            // 检查是否是下一个帧的开始
            if ((bytes[endOffset] >= 0x41 && bytes[endOffset] <= 0x5A) ||
                (bytes[endOffset] >= 0x30 && bytes[endOffset] <= 0x39)) {
              // 检查接下来的3个字节是否也是大写字母或数字
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
      debugPrint('Error extracting MP3 cover: $e');
    }
    return null;
  }

  /// 从FLAC文件提取封面
  Uint8List? _extractFlacCover(Uint8List bytes) {
    try {
      // FLAC使用Vorbis Comment和PICTURE块
      // 查找PICTURE块（块类型6）
      int offset = 4; // 跳过"fLaC"标记

      while (offset < bytes.length - 4) {
        final blockType = bytes[offset] & 0x7F;
        final isLastBlock = (bytes[offset] & 0x80) != 0;

        final blockSize = (bytes[offset + 1] << 16) |
                         (bytes[offset + 2] << 8) |
                         bytes[offset + 3];

        if (blockType == 6) {
          // PICTURE块
          // 跳过PICTURE类型(4) + MIME长度(4) + MIME + 描述长度(4) + 描述
          int pictureOffset = offset + 4;

          // 跳过PICTURE类型
          pictureOffset += 4;

          // 读取MIME类型长度
          final mimeLength = (bytes[pictureOffset] << 24) |
                            (bytes[pictureOffset + 1] << 16) |
                            (bytes[pictureOffset + 2] << 8) |
                            bytes[pictureOffset + 3];
          pictureOffset += 4 + mimeLength;

          // 读取描述长度
          final descLength = (bytes[pictureOffset] << 24) |
                            (bytes[pictureOffset + 1] << 16) |
                            (bytes[pictureOffset + 2] << 8) |
                            bytes[pictureOffset + 3];
          pictureOffset += 4 + descLength;

          // 跳过宽度(4) + 高度(4) + 颜色深度(4) + 颜色数(4)
          pictureOffset += 16;

          // 读取图片数据长度
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
      debugPrint('Error extracting FLAC cover: $e');
    }
    return null;
  }

  /// 从MP4/M4A文件提取封面
  Uint8List? _extractMp4Cover(Uint8List bytes) {
    try {
      // MP4/M4A使用atom/box结构，封面通常在covr atom中
      return _findMp4Atom(bytes, 'covr');
    } catch (e) {
      debugPrint('Error extracting MP4 cover: $e');
    }
    return null;
  }

  /// 递归查找MP4 atom
  Uint8List? _findMp4Atom(Uint8List bytes, String atomName) {
    int offset = 0;

    // 跳过ftyp box
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
        // 找到目标atom，跳过atom头和版本/标志字节
        final dataOffset = offset + 8 + 8; // atom头(8) + 版本/标志(8)
        if (dataOffset < offset + size) {
          return Uint8List.sublistView(bytes, dataOffset, offset + size);
        }
      }

      // 递归搜索moov和udta容器
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

  /// 在线搜索封面
  Future<Uint8List?> _searchOnlineCover(Song song) async {
    // 尝试多个API源
    final sources = [
      _searchFromMusicBrainz,
      _searchFromLastFm,
      _searchFromDeezer,
    ];

    for (final source in sources) {
      try {
        final cover = await source(song);
        if (cover != null) return cover;
      } catch (e) {
        debugPrint('Error searching cover from ${source.toString()}: $e');
      }
    }

    return null;
  }

  /// 从MusicBrainz搜索封面
  Future<Uint8List?> _searchFromMusicBrainz(Song song) async {
    try {
      // 构建搜索查询
      final query = Uri.encodeComponent('${song.title} ${song.artist}');
      final searchUrl = 'https://musicbrainz.org/ws/2/release/?query=$query&fmt=json&limit=1';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'User-Agent': 'RenaissanceMusicApp/1.0'},
      );

      if (response.statusCode == 200) {
        // 解析响应获取release ID
        final releaseMatch = RegExp(r'"id":"([^"]+)"').firstMatch(response.body);
        if (releaseMatch != null) {
          final releaseId = releaseMatch.group(1);

          // 获取封面
          final coverUrl = 'https://coverartarchive.org/release/$releaseId/front';
          final coverResponse = await http.get(Uri.parse(coverUrl));

          if (coverResponse.statusCode == 200) {
            return coverResponse.bodyBytes;
          }
        }
      }
    } catch (e) {
      debugPrint('MusicBrainz search error: $e');
    }
    return null;
  }
  /// 从Last.fm搜索封面
  Future<Uint8List?> _searchFromLastFm(Song song) async {
    try {
      // 注意：需要API key，这里使用公开的图片搜索方式
      final query = Uri.encodeComponent('${song.title} ${song.artist} album cover');
      final searchUrl = 'https://www.last.fm/music/${Uri.encodeComponent(song.artist)}/${Uri.encodeComponent(song.album)}/+images';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.0',
        },
      );

      if (response.statusCode == 200) {
        // 从HTML中提取图片URL
        final imageMatch = RegExp(r'src="([^"]+\.(?:jpg|jpeg|png))"').firstMatch(response.body);
        if (imageMatch != null) {
          var imageUrl = imageMatch.group(1)!;
          // 确保URL是完整的
          if (imageUrl.startsWith('//')) {
            imageUrl = 'https:$imageUrl';
          } else if (imageUrl.startsWith('/')) {
            imageUrl = 'https://www.last.fm$imageUrl';
          }

          final imageResponse = await http.get(Uri.parse(imageUrl));
          if (imageResponse.statusCode == 200) {
            return imageResponse.bodyBytes;
          }
        }
      }
    } catch (e) {
      debugPrint('Last.fm search error: $e');
    }
    return null;
  }

  /// 从Deezer搜索封面
  Future<Uint8List?> _searchFromDeezer(Song song) async {
    try {
      final query = Uri.encodeComponent('${song.title} ${song.artist}');
      final searchUrl = 'https://api.deezer.com/search?q=$query&limit=1';

      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        // 从JSON响应中提取封面URL
        final coverMatch = RegExp(r'"cover_big":"([^"]+)"').firstMatch(response.body);
        if (coverMatch != null) {
          var coverUrl = coverMatch.group(1)!;
          // 处理转义的URL
          coverUrl = coverUrl.replaceAll(r'\/', '/');

          final coverResponse = await http.get(Uri.parse(coverUrl));
          if (coverResponse.statusCode == 200) {
            return coverResponse.bodyBytes;
          }
        }
      }
    } catch (e) {
      debugPrint('Deezer search error: $e');
    }
    return null;
  }

  /// 保存封面到缓存
  Future<void> _saveCoverToCache(Uint8List imageData, String cachePath) async {
    try {
      // 使用image包处理图片，确保格式正确并压缩
      final image = img.decodeImage(imageData);
      if (image != null) {
        // 调整大小以提高性能
        final resized = img.copyResize(image, width: 500);
        final jpegData = img.encodeJpg(resized, quality: 85);

        final file = File(cachePath);
        await file.writeAsBytes(jpegData);
      } else {
        // 如果无法解码，直接保存原始数据
        final file = File(cachePath);
        await file.writeAsBytes(imageData);
      }
    } catch (e) {
      debugPrint('Error saving cover to cache: $e');
      // 直接保存原始数据作为后备
      try {
        final file = File(cachePath);
        await file.writeAsBytes(imageData);
      } catch (_) {}
    }
  }

  /// 获取默认封面路径
  String _getDefaultCoverPath(Song song) {
    // 根据歌曲ID的哈希值选择默认封面
    final index = song.id.hashCode.abs() % 3;
    return 'assets/images/cover${index + 1}.jpg';
  }

  /// 清除封面缓存
  Future<void> clearCache() async {
    await _initCacheDir();

    try {
      final files = await _cacheDir!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      debugPrint('Cover cache cleared');
    } catch (e) {
      debugPrint('Error clearing cover cache: $e');
    }
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
      debugPrint('Error calculating cache size: $e');
    }

    return totalSize;
  }
}
