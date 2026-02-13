import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Slider, IconButton, Divider, Colors, showDialog, Tooltip, ButtonStyle;
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

  @override
  void initState() {
    super.initState();
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

    if (song != null && song.hasGoldenLetter) {
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

    if (playerState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSongCompleted();
        ref.read(audioControllerProvider.notifier).resetCompletion();
      });
    }

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
            children: [
              _buildWindowButton(
                icon: FluentIcons.remove,
                onTap: () => windowManager.minimize(),
              ),
              const SizedBox(width: 8),
              _buildWindowButton(
                icon: FluentIcons.chrome_close,
                onTap: () => windowManager.close(),
                isClose: true,
              ),
            ],
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
                                '暂无本地音乐',
                                style: TextStyle(
                                  color: AppTheme.warmBeige.withOpacity(0.6),
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _localSongs.length,
                        itemBuilder: (context, index) {
                          final song = _localSongs[index];
                          final isPlaying =
                              ref.watch(audioControllerProvider).currentSong?.id ==
                                  song.id;

                          return EnhancedSongListItem(
                            song: song,
                            isPlaying: isPlaying,
                            onTap: () => _loadAndPlaySong(song),
                            coverPath: isPlaying ? _currentCoverPath : null,
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
            FluentIcons.folder,
            color: AppTheme.vintageGold.withOpacity(0.7),
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _musicDirectoryPath ?? '未选择文件夹',
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isLoading ? null : _selectMusicDirectory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warmBrown.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.open_folder_horizontal,
                      size: 10,
                      color: AppTheme.warmBeige.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '切换',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.warmBeige.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(width: 10),
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
              color: Colors.black.withOpacity(0.7),
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
          if (_localSongs.isNotEmpty)
            _buildBlindBoxButton(),
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

    // 设置盲盒模式
    ref.read(playlistControllerProvider.notifier).setPlayMode(PlayMode.blindBox);

    // 随机选择一首歌曲
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _localSongs.length;
    final randomSong = _localSongs[randomIndex];

    // 播放歌曲
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
