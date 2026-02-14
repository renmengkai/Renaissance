import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/music_source.dart';
import '../services/music_source_manager.dart';

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
  final Ref _ref;
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  bool _isLoading = false;

  AudioController(this._ref) : super(const AudioPlaybackStatus()) {
    _init();
  }

  void _init() {
    // 设置默认音量为 0.5
    _audioPlayer.setVolume(0.5);

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
    if (_isLoading) return;
    _isLoading = true;
    
    // 立即更新歌曲信息，不需要等待网络操作
    state = state.copyWith(
      isLoading: true, 
      currentSong: song, 
      errorMessage: null,
      position: Duration.zero,
      progress: 0.0,
    );

    // 执行后台加载并等待完成
    await _loadAudioInBackground(song);
  }

  Future<void> _loadAudioInBackground(Song song) async {
    try {
      String audioUrl = song.audioUrl;

      // 异步获取云存储签名URL
      if (song.sourceType == MusicSourceType.cloud && song.cloudKey != null) {
        final manager = _ref.read(musicSourceManagerProvider.notifier);
        try {
          audioUrl = await manager.getSignedUrlForSong(song);
        } catch (e) {
          // 获取签名URL失败不影响歌曲信息显示
        }
      }

      Duration? loadedDuration;
      bool loadSuccess = false;

      if (audioUrl.startsWith('http')) {
        try {
          loadedDuration = await _audioPlayer.setUrl(audioUrl);
          loadSuccess = true;
        } catch (e) {
          // 网络URL加载失败，尝试其他方式
        }
      } else if (audioUrl.startsWith('assets/')) {
        try {
          loadedDuration = await _audioPlayer.setAsset(audioUrl);
          loadSuccess = true;
        } catch (e) {
          // 资产文件加载失败
        }
      } else {
        // 本地文件路径
        final file = File(song.audioUrl);
        if (await file.exists()) {
          try {
            loadedDuration = await _audioPlayer.setFilePath(song.audioUrl);
            loadSuccess = true;
          } catch (e) {
            // 本地文件加载失败
          }
        }
      }

      // 如果加载失败，尝试使用原始audioUrl作为最后手段
      if (!loadSuccess && audioUrl.isNotEmpty) {
        try {
          loadedDuration = await _audioPlayer.setUrl(audioUrl);
          loadSuccess = true;
        } catch (e) {
          // 所有加载方式都失败
        }
      }

      final finalDuration = loadedDuration ?? _audioPlayer.duration;

      _isLoading = false;
      if (!loadSuccess) {
        // 使用自动清除错误信息的方法
        setErrorWithAutoClear('音频加载失败', duration: const Duration(seconds: 5));
      }
      state = state.copyWith(
        isLoading: false,
        duration: finalDuration ?? song.duration,
      );
    } catch (e, stackTrace) {
      _isLoading = false;
      // 使用自动清除错误信息的方法
      setErrorWithAutoClear('播放错误: $e', duration: const Duration(seconds: 5));
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        position: Duration.zero,
        progress: 0.0,
      );
    }
  }

  Future<void> play() async {

    try {
      // 检查播放器状态
      final playerState = _audioPlayer.playerState;

      
      // 如果播放器处于异常状态，尝试重新设置
      if (playerState.processingState == just_audio.ProcessingState.idle) {

        if (state.currentSong != null) {

          await loadSong(state.currentSong!);
        }
      }
      
      await _audioPlayer.play();

    } catch (e, stackTrace) {

      
      // 尝试重新加载歌曲并播放
      if (state.currentSong != null) {
        try {

          await loadSong(state.currentSong!);
          await Future.delayed(const Duration(milliseconds: 500));
          await _audioPlayer.play();

        } catch (reloadError) {

        }
      }
    }
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
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = const AudioPlaybackStatus();
  }

  void resetCompletion() {
    state = state.copyWith(isCompleted: false);
  }

  /// 清除错误信息
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// 设置错误信息并在指定时间后自动清除
  void setErrorWithAutoClear(String errorMessage, {Duration duration = const Duration(seconds: 5)}) {
    state = state.copyWith(errorMessage: errorMessage);
    // 延迟自动清除错误信息
    Future.delayed(duration, () {
      clearError();
    });
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
  return AudioController(ref);
});
