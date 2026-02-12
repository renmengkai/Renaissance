import 'package:freezed_annotation/freezed_annotation.dart';
import 'song.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required List<Song> songs,
    String? description,
    String? coverUrl,
    DateTime? createdAt,
    @Default(0) int playCount,
    @Default(false) bool isFavorite,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}

// 播放列表管理状态
class PlaylistState {
  final List<Playlist> playlists;
  final Playlist? currentPlaylist;
  final int currentIndex;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final PlayMode playMode;

  const PlaylistState({
    this.playlists = const [],
    this.currentPlaylist,
    this.currentIndex = 0,
    this.isShuffled = false,
    this.repeatMode = RepeatMode.none,
    this.playMode = PlayMode.sequential,
  });

  PlaylistState copyWith({
    List<Playlist>? playlists,
    Playlist? currentPlaylist,
    int? currentIndex,
    bool? isShuffled,
    RepeatMode? repeatMode,
    PlayMode? playMode,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      playMode: playMode ?? this.playMode,
    );
  }

  Song? get currentSong {
    if (currentPlaylist == null || currentPlaylist!.songs.isEmpty) {
      return null;
    }
    if (currentIndex < 0 || currentIndex >= currentPlaylist!.songs.length) {
      return null;
    }
    return currentPlaylist!.songs[currentIndex];
  }

  bool get hasNext =>
      currentPlaylist != null && currentIndex < currentPlaylist!.songs.length - 1;

  bool get hasPrevious => currentPlaylist != null && currentIndex > 0;
}

enum RepeatMode {
  none,
  all,
  one,
}

enum PlayMode {
  sequential,
  shuffle,
  blindBox,
}

// 示例播放列表
final List<Playlist> samplePlaylists = [
  Playlist(
    id: '1',
    name: '90年代经典',
    description: '那些年的经典老歌',
    songs: sampleSongs,
    createdAt: DateTime.now(),
  ),
  Playlist(
    id: '2',
    name: '我的收藏',
    description: '精心挑选的珍藏',
    songs: [sampleSongs[0], sampleSongs[1]],
    createdAt: DateTime.now(),
    isFavorite: true,
  ),
  Playlist(
    id: '3',
    name: '深夜电台',
    description: '适合深夜聆听的歌曲',
    songs: [sampleSongs[2]],
    createdAt: DateTime.now(),
  ),
];
