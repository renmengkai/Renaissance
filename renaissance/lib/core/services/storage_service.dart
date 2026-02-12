import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 存储服务
class StorageService {
  static SharedPreferences? _prefs;

  // 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 字符串操作
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  // 整数操作
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  // 布尔值操作
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // 双精度浮点数操作
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  // 字符串列表操作
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  // JSON 对象操作
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // JSON 列表操作
  static Future<bool> setJsonList(
      String key, List<Map<String, dynamic>> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  static List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      final list = jsonDecode(jsonString) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // 删除键
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // 清空所有数据
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // 检查键是否存在
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // 获取所有键
  static Set<String> getKeys() {
    return _prefs?.getKeys() ?? {};
  }

  // 重新加载
  static Future<void> reload() async {
    await _prefs?.reload();
  }
}

// 存储键名常量
class StorageKeys {
  // 设置
  static const String settings = 'settings';
  static const String masterVolume = 'master_volume';
  static const String enableVisualizer = 'enable_visualizer';
  static const String enableLyrics = 'enable_lyrics';
  static const String enableNotifications = 'enable_notifications';
  static const String audioQuality = 'audio_quality';
  static const String autoPlay = 'auto_play';
  static const String crossfade = 'crossfade';
  static const String crossfadeDuration = 'crossfade_duration';

  // 播放状态
  static const String lastPlayedSongId = 'last_played_song_id';
  static const String lastPlayedPosition = 'last_played_position';
  static const String playbackHistory = 'playback_history';

  // 播放列表
  static const String playlists = 'playlists';
  static const String favoriteSongs = 'favorite_songs';

  // 搜索历史
  static const String searchHistory = 'search_history';

  // 用户数据
  static const String userLetters = 'user_letters';
  static const String readLetters = 'read_letters';

  // 主题
  static const String themeMode = 'theme_mode';
  static const String accentColor = 'accent_color';
}
