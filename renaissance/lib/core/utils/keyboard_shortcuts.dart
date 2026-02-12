import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 快捷键管理器
class KeyboardShortcutsManager {
  static final Map<ShortcutActivator, VoidCallback> _shortcuts = {};

  static void register(ShortcutActivator shortcut, VoidCallback action) {
    _shortcuts[shortcut] = action;
  }

  static void unregister(ShortcutActivator shortcut) {
    _shortcuts.remove(shortcut);
  }

  static void clear() {
    _shortcuts.clear();
  }

  static bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      for (final entry in _shortcuts.entries) {
        if (entry.key.accepts(event, HardwareKeyboard.instance)) {
          entry.value();
          return true;
        }
      }
    }
    return false;
  }
}

// 预定义的快捷键
class AppShortcuts {
  // 播放控制
  static const playPause = SingleActivator(LogicalKeyboardKey.space);
  static const nextTrack = SingleActivator(LogicalKeyboardKey.arrowRight, control: true);
  static const previousTrack = SingleActivator(LogicalKeyboardKey.arrowLeft, control: true);
  static const stop = SingleActivator(LogicalKeyboardKey.keyS, control: true);
  static const seekForward = SingleActivator(LogicalKeyboardKey.arrowRight, shift: true);
  static const seekBackward = SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true);

  // 音量控制
  static const volumeUp = SingleActivator(LogicalKeyboardKey.arrowUp, control: true);
  static const volumeDown = SingleActivator(LogicalKeyboardKey.arrowDown, control: true);
  static const mute = SingleActivator(LogicalKeyboardKey.keyM, control: true);

  // 界面控制
  static const toggleFullscreen = SingleActivator(LogicalKeyboardKey.f11);
  static const toggleMixer = SingleActivator(LogicalKeyboardKey.keyE, control: true);
  static const toggleLyrics = SingleActivator(LogicalKeyboardKey.keyL, control: true);
  static const openSettings = SingleActivator(LogicalKeyboardKey.comma, control: true);
  static const openSearch = SingleActivator(LogicalKeyboardKey.keyF, control: true);

  // 导航
  static const goToLibrary = SingleActivator(LogicalKeyboardKey.digit1, alt: true);
  static const goToPlaylist = SingleActivator(LogicalKeyboardKey.digit2, alt: true);
  static const goToFavorites = SingleActivator(LogicalKeyboardKey.digit3, alt: true);

  // 其他
  static const shuffle = SingleActivator(LogicalKeyboardKey.keyS, alt: true);
  static const repeat = SingleActivator(LogicalKeyboardKey.keyR, alt: true);
  static const like = SingleActivator(LogicalKeyboardKey.keyL, alt: true);
  static const writeLetter = SingleActivator(LogicalKeyboardKey.keyW, control: true);
}

// 快捷键帮助对话框
class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('键盘快捷键'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('播放控制', [
              _buildShortcutItem('Space', '播放/暂停'),
              _buildShortcutItem('Ctrl + →', '下一首'),
              _buildShortcutItem('Ctrl + ←', '上一首'),
              _buildShortcutItem('Ctrl + S', '停止'),
              _buildShortcutItem('Shift + →', '快进 5 秒'),
              _buildShortcutItem('Shift + ←', '后退 5 秒'),
            ]),
            const SizedBox(height: 16),
            _buildSection('音量控制', [
              _buildShortcutItem('Ctrl + ↑', '音量增加'),
              _buildShortcutItem('Ctrl + ↓', '音量减少'),
              _buildShortcutItem('Ctrl + M', '静音'),
            ]),
            const SizedBox(height: 16),
            _buildSection('界面控制', [
              _buildShortcutItem('F11', '全屏'),
              _buildShortcutItem('Ctrl + E', '显示/隐藏混音台'),
              _buildShortcutItem('Ctrl + L', '显示/隐藏歌词'),
              _buildShortcutItem('Ctrl + ,', '打开设置'),
              _buildShortcutItem('Ctrl + F', '搜索'),
            ]),
            const SizedBox(height: 16),
            _buildSection('导航', [
              _buildShortcutItem('Alt + 1', '音乐库'),
              _buildShortcutItem('Alt + 2', '播放列表'),
              _buildShortcutItem('Alt + 3', '我的收藏'),
            ]),
            const SizedBox(height: 16),
            _buildSection('其他', [
              _buildShortcutItem('Alt + S', '随机播放'),
              _buildShortcutItem('Alt + R', '循环模式'),
              _buildShortcutItem('Alt + L', '收藏歌曲'),
              _buildShortcutItem('Ctrl + W', '写一封信'),
            ]),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text('关闭'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// 快捷键监听器组件
class ShortcutsListener extends StatefulWidget {
  final Widget child;
  final Map<ShortcutActivator, VoidCallback> shortcuts;

  const ShortcutsListener({
    super.key,
    required this.child,
    required this.shortcuts,
  });

  @override
  State<ShortcutsListener> createState() => _ShortcutsListenerState();
}

class _ShortcutsListenerState extends State<ShortcutsListener> {
  @override
  void initState() {
    super.initState();
    // 注册快捷键
    widget.shortcuts.forEach((shortcut, action) {
      KeyboardShortcutsManager.register(shortcut, action);
    });
  }

  @override
  void dispose() {
    // 注销快捷键
    widget.shortcuts.keys.forEach(KeyboardShortcutsManager.unregister);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (KeyboardShortcutsManager.handleKeyEvent(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
