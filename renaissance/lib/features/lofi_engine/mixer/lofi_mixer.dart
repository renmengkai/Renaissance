import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../player/audio/audio_controller.dart';

// 白噪音分类枚举
enum WhiteNoiseCategory {
  whitenoise('白噪音', IconsFluent.volume3),
  tv('电视背景', IconsFluent.tv),
  clock('时钟滴答', IconsFluent.clock),
  paper('翻书声', IconsFluent.page),
  rain('雨声雷鸣', IconsFluent.weather_rain_showers_day),
  grass('风吹草动', IconsFluent.leaf),
  wind('微风轻拂', IconsFluent.weather_blowing_dust),
  bird('森林鸟鸣', IconsFluent.animal_cat),
  village('乡村傍晚', IconsFluent.home),
  ocean('海浪拍岸', IconsFluent.ocean),
  street('街道人声', IconsFluent.people);

  final String displayName;
  final String icon;
  const WhiteNoiseCategory(this.displayName, this.icon);
}

// 白噪音轨道信息
class WhiteNoiseTrack {
  final String assetPath;
  final WhiteNoiseCategory category;
  final String displayName;

  const WhiteNoiseTrack({
    required this.assetPath,
    required this.category,
    required this.displayName,
  });
}

// 白噪音音频文件列表（带分类）
final List<WhiteNoiseTrack> whiteNoiseTracks = [
  // 白噪音
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/dragon-studio-whitenoise-372485.mp3',
    category: WhiteNoiseCategory.whitenoise,
    displayName: '纯净白噪音',
  ),
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/freesound_community-whitenoise-34872.mp3',
    category: WhiteNoiseCategory.whitenoise,
    displayName: '柔和白噪音',
  ),
  // 电视背景
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/arunangshubanerjee-tv-playing-in-the-next-room-distant-and-indistinct-television-sound-360697.mp3',
    category: WhiteNoiseCategory.tv,
    displayName: '远处电视',
  ),
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/u_a4gfvwagf1-television-playing-411339.mp3',
    category: WhiteNoiseCategory.tv,
    displayName: '电视背景',
  ),
  // 时钟
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/freesound_community-ticking-clock_1-27477.mp3',
    category: WhiteNoiseCategory.clock,
    displayName: '时钟滴答',
  ),
  // 翻书
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/pwlpl-paper-page-flip-and-document-rustle-481168.mp3',
    category: WhiteNoiseCategory.paper,
    displayName: '翻书声',
  ),
  // 雨声
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/mindmist-night-rain-with-distant-thunder-321446.mp3',
    category: WhiteNoiseCategory.rain,
    displayName: '夜雨雷鸣',
  ),
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/eryliaa-gentle-rain-for-relaxation-and-sleep-337279.mp3',
    category: WhiteNoiseCategory.rain,
    displayName: '轻柔雨声',
  ),
  // 草地
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/dragon-studio-dry-field-grass-rustling-482893.mp3',
    category: WhiteNoiseCategory.grass,
    displayName: '草地沙沙',
  ),
  // 风声
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/storegraphic-soft-wind-318856.mp3',
    category: WhiteNoiseCategory.wind,
    displayName: '微风轻拂',
  ),
  // 鸟鸣
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/empressnefertitimumbi-forest-bird-harmonies-258412.mp3',
    category: WhiteNoiseCategory.bird,
    displayName: '森林鸟鸣',
  ),
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/nickype-voices-of-nature_birds_nature-sound-201923.mp3',
    category: WhiteNoiseCategory.bird,
    displayName: '自然鸟鸣',
  ),
  // 乡村
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/subhamita-evening-sound-effect-in-village-348670.mp3',
    category: WhiteNoiseCategory.village,
    displayName: '乡村傍晚',
  ),
  // 雷声（归入雨声类别）
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/u_vrs223ln83-loud-thunder-439064.mp3',
    category: WhiteNoiseCategory.rain,
    displayName: '远处雷声',
  ),
  // 海浪
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/richardmultimedia-ocean-waves-250310.mp3',
    category: WhiteNoiseCategory.ocean,
    displayName: '海浪拍岸',
  ),
  // 街道
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/freesound_community-strasse-menschen-verkehr-25499.mp3',
    category: WhiteNoiseCategory.street,
    displayName: '街道人声',
  ),
  // 其他音效
  const WhiteNoiseTrack(
    assetPath: 'assets/audio/da-wa-wa-i--115693.mp3',
    category: WhiteNoiseCategory.village,
    displayName: '环境音效',
  ),
];

// 活跃的白噪音轨道
class ActiveTrack {
  final AudioPlayer player;
  final WhiteNoiseTrack track;
  double volume;
  StreamSubscription? subscription;

  ActiveTrack({
    required this.player,
    required this.track,
    this.volume = 0.3,
    this.subscription,
  });

  Future<void> dispose() async {
    await subscription?.cancel();
    await player.dispose();
  }
}

// Lo-Fi 混音器状态
class LoFiMixerState {
  final double mainVolume;
  final Map<WhiteNoiseCategory, ActiveTrack> activeTracks;
  final bool isInitialized;
  final String? errorMessage;
  final bool hasWhiteNoise;

  const LoFiMixerState({
    this.mainVolume = 0.5,
    this.activeTracks = const {},
    this.isInitialized = false,
    this.errorMessage,
    this.hasWhiteNoise = false,
  });

  // 获取当前活跃的白噪音数量
  int get activeTrackCount => activeTracks.length;

  // 获取总的白噪音音量（用于主控制）
  double get totalWhiteNoiseVolume {
    if (activeTracks.isEmpty) return 0.0;
    double total = 0;
    for (final track in activeTracks.values) {
      total += track.volume;
    }
    return (total / activeTracks.length).clamp(0.0, 1.0);
  }

  // 获取指定类别的音量
  double getVolumeForCategory(WhiteNoiseCategory category) {
    return activeTracks[category]?.volume ?? 0.0;
  }

  // 检查类别是否活跃
  bool isCategoryActive(WhiteNoiseCategory category) {
    return activeTracks.containsKey(category);
  }

  LoFiMixerState copyWith({
    double? mainVolume,
    Map<WhiteNoiseCategory, ActiveTrack>? activeTracks,
    bool? isInitialized,
    String? errorMessage,
    bool? hasWhiteNoise,
  }) {
    return LoFiMixerState(
      mainVolume: mainVolume ?? this.mainVolume,
      activeTracks: activeTracks ?? this.activeTracks,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
      hasWhiteNoise: hasWhiteNoise ?? this.hasWhiteNoise,
    );
  }
}

// Lo-Fi 混音器控制器
class LoFiMixer extends StateNotifier<LoFiMixerState> {
  final Ref _ref;
  final Random _random = Random();

  LoFiMixer(this._ref) : super(const LoFiMixerState());

  Future<void> initialize() async {
    // 检查是否有白噪音文件
    bool hasWhiteNoise = whiteNoiseTracks.isNotEmpty;

    state = state.copyWith(
      isInitialized: true,
      hasWhiteNoise: hasWhiteNoise,
    );

    // 设置默认音量
    try {
      _ref.read(audioControllerProvider.notifier).setVolume(state.mainVolume);
    } catch (e) {
    }
  }

  // 切换指定类别的白噪音
  Future<void> toggleCategory(WhiteNoiseCategory category) async {
    if (state.isCategoryActive(category)) {
      // 关闭该类别
      await _removeCategory(category);
    } else {
      // 开启该类别，随机选择一个该类别下的音频
      await _addRandomTrackFromCategory(category);
    }
  }

  // 添加指定类别的随机白噪音
  Future<void> _addRandomTrackFromCategory(WhiteNoiseCategory category) async {
    final categoryTracks = whiteNoiseTracks
        .where((t) => t.category == category)
        .toList();
    
    if (categoryTracks.isEmpty) return;

    final track = categoryTracks[_random.nextInt(categoryTracks.length)];
    await _addTrack(track);
  }

  // 添加白噪音轨道
  Future<void> _addTrack(WhiteNoiseTrack track) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(track.assetPath);
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(0.3);
      await player.play();

      final activeTrack = ActiveTrack(
        player: player,
        track: track,
        volume: 0.3,
      );

      final newTracks = Map<WhiteNoiseCategory, ActiveTrack>.from(state.activeTracks);
      newTracks[track.category] = activeTrack;

      state = state.copyWith(activeTracks: newTracks);
    } catch (e) {
    }
  }

  // 移除指定类别的白噪音
  Future<void> _removeCategory(WhiteNoiseCategory category) async {
    final track = state.activeTracks[category];
    if (track == null) return;

    await track.dispose();

    final newTracks = Map<WhiteNoiseCategory, ActiveTrack>.from(state.activeTracks);
    newTracks.remove(category);

    state = state.copyWith(activeTracks: newTracks);
  }

  // 切换指定类别的白噪音文件（同类别内切换）
  Future<void> switchTrackInCategory(WhiteNoiseCategory category) async {
    final currentTrack = state.activeTracks[category];
    if (currentTrack == null) return;

    // 获取该类别的所有轨道
    final categoryTracks = whiteNoiseTracks
        .where((t) => t.category == category)
        .toList();
    
    if (categoryTracks.length <= 1) return;

    // 找到当前播放的索引，切换到下一个
    final currentIndex = categoryTracks.indexWhere((t) => t.assetPath == currentTrack.track.assetPath);
    final nextIndex = (currentIndex + 1) % categoryTracks.length;
    final nextTrack = categoryTracks[nextIndex];

    // 先移除当前
    await _removeCategory(category);
    // 添加新的
    await _addTrack(nextTrack);
  }

  // 设置主音量
  void setMainVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    state = state.copyWith(mainVolume: clampedVolume);

    try {
      _ref.read(audioControllerProvider.notifier).setVolume(clampedVolume);
    } catch (e) {
    }
  }

  // 设置指定类别的音量
  void setCategoryVolume(WhiteNoiseCategory category, double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final track = state.activeTracks[category];
    
    if (track != null) {
      track.volume = clampedVolume;
      track.player.setVolume(clampedVolume);

      // 如果音量为0，暂停播放；如果大于0且未播放，开始播放
      if (clampedVolume == 0) {
        track.player.pause();
      } else if (!track.player.playing) {
        track.player.play();
      }

      // 触发状态更新
      state = state.copyWith(activeTracks: Map.from(state.activeTracks));
    }
  }

  // 设置所有白噪音的总音量
  void setWhiteNoiseVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    
    for (final entry in state.activeTracks.entries) {
      final track = entry.value;
      track.volume = clampedVolume;
      track.player.setVolume(clampedVolume);

      if (clampedVolume == 0) {
        track.player.pause();
      } else if (!track.player.playing) {
        track.player.play();
      }
    }

    state = state.copyWith(activeTracks: Map.from(state.activeTracks));
  }

  // 播放/暂停指定类别
  Future<void> toggleCategoryPlayback(WhiteNoiseCategory category) async {
    final track = state.activeTracks[category];
    if (track == null) return;

    if (track.player.playing) {
      await track.player.pause();
    } else {
      await track.player.play();
    }
    
    // 触发状态更新
    state = state.copyWith(activeTracks: Map.from(state.activeTracks));
  }

  // 播放所有白噪音
  Future<void> playAll() async {
    for (final track in state.activeTracks.values) {
      if (track.volume > 0) {
        await track.player.play();
      }
    }
  }

  // 暂停所有白噪音
  Future<void> pauseAll() async {
    for (final track in state.activeTracks.values) {
      await track.player.pause();
    }
  }

  // 停止所有白噪音并清空
  Future<void> stopAll() async {
    for (final track in state.activeTracks.values) {
      await track.dispose();
    }
    
    state = state.copyWith(activeTracks: {});
  }

  @override
  void dispose() {
    for (final track in state.activeTracks.values) {
      track.dispose();
    }
    super.dispose();
  }
}

// Provider
final loFiMixerProvider = StateNotifierProvider<LoFiMixer, LoFiMixerState>((ref) {
  return LoFiMixer(ref);
});

// 图标常量（避免依赖 fluent_ui）
class IconsFluent {
  static const String volume3 = 'volume3';
  static const String tv = 'tv';
  static const String clock = 'clock';
  static const String page = 'page';
  static const String weather_rain_showers_day = 'weather_rain_showers_day';
  static const String leaf = 'leaf';
  static const String weather_blowing_dust = 'weather_blowing_dust';
  static const String animal_cat = 'animal_cat';
  static const String home = 'home';
  static const String ocean = 'ocean';
  static const String people = 'people';
}
