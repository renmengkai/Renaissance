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
        title: 'Gentle Rain',
        artist: 'Relaxing Vibes',
        album: 'Chill Sessions',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/eryliaa-gentle-rain-for-relaxation-and-sleep-337279.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#4ECDC4',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_2',
        title: 'Ocean Waves',
        artist: 'Lofi Study',
        album: 'Night Vibes',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/richardmultimedia-ocean-waves-250310.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#2C3E50',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_3',
        title: 'Forest Birds',
        artist: 'Nature Sounds',
        album: 'Ambient Nature',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/empressnefertitimumbi-forest-bird-harmonies-258412.mp3',
        duration: const Duration(minutes: 4, seconds: 15),
        dominantColor: '#1E90FF',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_4',
        title: 'Night Rain',
        artist: 'Classical Relax',
        album: 'Piano Dreams',
        year: 2024,
        coverUrl: 'assets/images/cover1.jpg',
        audioUrl: 'assets/audio/mindmist-night-rain-with-distant-thunder-321446.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
        dominantColor: '#A0522D',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_5',
        title: 'Soft Wind',
        artist: 'Electronic Beats',
        album: 'Synthwave',
        year: 2024,
        coverUrl: 'assets/images/cover2.jpg',
        audioUrl: 'assets/audio/storegraphic-soft-wind-318856.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        dominantColor: '#9400D3',
        hasGoldenLetter: false,
      ),
      Song(
        id: 'online_6',
        title: 'Thunder',
        artist: 'Nature Ambience',
        album: 'Natural Sounds',
        year: 2024,
        coverUrl: 'assets/images/cover3.jpg',
        audioUrl: 'assets/audio/u_vrs223ln83-loud-thunder-439064.mp3',
        duration: const Duration(minutes: 4, seconds: 15),
        dominantColor: '#228B22',
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
