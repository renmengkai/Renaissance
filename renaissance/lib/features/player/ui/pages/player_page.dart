import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Slider, IconButton, Divider, Colors, showDialog, Tooltip, ButtonStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../shared/components/window_controls_stub.dart'
    if (dart.library.io) '../../../../shared/components/window_controls_impl.dart';
import '../../../blindbox/blur/blurred_cover.dart';
import '../../../golden_letter/repository/letter_repository.dart';
import '../../../golden_letter/ui/golden_letter_widget.dart';
import '../../../golden_letter/ui/write_letter_dialog.dart';
import '../../../lofi_engine/mixer/lofi_mixer.dart';
import '../../../lofi_engine/mixer/mixer_panel.dart';
import '../../../settings/ui/settings_page.dart';
import '../../audio/audio_controller.dart';
import '../../audio/playlist_controller.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/music_source.dart';
import '../../services/local_music_service.dart';
import '../../services/music_source_manager.dart';
import '../../services/cover_art_service.dart';
import '../../../../shared/widgets/vinyl_cover.dart';
import '../../../../shared/widgets/enhanced_song_list_item.dart';
import '../../../../shared/widgets/player_controls.dart';
import '../../../../shared/widgets/animations.dart';

typedef PlayerState = AudioPlaybackStatus;

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _showMixer = false;
  bool _showLetter = false;
  List<Song> _localSongs = [];
  bool _isLoading = true;
  String? _musicDirectoryPath;

  String? _currentCoverPath;
  bool _isLoadingCover = false;

  int _currentIndex = -1;
  bool _isBlindBoxRevealed = false;

  // 当前启用的音乐源列表
  List<MusicSource> _enabledSources = [];

  // 分页加载相关状态
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  static const int _pageSize = 100;
  final ScrollController _scrollController = ScrollController();
  // 自动连续加载模式（无需等待用户滚动）
  bool _autoLoadMode = true;

  // 歌曲封面缓存
  final Map<String, String> _songCoverCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loFiMixerProvider.notifier).initialize();
      _loadSongs();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSongs();
    }
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
    });

    final stopwatch = Stopwatch()..start();

    // 使用 MusicSourceManager 获取所有启用的音乐源中的歌曲（第一页）
    final manager = ref.read(musicSourceManagerProvider.notifier);
    final sources = ref.read(musicSourceManagerProvider);
    debugPrint('[PlayerPage] Sources: ${sources.map((s) => '${s.name} (enabled: ${s.isEnabled})').toList()}');

    final songs = await manager.getAllSongs(page: 0, pageSize: _pageSize);
    final musicPath = await LocalMusicService.getMusicDirectoryPath();

    if (songs.isNotEmpty) {
      final allSongsPlaylist = Playlist(
        id: 'all_songs',
        name: '全部音乐',
        songs: songs,
      );
      ref.read(playlistControllerProvider.notifier).loadPlaylist(allSongsPlaylist);
    }

    final enabledSources = sources.where((s) => s.isEnabled).toList();
    debugPrint('[PlayerPage] Enabled sources: ${enabledSources.map((s) => '${s.name} (enabled: ${s.isEnabled})').toList()}');

    setState(() {
      _localSongs = songs;
      _isLoading = false;
      _hasMoreData = songs.length >= _pageSize;
      _musicDirectoryPath = musicPath;
      _enabledSources = enabledSources;
    });

    stopwatch.stop();
    debugPrint('[PlayerPage] Loaded ${songs.length} songs in ${stopwatch.elapsedMilliseconds}ms');

    // 设置封面加载回调，当异步加载完成时更新UI
    CoverArtService().onCoverLoaded = (song, coverPath) {
      if (mounted && coverPath.isNotEmpty) {
        setState(() {
          _songCoverCache[song.id] = coverPath;
        });
      }
    };

    // 异步预加载封面，不阻塞UI
    // 注意：preloadCovers 已经在后台异步加载封面到 CoverArtService 的内存缓存
    CoverArtService().preloadCovers(songs);

    // 延迟加载封面到UI缓存，确保不阻塞歌曲加载和播放
    // 使用延迟执行，让歌曲列表先显示出来
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadSongCovers(songs);
      }
    });

    // 自动连续加载模式：如果还有更多数据，自动开始加载下一页
    if (_autoLoadMode && _hasMoreData && songs.length >= _pageSize) {
      debugPrint('[PlayerPage] Auto load mode: starting to load next pages...');
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _loadMoreSongs();
        }
      });
    }
  }

  /// 异步加载每首歌的封面 - 使用批量并行加载，避免阻塞UI和音乐播放
  void _loadSongCovers(List<Song> songs) async {
    final coverArtService = CoverArtService();

    // 首先检查哪些歌曲已经有缓存（内存或磁盘）
    final songsNeedLoading = <Song>[];
    final cachedCovers = <String, String>{};

    for (final song in songs) {
      // 同步检查内存缓存，不阻塞
      final cachedPath = coverArtService.getCoverFromMemoryCache(song);
      if (cachedPath != null && cachedPath.isNotEmpty) {
        cachedCovers[song.id] = cachedPath;
      } else {
        // 内存中没有，需要异步检查磁盘缓存或网络加载
        songsNeedLoading.add(song);
      }
    }

    // 批量更新内存中已缓存的封面到UI
    if (mounted && cachedCovers.isNotEmpty) {
      setState(() {
        _songCoverCache.addAll(cachedCovers);
      });
    }

    // 如果没有需要加载的封面，直接返回
    if (songsNeedLoading.isEmpty) return;

    debugPrint(
        '[PlayerPage] Loading covers for ${songsNeedLoading.length} songs (skipped ${cachedCovers.length} memory cached)');

    // 分批并行加载剩余需要加载的封面
    const batchSize = 5;
    for (int i = 0; i < songsNeedLoading.length; i += batchSize) {
      final batch = songsNeedLoading.skip(i).take(batchSize).toList();

      // 并行加载当前批次的封面
      final futures = batch.map((song) async {
        try {
          // getCoverArt 会检查磁盘缓存，如果没有则从网络加载并保存到磁盘
          final coverPath = await coverArtService.getCoverArt(song);
          return (song.id, coverPath);
        } catch (e) {
          debugPrint('[PlayerPage] Error loading cover for ${song.title}: $e');
          return (song.id, null);
        }
      });

      final results = await Future.wait(futures);

      // 批量更新缓存，只更新有变化的（排除默认封面）
      if (mounted) {
        final newCovers = <String, String>{};
        for (final (songId, coverPath) in results) {
          if (coverPath != null &&
              coverPath.isNotEmpty &&
              !coverPath.startsWith('assets/') && // 排除默认封面
              _songCoverCache[songId] != coverPath) {
            newCovers[songId] = coverPath;
          }
        }

        if (newCovers.isNotEmpty) {
          setState(() {
            _songCoverCache.addAll(newCovers);
          });
        }
      }

      // 每批之间添加小延迟，避免请求过于频繁影响音乐播放
      if (i + batchSize < songsNeedLoading.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// 加载更多歌曲（分页加载）
  Future<void> _loadMoreSongs() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    debugPrint('[PlayerPage] Loading more songs, page: $nextPage');

    try {
      final manager = ref.read(musicSourceManagerProvider.notifier);
      final newSongs = await manager.getAllSongs(page: nextPage, pageSize: _pageSize);

      if (newSongs.isEmpty) {
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
        });
        debugPrint('[PlayerPage] No more songs to load');
        return;
      }

      setState(() {
        _localSongs.addAll(newSongs);
        _currentPage = nextPage;
        _hasMoreData = newSongs.length >= _pageSize;
        _isLoadingMore = false;
      });

      debugPrint('[PlayerPage] Loaded ${newSongs.length} more songs, total: ${_localSongs.length}');

      // 异步预加载新加载歌曲的封面
      CoverArtService().preloadCovers(newSongs);
      _loadSongCovers(newSongs);

      // 自动连续加载模式：如果还有更多数据，继续加载下一页
      if (_autoLoadMode && _hasMoreData) {
        debugPrint('[PlayerPage] Auto load mode: loading next page...');
        // 使用 Future.delayed 避免阻塞UI
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadMoreSongs();
          }
        });
      }
    } catch (e) {
      debugPrint('[PlayerPage] Error loading more songs: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _selectMusicDirectory() async {
    final selectedDir = await LocalMusicService.selectMusicDirectory();
    if (selectedDir != null) {
      await _loadSongs();
    }
  }

  void _loadAndPlaySong(Song song) async {
    final audioController = ref.read(audioControllerProvider.notifier);
    final letterController = ref.read(letterControllerProvider.notifier);
    final playlistController = ref.read(playlistControllerProvider.notifier);

    letterController.reset();

    final index = _localSongs.indexWhere((s) => s.id == song.id);
    setState(() {
      _showLetter = false;
      _currentCoverPath = null;
      _isLoadingCover = true;
      _currentIndex = index;
      _isBlindBoxRevealed = false;
    });

    playlistController.playSong(song);

    // 暂停封面加载，优先保证音乐播放流畅
    CoverArtService().pauseLoading();

    // 加载歌曲（现在是异步的，不会阻塞UI）
    audioController.loadSong(song).then((_) {
      // 歌曲加载完成后播放
      audioController.play();

      // 延迟恢复封面加载，等待音乐缓存足够
      // 给音乐播放留出网络带宽
      Future.delayed(const Duration(seconds: 3), () {
        CoverArtService().resumeLoading();
      });
    });

    // 封面加载在后台执行，不阻塞UI更新
    _loadCoverInBackground(song);
  }

  void _loadCoverInBackground(Song song) async {
    final coverPath = await LocalMusicService.loadSongCoverArt(song);
    if (mounted) {
      setState(() {
        _currentCoverPath = coverPath;
        _isLoadingCover = false;
      });
    }
  }

  void _playNext() {
    if (_localSongs.isEmpty) return;

    final playMode = ref.read(playlistControllerProvider).playMode;
    int nextIndex;

    if (playMode == PlayMode.shuffle || playMode == PlayMode.blindBox) {
      nextIndex = DateTime.now().millisecondsSinceEpoch % _localSongs.length;
    } else {
      nextIndex = (_currentIndex + 1) % _localSongs.length;
    }

    ref.read(playlistControllerProvider.notifier).next();

    _loadAndPlaySong(_localSongs[nextIndex]);
  }

  void _playPrevious() {
    if (_localSongs.isEmpty) return;

    final playMode = ref.read(playlistControllerProvider).playMode;
    int prevIndex;

    if (playMode == PlayMode.shuffle || playMode == PlayMode.blindBox) {
      prevIndex = DateTime.now().millisecondsSinceEpoch % _localSongs.length;
    } else {
      prevIndex = _currentIndex <= 0 ? _localSongs.length - 1 : _currentIndex - 1;
    }

    ref.read(playlistControllerProvider.notifier).previous();

    _loadAndPlaySong(_localSongs[prevIndex]);
  }

  void _onSongCompleted() async {
    final playerState = ref.read(audioControllerProvider);
    final song = playerState.currentSong;

    bool hasLetter = false;

    if (song != null && song.hasGoldenLetter) {
      final letterController = ref.read(letterControllerProvider.notifier);
      await letterController.checkForLetter(song.id);

      final letterState = ref.read(letterControllerProvider);
      if (letterState.letter != null) {
        setState(() {
          _showLetter = true;
        });
        hasLetter = true;
      }
    }

    if (!hasLetter) {
      _playNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioControllerProvider);
    final letterState = ref.watch(letterControllerProvider);
    final currentSong = playerState.currentSong;

    // 监听音乐播放状态，在音乐播放一段时间后恢复封面加载
    ref.listen(audioControllerProvider, (previous, current) {
      if (previous == null || current == null) return;
      // 当音乐开始播放时，检查是否需要恢复封面加载
      if (!previous.isPlaying && current.isPlaying) {
        // 音乐刚开始播放，确保封面加载已暂停
        CoverArtService().pauseLoading();
      }
      // 当音乐播放了一段时间（位置超过3秒），恢复封面加载
      if (current.isPlaying &&
          current.position.inSeconds >= 3 &&
          previous.position.inSeconds < 3) {
        CoverArtService().resumeLoading();
      }
      // 当音乐暂停时，可以恢复封面加载
      if (previous.isPlaying && !current.isPlaying) {
        CoverArtService().resumeLoading();
      }
    });

    // 监听音乐源变化，当源变化时重新加载歌曲
    ref.listen(musicSourceManagerProvider, (previous, next) {
      debugPrint('[PlayerPage] Music sources changed');
      debugPrint('[PlayerPage] Previous sources: ${previous?.map((s) => '${s.name} (enabled: ${s.isEnabled})').toList()}');
      debugPrint('[PlayerPage] Next sources: ${next.map((s) => '${s.name} (enabled: ${s.isEnabled})').toList()}');
      if (previous != null && previous.length == next.length) {
        // 检查是否有源的启用状态发生变化
        bool hasChanged = false;
        for (int i = 0; i < previous.length; i++) {
          if (previous[i].isEnabled != next[i].isEnabled) {
            hasChanged = true;
            break;
          }
        }
        debugPrint('[PlayerPage] Has changed: $hasChanged');
        if (hasChanged) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadSongs();
          });
        }
      } else {
        // 源的数量发生变化（添加或删除）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadSongs();
        });
      }
    });

    if (playerState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSongCompleted();
        ref.read(audioControllerProvider.notifier).resetCompletion();
      });
    }

    if (PlatformUtils.isMobile) {
      return _buildMobileLayout(context, currentSong, playerState, letterState);
    }

    return _buildDesktopLayout(context, currentSong, playerState, letterState);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Song? currentSong,
    PlayerState playerState,
    LetterState letterState,
  ) {
    return m.Scaffold(
      backgroundColor: AppTheme.softBlack,
      appBar: m.AppBar(
        backgroundColor: AppTheme.softBlack,
        foregroundColor: AppTheme.warmCream,
        elevation: 0,
        title: const Text(
          '文艺复兴',
          style: TextStyle(
            fontFamily: 'NotoSerifSC',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
        actions: [
          m.IconButton(
            icon: const Icon(m.Icons.settings),
            onPressed: () {
              m.Navigator.push(
                context,
                m.MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          m.IconButton(
            icon: const Icon(m.Icons.equalizer),
            onPressed: () {
              setState(() {
                _showMixer = !_showMixer;
              });
            },
          ),
        ],
      ),
      drawer: _buildMobileDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.softBlack,
              AppTheme.charcoal,
              AppTheme.deepBrown.withOpacity(0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (currentSong != null)
              Positioned.fill(
                child: DynamicBackground(
                  dominantColor: currentSong.dominantColor,
                  child: Container(),
                ),
              ),
            Column(
              children: [
                Expanded(
                  child: currentSong != null
                      ? _buildMobilePlayerContent(currentSong, playerState, letterState)
                      : _buildEmptyState(),
                ),
              ],
            ),
            if (_showMixer)
              Positioned.fill(
                child: Container(
                  color: m.Colors.black.withOpacity(0.9),
                  child: Column(
                    children: [
                      m.AppBar(
                        backgroundColor: m.Colors.transparent,
                        foregroundColor: AppTheme.warmCream,
                        title: const Text('混音台'),
                        leading: m.IconButton(
                          icon: const Icon(m.Icons.close),
                          onPressed: () {
                            setState(() {
                              _showMixer = false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: MixerPanel(
                          key: ValueKey(currentSong?.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (letterState.isRevealed && letterState.letter != null)
              Positioned.fill(
                child: Container(
                  color: m.Colors.black.withOpacity(0.7),
                  child: Center(
                    child: GoldenLetterWidget(
                      key: ValueKey(letterState.letter!.id),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    // 获取当前音乐源显示文本
    String sourceText;
    if (_enabledSources.isEmpty) {
      sourceText = '未启用任何音乐源';
    } else if (_enabledSources.length == 1) {
      sourceText = _enabledSources.first.name;
    } else {
      sourceText = '${_enabledSources.length} 个音乐源';
    }

    return m.Drawer(
      backgroundColor: AppTheme.softBlack,
      child: Column(
        children: [
          m.UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.charcoal,
            ),
            accountName: const Text(
              '歌曲列表',
              style: TextStyle(color: AppTheme.warmCream),
            ),
            accountEmail: Text(
              sourceText,
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            currentAccountPicture: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.vintageGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                m.Icons.music_note,
                color: AppTheme.vintageGold,
                size: 32,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: m.CircularProgressIndicator(
                      color: AppTheme.vintageGold,
                    ),
                  )
                : _localSongs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  m.Icons.music_note,
                                  size: 48,
                                  color: AppTheme.warmBrown,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无音乐',
                                  style: TextStyle(
                                    color: AppTheme.warmBeige.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _localSongs.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _localSongs.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.vintageGold),
                                ),
                              ),
                            );
                          }
                          final song = _localSongs[index];
                          final isPlaying =
                              ref.watch(audioControllerProvider).currentSong?.id ==
                                  song.id;

                          return m.ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.warmBrown.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPlaying ? m.Icons.play_arrow : m.Icons.music_note,
                                color: isPlaying ? AppTheme.vintageGold : AppTheme.warmBeige,
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isPlaying ? AppTheme.vintageGold : AppTheme.warmCream,
                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: AppTheme.warmBeige.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _loadAndPlaySong(song);
                            },
                          );
                        },
                      ),
          ),
          m.Padding(
            padding: const EdgeInsets.all(16),
            child: m.ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectMusicDirectory,
              icon: const Icon(m.Icons.folder_open),
              label: const Text('选择音乐文件夹'),
              style: m.ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vintageGold,
                foregroundColor: AppTheme.softBlack,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePlayerContent(
    Song song,
    PlayerState playerState,
    LetterState letterState,
  ) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        
        if (details.primaryVelocity! < -500) {
          _playNext();
        } else if (details.primaryVelocity! > 500) {
          _playPrevious();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            VinylCover(
              coverPath: _currentCoverPath ?? song.coverUrl,
              dominantColor: song.dominantColor,
              isPlaying: playerState.isPlaying,
              size: 200,
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 32),
            _buildSongInfo(song),
            const SizedBox(height: 24),
            VintageProgressBar(
              progress: playerState.progress.clamp(0.0, 1.0),
              position: playerState.position,
              duration: playerState.duration,
              onSeek: (value) {
                ref.read(audioControllerProvider.notifier).seekToProgress(value);
              },
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),
            _buildMobileControls(playerState, song),
            if (_showLetter && letterState.letter != null)
              m.Padding(
                padding: const EdgeInsets.only(top: 16),
                child: m.ElevatedButton.icon(
                  onPressed: () {
                    ref.read(letterControllerProvider.notifier).revealLetter();
                  },
                  icon: const Icon(m.Icons.mail),
                  label: const Text('查看金色信件'),
                  style: m.ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vintageGold,
                    foregroundColor: AppTheme.softBlack,
                  ),
                ),
              ),
            if (playerState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: m.Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: m.Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m.Icons.error,
                      color: m.Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        playerState.errorMessage!,
                        style: TextStyle(
                          color: m.Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileControls(PlayerState playerState, Song? currentSong) {
    final playMode = ref.watch(playlistControllerProvider).playMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        m.IconButton(
          onPressed: () {
            ref.read(playlistControllerProvider.notifier).togglePlayMode();
            if (playMode == PlayMode.blindBox) {
              setState(() {
                _isBlindBoxRevealed = false;
              });
            }
          },
          icon: Icon(
            playMode == PlayMode.shuffle
                ? m.Icons.shuffle
                : playMode == PlayMode.blindBox
                    ? m.Icons.card_giftcard
                    : m.Icons.repeat,
            color: AppTheme.warmBeige,
          ),
          iconSize: 24,
        ),
        m.IconButton(
          onPressed: _playPrevious,
          icon: const Icon(m.Icons.skip_previous),
          color: AppTheme.warmCream,
          iconSize: 36,
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.vintageGold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.vintageGold.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: m.IconButton(
            onPressed: () {
              ref.read(audioControllerProvider.notifier).togglePlay();
            },
            icon: Icon(
              playerState.isPlaying ? m.Icons.pause : m.Icons.play_arrow,
              color: AppTheme.softBlack,
            ),
            iconSize: 36,
          ),
        ),
        m.IconButton(
          onPressed: _playNext,
          icon: const Icon(m.Icons.skip_next),
          color: AppTheme.warmCream,
          iconSize: 36,
        ),
        m.IconButton(
          onPressed: () {
            if (currentSong != null) {
              showDialog(
                context: context,
                builder: (ctx) => WriteLetterDialog(
                  songId: currentSong.id,
                  songTitle: currentSong.title,
                ),
              );
            }
          },
          icon: const Icon(m.Icons.edit_note),
          color: AppTheme.warmBeige,
          iconSize: 24,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Song? currentSong,
    PlayerState playerState,
    LetterState letterState,
  ) {
    return NavigationView(
      appBar: NavigationAppBar(
        height: 48,
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FluentIcons.music_note,
                    color: AppTheme.vintageGold.withOpacity(0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '文艺复兴',
                    style: TextStyle(
                      fontFamily: 'NotoSerifSC',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                      color: AppTheme.warmCream,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: _buildDesktopWindowButtons(),
          ),
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.softBlack,
              AppTheme.charcoal,
              AppTheme.deepBrown.withOpacity(0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (currentSong != null)
              Positioned.fill(
                child: DynamicBackground(
                  dominantColor: currentSong.dominantColor,
                  child: Container(),
                ),
              ),
            Row(
              children: [
                _buildSongList(),
                Expanded(
                  child: currentSong != null
                      ? _buildPlayerContent(currentSong, playerState, letterState)
                      : _buildEmptyState(),
                ),
                if (_showMixer)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: MixerPanel(
                      key: ValueKey(currentSong?.id),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopWindowButtons() {
    return [
      _buildWindowButton(
        icon: FluentIcons.settings,
        onTap: () => _openSettings(context),
      ),
      const SizedBox(width: 8),
      _buildWindowButton(
        icon: FluentIcons.remove,
        onTap: () => minimizeWindow(),
      ),
      const SizedBox(width: 8),
      _buildWindowButton(
        icon: FluentIcons.chrome_close,
        onTap: () => closeWindow(),
        isClose: true,
      ),
    ];
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovering = false;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isHovering
                    ? (isClose
                        ? const Color(0xFFE81123)
                        : AppTheme.warmBeige.withOpacity(0.1))
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 10,
                color: isHovering
                    ? (isClose ? Colors.white : AppTheme.warmCream)
                    : AppTheme.warmBeige.withOpacity(0.6),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongList() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark.withOpacity(0.8),
        border: Border(
          right: BorderSide(
            color: AppTheme.warmBrown.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.vintageGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FluentIcons.music_note,
                    color: AppTheme.vintageGold,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '歌曲列表',
                    style: FluentTheme.of(context).typography.subtitle?.copyWith(
                          color: AppTheme.warmCream,
                          fontSize: 16,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.warmBrown.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProgressRing(
                          activeColor: AppTheme.vintageGold,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '扫描音乐...',
                          style: TextStyle(
                            color: AppTheme.warmBeige.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : _localSongs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.warmBrown.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FluentIcons.music_note,
                                  color: AppTheme.warmBrown.withOpacity(0.3),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无音乐',
                                style: TextStyle(
                                  color: AppTheme.warmBeige.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '请在设置中添加本地文件夹或云存储',
                                style: TextStyle(
                                  color: AppTheme.warmBrown.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _localSongs.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _localSongs.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.vintageGold),
                                ),
                              ),
                            );
                          }
                          final song = _localSongs[index];
                          final isPlaying =
                              ref.watch(audioControllerProvider).currentSong?.id ==
                                  song.id;
                          // 优先使用缓存的封面，如果没有则使用 song.coverUrl
                          final cachedCover = _songCoverCache[song.id];
                          final coverPath = isPlaying
                              ? (_currentCoverPath ?? cachedCover ?? song.coverUrl)
                              : (cachedCover ?? song.coverUrl);

                          return EnhancedSongListItem(
                            song: song,
                            isPlaying: isPlaying,
                            onTap: () => _loadAndPlaySong(song),
                            coverPath: coverPath,
                            index: index,
                          );
                        },
                      ),
          ),
          _buildMusicFolderBar(),
        ],
      ),
    );
  }

  Widget _buildMusicFolderBar() {
    // 直接从 musicSourceManagerProvider 获取当前启用的音乐源
    final sources = ref.watch(musicSourceManagerProvider);
    final enabledSources = sources.where((s) => s.isEnabled).toList();

    if (enabledSources.isEmpty) {
      return Container(
        height: 40,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.warmBrown.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.warmBrown.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              FluentIcons.music_note,
              color: AppTheme.warmBeige.withOpacity(0.5),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '未启用任何音乐源',
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.5),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
    }

    // 如果只有一个启用的源，显示源名称
    if (enabledSources.length == 1) {
      final source = enabledSources.first;
      return Container(
        height: 40,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.warmBrown.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.warmBrown.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              source.type == MusicSourceType.local
                  ? FluentIcons.folder
                  : FluentIcons.cloud,
              color: AppTheme.vintageGold.withOpacity(0.7),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                source.name,
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.6),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
    }

    // 多个启用的源，显示可切换的源列表
    return Container(
      height: 40,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.warmBrown.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warmBrown.withOpacity(0.15),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: enabledSources.length,
        itemBuilder: (context, index) {
          final source = enabledSources[index];
          final isSelected = _localSongs.isNotEmpty &&
              _localSongs.first.sourceId == source.id;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _switchToSource(source),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.vintageGold.withOpacity(0.2)
                      : AppTheme.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.vintageGold.withOpacity(0.5),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      source.type == MusicSourceType.local
                          ? FluentIcons.folder
                          : FluentIcons.cloud,
                      size: 10,
                      color: isSelected
                          ? AppTheme.vintageGold
                          : AppTheme.warmBeige.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      source.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppTheme.vintageGold
                            : AppTheme.warmBeige.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  void _switchToSource(MusicSource source) async {
    final manager = ref.read(musicSourceManagerProvider.notifier);
    final songs = await manager.getSongsFromSource(source, page: 0, pageSize: _pageSize);

    setState(() {
      _currentPage = 0;
      _hasMoreData = songs.length >= _pageSize;
    });

    if (songs.isNotEmpty) {
      final playlist = Playlist(
        id: 'source_${source.id}',
        name: source.name,
        songs: songs,
      );
      ref.read(playlistControllerProvider.notifier).loadPlaylist(playlist);

      setState(() {
        _localSongs = songs;
      });

      CoverArtService().preloadCovers(songs);

      // 自动连续加载模式：如果还有更多数据，自动开始加载下一页
      if (_autoLoadMode && _hasMoreData && songs.length >= _pageSize) {
        debugPrint('[PlayerPage] Auto load mode: starting to load next pages for source ${source.name}...');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _loadMoreSongsForSource(source);
          }
        });
      }
    }
  }

  /// 为特定音乐源加载更多歌曲（分页加载）
  Future<void> _loadMoreSongsForSource(MusicSource source) async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    debugPrint('[PlayerPage] Loading more songs for source ${source.name}, page: $nextPage');

    try {
      final manager = ref.read(musicSourceManagerProvider.notifier);
      final newSongs = await manager.getSongsFromSource(source, page: nextPage, pageSize: _pageSize);

      if (newSongs.isEmpty) {
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
        });
        debugPrint('[PlayerPage] No more songs to load for source ${source.name}');
        return;
      }

      setState(() {
        _localSongs.addAll(newSongs);
        _currentPage = nextPage;
        _hasMoreData = newSongs.length >= _pageSize;
        _isLoadingMore = false;
      });

      debugPrint('[PlayerPage] Loaded ${newSongs.length} more songs for source ${source.name}, total: ${_localSongs.length}');

      // 异步预加载新加载歌曲的封面
      CoverArtService().preloadCovers(newSongs);
      _loadSongCovers(newSongs);

      // 自动连续加载模式：如果还有更多数据，继续加载下一页
      if (_autoLoadMode && _hasMoreData) {
        debugPrint('[PlayerPage] Auto load mode: loading next page for source ${source.name}...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadMoreSongsForSource(source);
          }
        });
      }
    } catch (e) {
      debugPrint('[PlayerPage] Error loading more songs for source ${source.name}: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildPlayerContent(Song song, PlayerState playerState, LetterState letterState) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                VinylCover(
                  coverPath: _currentCoverPath ?? song.coverUrl,
                  dominantColor: song.dominantColor,
                  isPlaying: playerState.isPlaying,
                  size: 280,
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 48),

            _buildSongInfo(song),
            const SizedBox(height: 48),

            Container(
              width: 480,
              child: VintageProgressBar(
                progress: playerState.progress.clamp(0.0, 1.0),
                position: playerState.position,
                duration: playerState.duration,
                onSeek: (value) {
                  ref.read(audioControllerProvider.notifier).seekToProgress(value);
                },
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 40),

            _buildControls(playerState),

            if (playerState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: m.Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: m.Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.error,
                      color: m.Colors.red.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        playerState.errorMessage!,
                        style: TextStyle(
                          color: m.Colors.red.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
          ],
        ),

        if (_showLetter && letterState.letter != null)
          Positioned(
            right: 48,
            bottom: 140,
            child: LetterBadge(
              onTap: () {
                ref.read(letterControllerProvider.notifier).revealLetter();
              },
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),

        if (letterState.isRevealed && letterState.letter != null)
          Positioned.fill(
            child: Container(
              color: m.Colors.black.withOpacity(0.7),
              child: Center(
                child: GoldenLetterWidget(
                  key: ValueKey(letterState.letter!.id),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

        Positioned(
          right: 28,
          top: 28,
          child: AnimatedControlButton(
            icon: FluentIcons.equalizer,
            size: 22,
            color: _showMixer ? AppTheme.vintageGold : AppTheme.warmBeige,
            tooltip: '混音台',
            onTap: () {
              setState(() {
                _showMixer = !_showMixer;
              });
            },
          ),
        ).animate().fadeIn(delay: 300.ms),

        if (song != null)
          Positioned(
            right: 28,
            bottom: 48,
            child: AnimatedControlButton(
              icon: FluentIcons.edit_mail,
              size: 20,
              tooltip: '写信',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => WriteLetterDialog(
                    songId: song.id,
                    songTitle: song.title,
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.music_note,
              size: 64,
              color: AppTheme.warmBrown.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '选择一首歌曲开始',
            style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  color: AppTheme.warmBeige.withOpacity(0.6),
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '在左侧列表中选择一首老歌，开启你的文艺复兴之旅',
            style: FluentTheme.of(context).typography.caption?.copyWith(
                  color: AppTheme.warmBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 32),
          if (_localSongs.isNotEmpty) _buildBlindBoxButton(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildBlindBoxButton() {
    return GestureDetector(
      onTap: _playBlindBox,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.vintageGold.withOpacity(0.2),
                AppTheme.vintageGold.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.vintageGold.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vintageGold.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.vintageGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.giftbox,
                  color: AppTheme.vintageGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '盲盒模式',
                    style: TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '随机播放一首，揭晓前隐藏歌名',
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }

  void _playBlindBox() {
    if (_localSongs.isEmpty) return;

    ref.read(playlistControllerProvider.notifier).setPlayMode(PlayMode.blindBox);

    final randomIndex = DateTime.now().millisecondsSinceEpoch % _localSongs.length;
    final randomSong = _localSongs[randomIndex];

    _loadAndPlaySong(randomSong);
  }

  Widget _buildSongInfo(Song song) {
    final playMode = ref.watch(playlistControllerProvider).playMode;
    final isBlindBoxMode = playMode == PlayMode.blindBox;

    const double fixedHeight = 120;

    if (isBlindBoxMode && !_isBlindBoxRevealed) {
      return SizedBox(
        height: fixedHeight,
        child: Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isBlindBoxRevealed = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.warmBrown.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.vintageGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.vintageGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FluentIcons.giftbox,
                      color: AppTheme.vintageGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '点击揭晓歌曲',
                        style: TextStyle(
                          color: AppTheme.warmBeige,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '神秘盲盒模式',
                        style: TextStyle(
                          color: AppTheme.warmBrown.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 400.ms,
          );
    }

    return SizedBox(
      height: fixedHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            song.title,
            style: FluentTheme.of(context).typography.title?.copyWith(
                  color: AppTheme.warmCream,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 10),
          Text(
            song.artist,
            style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  color: AppTheme.warmBeige.withOpacity(0.8),
                  fontSize: 18,
                ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${song.album} · ${song.year}',
              style: FluentTheme.of(context).typography.caption?.copyWith(
                    color: AppTheme.warmBrown.withOpacity(0.8),
                  ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerState playerState) {
    final playMode = ref.watch(playlistControllerProvider).playMode;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayModeButton(
              mode: playMode.index,
              onTap: () {
                ref.read(playlistControllerProvider.notifier).togglePlayMode();
                if (playMode == PlayMode.blindBox) {
                  setState(() {
                    _isBlindBoxRevealed = false;
                  });
                }
              },
            ),
            const SizedBox(width: 32),

            AnimatedControlButton(
              icon: FluentIcons.previous,
              size: 26,
              onTap: _playPrevious,
              tooltip: '上一首',
            ),
            const SizedBox(width: 40),

            AnimatedPlayButton(
              isPlaying: playerState.isPlaying,
              onTap: () {
                ref.read(audioControllerProvider.notifier).togglePlay();
              },
              size: 72,
            ),
            const SizedBox(width: 40),

            AnimatedControlButton(
              icon: FluentIcons.next,
              size: 26,
              onTap: _playNext,
              tooltip: '下一首',
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}
