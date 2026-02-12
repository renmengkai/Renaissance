import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Slider, IconButton, Divider, Colors, showDialog, Tooltip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../blindbox/blur/blurred_cover.dart';
import '../../../golden_letter/repository/letter_repository.dart';
import '../../../golden_letter/ui/golden_letter_widget.dart';
import '../../../golden_letter/ui/write_letter_dialog.dart';
import '../../../lofi_engine/mixer/lofi_mixer.dart';
import '../../../lofi_engine/mixer/mixer_panel.dart';
import '../../audio/audio_controller.dart';
import '../../audio/playlist_controller.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../services/local_music_service.dart';

// Type alias for backward compatibility
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
  
  bool _isDraggingProgress = false;
  double _draggingProgressValue = 0.0;

  int _currentIndex = -1;
  bool _isBlindBoxRevealed = false;

  @override
  void initState() {
    super.initState();
    // 初始化 Lo-Fi 混音器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loFiMixerProvider.notifier).initialize();
      _loadLocalSongs();
    });
  }

  Future<void> _loadLocalSongs() async {
    setState(() {
      _isLoading = true;
    });
    final songs = await LocalMusicService.scanLocalSongs();
    final musicPath = await LocalMusicService.getMusicDirectoryPath();

    // 创建本地音乐播放列表并加载到 playlistController
    if (songs.isNotEmpty) {
      final localPlaylist = Playlist(
        id: 'local_music',
        name: '本地音乐',
        songs: songs,
      );
      ref.read(playlistControllerProvider.notifier).loadPlaylist(localPlaylist);
    }

    setState(() {
      _localSongs = songs;
      _isLoading = false;
      _musicDirectoryPath = musicPath;
    });
  }

  Future<void> _selectMusicDirectory() async {
    final selectedDir = await LocalMusicService.selectMusicDirectory();
    if (selectedDir != null) {
      // 重新加载歌曲
      await _loadLocalSongs();
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

    // 更新 playlistController 的当前歌曲索引
    playlistController.playSong(song);

    audioController.loadSong(song).then((_) {
      audioController.play();
    });

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

    // 更新 playlistController 的 currentIndex
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

    // 更新 playlistController 的 currentIndex
    ref.read(playlistControllerProvider.notifier).previous();

    _loadAndPlaySong(_localSongs[prevIndex]);
  }

  void _onSongCompleted() async {
    final playerState = ref.read(audioControllerProvider);
    final song = playerState.currentSong;

    if (song != null && song.hasGoldenLetter) {
      // 检查是否有信件
      final letterController = ref.read(letterControllerProvider.notifier);
      await letterController.checkForLetter(song.id);

      final letterState = ref.read(letterControllerProvider);
      if (letterState.letter != null) {
        setState(() {
          _showLetter = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioControllerProvider);
    final letterState = ref.watch(letterControllerProvider);
    final currentSong = playerState.currentSong;

    // 监听播放完成
    if (playerState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSongCompleted();
        ref.read(audioControllerProvider.notifier).resetCompletion();
      });
    }

    return NavigationView(
      appBar: NavigationAppBar(
        title: const DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '文艺复兴',
              style: TextStyle(
                fontFamily: 'NotoSerifSC',
                fontSize: 16,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.remove),
              onPressed: () => windowManager.minimize(),
            ),
            IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: () => windowManager.close(),
            ),
          ],
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
        child: Row(
          children: [
            // 左侧：歌曲列表
            _buildSongList(),

            // 中间：播放器主体
            Expanded(
              child: currentSong != null
                  ? _buildPlayerContent(currentSong, playerState, letterState)
                  : _buildEmptyState(),
            ),

            // 右侧：混音台
            if (_showMixer)
              Padding(
                padding: const EdgeInsets.all(24),
                child: MixerPanel(
                  key: ValueKey(currentSong?.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        border: Border(
          right: BorderSide(
            color: AppTheme.warmBrown.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  FluentIcons.music_note,
                  color: AppTheme.vintageGold,
                  size: 20,
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
          ),
          const Divider(),

          // 音乐文件夹路径提示和操作按钮
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warmBrown.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FluentIcons.folder,
                      color: AppTheme.vintageGold.withOpacity(0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '音乐文件夹',
                      style: TextStyle(
                        color: AppTheme.warmBeige.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_musicDirectoryPath != null)
                  Text(
                    _musicDirectoryPath!,
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.5),
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        onPressed: _isLoading ? null : _selectMusicDirectory,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FluentIcons.open_folder_horizontal,
                              size: 12,
                              color: AppTheme.warmBeige,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '更改文件夹',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.warmBeige,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _isLoading ? null : _loadLocalSongs,
                      child: Icon(
                        FluentIcons.refresh,
                        size: 12,
                        color: AppTheme.warmBeige,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 歌曲列表
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProgressRing(
                          activeColor: AppTheme.vintageGold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '扫描本地音乐...',
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FluentIcons.music_note,
                                color: AppTheme.warmBrown.withOpacity(0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '暂无本地音乐',
                                style: TextStyle(
                                  color: AppTheme.warmBeige.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '请将音乐文件放入上述文件夹',
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _localSongs.length,
                        itemBuilder: (context, index) {
                          final song = _localSongs[index];
                          final isPlaying =
                              ref.watch(audioControllerProvider).currentSong?.id ==
                                  song.id;

                          return _SongListItem(
                            song: song,
                            isPlaying: isPlaying,
                            onTap: () => _loadAndPlaySong(song),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(Song song, PlayerState playerState, LetterState letterState) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景装饰
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.8,
                colors: [
                  _parseColor(song.dominantColor)?.withOpacity(0.15) ??
                      AppTheme.warmBrown.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 主要内容
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                BlurredCover(
                  coverUrl: _currentCoverPath ?? song.coverUrl,
                  dominantColor: song.dominantColor,
                  year: song.year,
                ),
                if (_isLoadingCover)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: ProgressRing(
                          activeColor: AppTheme.vintageGold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),

            // 歌曲信息
            _buildSongInfo(song),
            const SizedBox(height: 40),

            // 进度条
            _buildProgressBar(playerState),
            const SizedBox(height: 32),

            // 控制按钮
            _buildControls(playerState),
            
            // 错误信息
            if (playerState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.error,
                      color: Colors.red.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        playerState.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // 信件徽章（当歌曲完成且有信件时显示）
        if (_showLetter && letterState.letter != null)
          Positioned(
            right: 40,
            bottom: 120,
            child: LetterBadge(
              onTap: () {
                ref.read(letterControllerProvider.notifier).revealLetter();
              },
            ),
          ),

        // 信件内容弹窗
        if (letterState.isRevealed && letterState.letter != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: GoldenLetterWidget(
                  key: ValueKey(letterState.letter!.id),
                ),
              ),
            ),
          ),

        // 混音台切换按钮
        Positioned(
          right: 24,
          top: 24,
          child: IconButton(
            icon: Icon(
              FluentIcons.equalizer,
              color: _showMixer ? AppTheme.vintageGold : AppTheme.warmBeige,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _showMixer = !_showMixer;
              });
            },
          ),
        ),

        // 写信按钮（在歌曲播放时显示）
        if (song != null)
          Positioned(
            right: 24,
            bottom: 40,
            child: IconButton(
              icon: const Icon(
                FluentIcons.edit_mail,
                color: AppTheme.warmBeige,
                size: 22,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => WriteLetterDialog(
                    songId: song.id,
                    songTitle: song.title,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.music_note,
            size: 80,
            color: AppTheme.warmBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '选择一首歌曲开始',
            style: FluentTheme.of(context).typography.subtitle?.copyWith(
              color: AppTheme.warmBeige.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在左侧列表中选择一首老歌，开启你的文艺复兴之旅',
            style: FluentTheme.of(context).typography.caption?.copyWith(
              color: AppTheme.warmBrown.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    final playMode = ref.watch(playlistControllerProvider).playMode;
    final isBlindBoxMode = playMode == PlayMode.blindBox;
    
    if (isBlindBoxMode && !_isBlindBoxRevealed) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isBlindBoxRevealed = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.warmBrown.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.vintageGold.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                FluentIcons.giftbox,
                color: AppTheme.vintageGold,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                '点击揭晓歌曲',
                style: TextStyle(
                  color: AppTheme.warmBeige,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '神秘盲盒模式',
                style: TextStyle(
                  color: AppTheme.warmBrown.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Text(
          song.title,
          style: FluentTheme.of(context).typography.title?.copyWith(
            color: AppTheme.warmCream,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
            color: AppTheme.warmBeige.withOpacity(0.8),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${song.album} · ${song.year}',
          style: FluentTheme.of(context).typography.caption?.copyWith(
            color: AppTheme.warmBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerState playerState) {
    final position = playerState.position;
    final duration = playerState.duration;
    final progress = playerState.progress;

    // 如果在拖动中，使用拖动值；否则使用实际进度
    final displayProgress = _isDraggingProgress 
        ? _draggingProgressValue 
        : progress.clamp(0.0, 1.0);

    String formatDuration(Duration d) {
      final minutes = d.inMinutes.toString().padLeft(2, '0');
      final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Container(
      width: 500,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Slider(
            min: 0.0,
            max: 1.0,
            value: displayProgress,
            onChanged: (value) {
              // 更新拖动状态，但不实际 seek
              setState(() {
                _isDraggingProgress = true;
                _draggingProgressValue = value;
              });
            },
            onChangeEnd: (value) {
              // 拖动结束时执行 seek
              setState(() {
                _isDraggingProgress = false;
              });
              ref
                  .read(audioControllerProvider.notifier)
                  .seekToProgress(value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(position),
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                formatDuration(duration),
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
            // 播放模式切换
            _buildPlayModeButton(playMode),
            const SizedBox(width: 24),
            
            // 上一首
            IconButton(
              icon: Icon(
                FluentIcons.previous,
                color: AppTheme.warmBeige,
                size: 28,
              ),
              onPressed: _playPrevious,
            ),
            const SizedBox(width: 32),

            // 播放/暂停
            GestureDetector(
              onTap: () {
                ref.read(audioControllerProvider.notifier).togglePlay();
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.vintageGold,
                      Color(0xFFB8941F),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.vintageGold.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  playerState.isPlaying
                      ? FluentIcons.pause
                      : FluentIcons.play_solid,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 32),

            // 下一首
            IconButton(
              icon: Icon(
                FluentIcons.next,
                color: AppTheme.warmBeige,
                size: 28,
              ),
              onPressed: _playNext,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayModeButton(PlayMode playMode) {
    IconData iconData;
    String tooltip;
    Color iconColor;
    
    switch (playMode) {
      case PlayMode.sequential:
        iconData = FluentIcons.play;
        tooltip = '顺序播放';
        iconColor = AppTheme.warmBeige;
        break;
      case PlayMode.shuffle:
        iconData = FluentIcons.sync;
        tooltip = '随机播放';
        iconColor = AppTheme.vintageGold;
        break;
      case PlayMode.blindBox:
        iconData = FluentIcons.giftbox;
        tooltip = '盲盒模式';
        iconColor = AppTheme.vintageGold;
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          iconData,
          color: iconColor,
          size: 22,
        ),
        onPressed: () {
          ref.read(playlistControllerProvider.notifier).togglePlayMode();
          if (playMode == PlayMode.blindBox) {
            setState(() {
              _isBlindBoxRevealed = false;
            });
          }
        },
      ),
    );
  }

  Color? _parseColor(String? hexColor) {
    if (hexColor == null) return null;
    try {
      return Color(
        int.parse(hexColor.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      return null;
    }
  }
}

// 歌曲列表项
class _SongListItem extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongListItem({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.vintageGold.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isPlaying
              ? Border.all(
                  color: AppTheme.vintageGold.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // 封面缩略图
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.warmBrown.withOpacity(0.3),
              ),
              child: isPlaying
                  ? const Center(
                      child: Icon(
                        FluentIcons.volume3,
                        color: AppTheme.vintageGold,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isPlaying ? AppTheme.vintageGold : AppTheme.warmCream,
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.artist} · ${song.year}',
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 信件标记
            if (song.hasGoldenLetter)
              Icon(
                FluentIcons.mail,
                color: AppTheme.vintageGold.withOpacity(0.6),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
