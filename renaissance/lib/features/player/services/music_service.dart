import '../models/song.dart';
import '../models/playlist.dart';

/// 音乐源服务
/// 提供本地音乐资源
class MusicService {
  /// 获取本地音乐列表
  static List<Song> getFreeOnlineSongs() {
    return [
      Song(
        id: 'online_1',
        title: 'Summer Breeze',
        artist: 'Relaxing Vibes',
        album: 'Chill Sessions',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/song1.wav',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#4ECDC4',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_2',
        title: 'Midnight Dreams',
        artist: 'Lofi Study',
        album: 'Night Vibes',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/song2.wav',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#2C3E50',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_3',
        title: 'Ocean Waves',
        artist: 'Nature Sounds',
        album: 'Ambient Nature',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/song3.wav',
        duration: const Duration(minutes: 4, seconds: 15),
        dominantColor: '#1E90FF',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_4',
        title: 'Piano Memories',
        artist: 'Classical Relax',
        album: 'Piano Dreams',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/song1.wav',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#A0522D',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_5',
        title: 'Digital Love',
        artist: 'Electronic Beats',
        album: 'Synthwave',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/song2.wav',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#9400D3',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_6',
        title: 'Forest Walk',
        artist: 'Nature Ambience',
        album: 'Natural Sounds',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/song3.wav',
        duration: const Duration(minutes: 4, seconds: 15),
        dominantColor: '#228B22',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_7',
        title: 'Sunset Boulevard',
        artist: 'Jazz Masters',
        album: 'Evening Jazz',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/song1.wav',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#FF6347',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_8',
        title: 'Starlight',
        artist: 'Cosmic Sounds',
        album: 'Space Ambient',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/song2.wav',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#191970',
        hasGoldenLetter: false,
      ),
    ];
  }

  /// 创建默认播放列表
  static Playlist createOnlinePlaylist() {
    return Playlist(
      id: 'online_playlist_1',
      name: '本地音乐',
      description: '本地音频文件',
      songs: getFreeOnlineSongs(),
      createdAt: DateTime.now(),
      coverUrl: 'assets/images/cover1.jpg',
    );
  }

  /// 获取多个播放列表
  static List<Playlist> getOnlinePlaylists() {
    return [
      createOnlinePlaylist(),
      Playlist(
        id: 'chill_playlist',
        name: '轻松氛围',
        description: '适合放松和学习的音乐',
        songs: getFreeOnlineSongs().take(4).toList(),
        createdAt: DateTime.now(),
        coverUrl: 'assets/images/cover1.jpg',
      ),
      Playlist(
        id: 'focus_playlist',
        name: '专注工作',
        description: '帮助提高专注力的音乐',
        songs: getFreeOnlineSongs().skip(4).toList(),
        createdAt: DateTime.now(),
        coverUrl: 'assets/images/cover2.jpg',
      ),
    ];
  }
}
