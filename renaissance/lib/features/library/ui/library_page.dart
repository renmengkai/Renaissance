import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/player/models/song.dart';
import '../../../features/player/models/playlist.dart';
import '../../../features/player/audio/playlist_controller.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistControllerProvider);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('音乐库'),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡片
            _buildStatsSection(context, playlistState),
            const SizedBox(height: 32),

            // 播放列表
            _buildPlaylistsSection(context, ref, playlistState),
            const SizedBox(height: 32),

            // 所有歌曲
            _buildAllSongsSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, PlaylistState state) {
    final totalSongs = state.playlists.fold<int>(
      0,
      (sum, playlist) => sum + playlist.songs.length,
    );
    final totalPlaylists = state.playlists.length;
    final favoriteSongs = state.playlists
        .firstWhere(
          (p) => p.name == '我的收藏',
          orElse: () => const Playlist(id: '', name: '', songs: []),
        )
        .songs
        .length;

    return Row(
      children: [
        _StatCard(
          icon: FluentIcons.music_note,
          title: '歌曲总数',
          value: totalSongs.toString(),
          color: AppTheme.vintageGold,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: FluentIcons.playlist_music,
          title: '播放列表',
          value: totalPlaylists.toString(),
          color: AppTheme.warmBrown,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: FluentIcons.heart,
          title: '我的收藏',
          value: favoriteSongs.toString(),
          color: const Color(0xFFE53935),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection(
    BuildContext context,
    WidgetRef ref,
    PlaylistState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '我的播放列表',
              style: FluentTheme.of(context).typography.subtitle?.copyWith(
                color: AppTheme.warmCream,
                fontSize: 20,
              ),
            ),
            Button(
              onPressed: () {
                _showCreatePlaylistDialog(context, ref);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.add, size: 16),
                  const SizedBox(width: 8),
                  const Text('新建列表'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: state.playlists.map((playlist) {
            return _PlaylistCard(
              playlist: playlist,
              onTap: () {
                ref
                    .read(playlistControllerProvider.notifier)
                    .loadPlaylist(playlist);
              },
              onDelete: () {
                _showDeletePlaylistDialog(context, ref, playlist);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllSongsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '所有歌曲',
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
            color: AppTheme.warmCream,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        ...sampleSongs.map((song) {
          return _SongListItem(
            song: song,
            onTap: () {
              // 播放歌曲
            },
            onAddToPlaylist: () {
              _showAddToPlaylistDialog(context, ref, song);
            },
          );
        }).toList(),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('新建播放列表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              controller: nameController,
              placeholder: '播放列表名称',
            ),
            const SizedBox(height: 12),
            TextBox(
              controller: descController,
              placeholder: '描述（可选）',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('创建'),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(playlistControllerProvider.notifier).createPlaylist(
                      nameController.text,
                      description: descController.text.isEmpty
                          ? null
                          : descController.text,
                    );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('删除播放列表'),
        content: Text('确定要删除"${playlist.name}"吗？'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('删除'),
            onPressed: () {
              ref
                  .read(playlistControllerProvider.notifier)
                  .deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) {
    final playlists = ref.read(playlistControllerProvider).playlists;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('添加到播放列表'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                onPressed: () {
                  ref
                      .read(playlistControllerProvider.notifier)
                      .addSongToPlaylist(playlist.id, song);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.acrylicDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: FluentTheme.of(context).typography.title?.copyWith(
                color: AppTheme.warmCream,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.acrylicDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warmBrown.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.vintageGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FluentIcons.playlist_music,
                    color: AppTheme.vintageGold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    FluentIcons.more,
                    color: AppTheme.warmBeige.withOpacity(0.6),
                    size: 16,
                  ),
                  onPressed: () {
                    // 显示更多选项
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              playlist.name,
              style: const TextStyle(
                color: AppTheme.warmCream,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (playlist.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  playlist.description!,
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${playlist.songs.length} 首歌曲',
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
}

class _SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onAddToPlaylist;

  const _SongListItem({
    required this.song,
    required this.onTap,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.warmBrown.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          FluentIcons.music_note,
          color: AppTheme.vintageGold,
          size: 18,
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: AppTheme.warmCream,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${song.artist} · ${song.album}',
        style: TextStyle(
          color: AppTheme.warmBeige.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${song.year}',
            style: TextStyle(
              color: AppTheme.warmBrown.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              FluentIcons.add,
              color: AppTheme.warmBeige.withOpacity(0.6),
              size: 16,
            ),
            onPressed: onAddToPlaylist,
          ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
