import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/music_service.dart';

// 播放列表控制器
class PlaylistController extends StateNotifier<PlaylistState> {
  PlaylistController() : super(const PlaylistState()) {
    // 使用在线音乐源作为默认播放列表
    final onlinePlaylist = MusicService.createOnlinePlaylist();
    state = state.copyWith(
      playlists: MusicService.getOnlinePlaylists(),
      currentPlaylist: onlinePlaylist,
      currentIndex: 0,
    );
  }

  // 加载播放列表
  void loadPlaylist(Playlist playlist, {int startIndex = 0}) {
    state = state.copyWith(
      currentPlaylist: playlist,
      currentIndex: startIndex.clamp(0, playlist.songs.length - 1),
    );
  }

  // 播放指定歌曲
  void playSong(Song song) {
    if (state.currentPlaylist == null) return;

    final index = state.currentPlaylist!.songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      state = state.copyWith(currentIndex: index);
    }
  }

  // 下一首
  void next() {
    if (state.currentPlaylist == null) return;

    final songs = state.currentPlaylist!.songs;
    int nextIndex;

    if (state.isShuffled) {
      // 随机播放
      nextIndex = Random().nextInt(songs.length);
    } else {
      // 顺序播放
      nextIndex = state.currentIndex + 1;

      // 处理循环模式
      if (nextIndex >= songs.length) {
        if (state.repeatMode == RepeatMode.all) {
          nextIndex = 0;
        } else {
          return; // 不循环，保持在最后一首
        }
      }
    }

    state = state.copyWith(currentIndex: nextIndex);
  }

  // 上一首
  void previous() {
    if (state.currentPlaylist == null) return;

    int prevIndex = state.currentIndex - 1;

    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.currentPlaylist!.songs.length - 1;
      } else {
        return;
      }
    }

    state = state.copyWith(currentIndex: prevIndex);
  }

  // 切换随机播放
  void toggleShuffle() {
    state = state.copyWith(isShuffled: !state.isShuffled);
  }

  // 切换循环模式
  void toggleRepeat() {
    final modes = RepeatMode.values;
    final nextIndex = (modes.indexOf(state.repeatMode) + 1) % modes.length;
    state = state.copyWith(repeatMode: modes[nextIndex]);
  }

  // 创建新播放列表
  void createPlaylist(String name, {String? description}) {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songs: [],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      playlists: [...state.playlists, newPlaylist],
    );
  }

  // 添加歌曲到播放列表
  void addSongToPlaylist(String playlistId, Song song) {
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.id == playlistId) {
        // 检查歌曲是否已存在
        if (!playlist.songs.any((s) => s.id == song.id)) {
          return playlist.copyWith(songs: [...playlist.songs, song]);
        }
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }

  // 从播放列表移除歌曲
  void removeSongFromPlaylist(String playlistId, String songId) {
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.id == playlistId) {
        return playlist.copyWith(
          songs: playlist.songs.where((s) => s.id != songId).toList(),
        );
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }

  // 删除播放列表
  void deletePlaylist(String playlistId) {
    state = state.copyWith(
      playlists: state.playlists.where((p) => p.id != playlistId).toList(),
      currentPlaylist: state.currentPlaylist?.id == playlistId
          ? null
          : state.currentPlaylist,
    );
  }

  // 收藏/取消收藏播放列表
  void toggleFavoritePlaylist(String playlistId) {
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.id == playlistId) {
        return playlist.copyWith(isFavorite: !playlist.isFavorite);
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }

  // 重命名播放列表
  void renamePlaylist(String playlistId, String newName) {
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.id == playlistId) {
        return playlist.copyWith(name: newName);
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }

  // 获取收藏的歌曲
  List<Song> getFavoriteSongs() {
    final favoritePlaylist = state.playlists.firstWhere(
      (p) => p.name == '我的收藏',
      orElse: () => const Playlist(id: '', name: '', songs: []),
    );
    return favoritePlaylist.songs;
  }

  // 添加歌曲到收藏
  void addToFavorites(Song song) {
    final favoritePlaylistIndex = state.playlists.indexWhere(
      (p) => p.name == '我的收藏',
    );

    if (favoritePlaylistIndex == -1) {
      // 创建收藏播放列表
      createPlaylist('我的收藏', description: '我喜爱的歌曲');
    }

    // 找到收藏列表并添加歌曲
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.name == '我的收藏') {
        if (!playlist.songs.any((s) => s.id == song.id)) {
          return playlist.copyWith(
            songs: [...playlist.songs, song],
            isFavorite: true,
          );
        }
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }

  // 从收藏移除
  void removeFromFavorites(String songId) {
    final updatedPlaylists = state.playlists.map((playlist) {
      if (playlist.name == '我的收藏') {
        return playlist.copyWith(
          songs: playlist.songs.where((s) => s.id != songId).toList(),
        );
      }
      return playlist;
    }).toList();

    state = state.copyWith(playlists: updatedPlaylists);
  }
}

// Provider
final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  return PlaylistController();
});
