import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import '../models/song.dart';

// 播放器状态
class AudioPlaybackStatus {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double progress;
  final Song? currentSong;
  final bool isCompleted;
  final String? errorMessage;

  const AudioPlaybackStatus({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.progress = 0.0,
    this.currentSong,
    this.isCompleted = false,
    this.errorMessage,
  });

  AudioPlaybackStatus copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    double? progress,
    Song? currentSong,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return AudioPlaybackStatus(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      progress: progress ?? this.progress,
      currentSong: currentSong ?? this.currentSong,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 音频控制器
class AudioController extends StateNotifier<AudioPlaybackStatus> {
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;

  AudioController() : super(const AudioPlaybackStatus()) {
    _init();
  }

  void _init() {
    // 监听播放位置
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      final duration = _audioPlayer.duration ?? Duration.zero;
      final progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
      
      state = state.copyWith(
        position: position,
        duration: duration,
        progress: progress.clamp(0.0, 1.0),
      );
    });

    // 监听播放状态
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == just_audio.ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          isCompleted: true,
          progress: 1.0,
        );
      } else {
        state = state.copyWith(
          isPlaying: playerState.playing,
          isCompleted: false,
        );
      }
    });
  }

  Future<void> loadSong(Song song) async {
    state = state.copyWith(isLoading: true, currentSong: song, errorMessage: null);

    try {
      // 支持网络音频、本地文件和asset音频
      if (song.audioUrl.startsWith('http')) {
        debugPrint('[AudioController] Loading network audio: ${song.audioUrl}');
        await _audioPlayer.setUrl(song.audioUrl);
      } else if (song.audioUrl.startsWith('assets/')) {
        debugPrint('[AudioController] Loading asset audio: ${song.audioUrl}');
        await _audioPlayer.setAsset(song.audioUrl);
      } else {
        // 本地文件路径
        debugPrint('[AudioController] Loading local file audio: ${song.audioUrl}');
        final file = File(song.audioUrl);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('[AudioController] File exists, size: $fileSize bytes');
          
          // 检查文件是否有读取权限
          try {
            await file.openRead(0, 1).first;
            debugPrint('[AudioController] File is readable');
          } catch (e) {
            debugPrint('[AudioController] File is not readable: $e');
            throw Exception('无法读取音频文件，请检查文件权限: ${song.audioUrl}');
          }
          
          await _audioPlayer.setFilePath(song.audioUrl);
        } else {
          debugPrint('[AudioController] File does not exist: ${song.audioUrl}');
          throw Exception('音频文件不存在: ${song.audioUrl}');
        }
      }
      
      // 等待音频加载完成并获取时长
      await _audioPlayer.load();
      final loadedDuration = _audioPlayer.duration;
      debugPrint('[AudioController] Audio loaded successfully, duration: $loadedDuration');
      
      state = state.copyWith(
        isLoading: false,
        duration: loadedDuration ?? song.duration,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      final errorMsg = '加载音频失败: $e';
      debugPrint('[AudioController] Error loading audio: $e');
      debugPrint('[AudioController] Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final duration = state.duration;
    final position = Duration(
      milliseconds: (duration.inMilliseconds * progress).toInt(),
    );
    await seek(position);
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(clampedVolume);
    debugPrint('[AudioController] Volume set to: $clampedVolume');
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = const AudioPlaybackStatus();
  }

  void resetCompletion() {
    state = state.copyWith(isCompleted: false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Provider
final audioControllerProvider = StateNotifierProvider<AudioController, AudioPlaybackStatus>((ref) {
  return AudioController();
});
