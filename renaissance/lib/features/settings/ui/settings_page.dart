import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart' hide showDialog;
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart' hide Colors, Slider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/vintage_settings.dart';
import '../../player/ui/music_source_settings.dart';

class SettingsState {
  final double masterVolume;
  final bool enableVisualizer;
  final bool enableLyrics;
  final bool enableNotifications;
  final String audioQuality;
  final String downloadPath;
  final bool autoPlay;
  final bool crossfade;
  final double crossfadeDuration;
  final bool enableSyncCoverLoading;

  const SettingsState({
    this.masterVolume = 0.5,
    this.enableVisualizer = true,
    this.enableLyrics = true,
    this.enableNotifications = true,
    this.audioQuality = 'High',
    this.downloadPath = '',
    this.autoPlay = false,
    this.crossfade = true,
    this.crossfadeDuration = 2.0,
    this.enableSyncCoverLoading = false,
  });

  SettingsState copyWith({
    double? masterVolume,
    bool? enableVisualizer,
    bool? enableLyrics,
    bool? enableNotifications,
    String? audioQuality,
    String? downloadPath,
    bool? autoPlay,
    bool? crossfade,
    double? crossfadeDuration,
    bool? enableSyncCoverLoading,
  }) {
    return SettingsState(
      masterVolume: masterVolume ?? this.masterVolume,
      enableVisualizer: enableVisualizer ?? this.enableVisualizer,
      enableLyrics: enableLyrics ?? this.enableLyrics,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      audioQuality: audioQuality ?? this.audioQuality,
      downloadPath: downloadPath ?? this.downloadPath,
      autoPlay: autoPlay ?? this.autoPlay,
      crossfade: crossfade ?? this.crossfade,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      enableSyncCoverLoading: enableSyncCoverLoading ?? this.enableSyncCoverLoading,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    // 初始化时从本地存储加载设置
    loadSettings();
  }

  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume);
  }

  void toggleVisualizer() {
    state = state.copyWith(enableVisualizer: !state.enableVisualizer);
  }

  void toggleLyrics() {
    state = state.copyWith(enableLyrics: !state.enableLyrics);
  }

  void toggleNotifications() {
    state = state.copyWith(enableNotifications: !state.enableNotifications);
  }

  void setAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
  }

  void setDownloadPath(String path) {
    state = state.copyWith(downloadPath: path);
  }

  void toggleAutoPlay() {
    state = state.copyWith(autoPlay: !state.autoPlay);
  }

  void toggleCrossfade() {
    state = state.copyWith(crossfade: !state.crossfade);
  }

  void setCrossfadeDuration(double duration) {
    state = state.copyWith(crossfadeDuration: duration);
  }

  void toggleSyncCoverLoading() {
    final newValue = !state.enableSyncCoverLoading;
    state = state.copyWith(enableSyncCoverLoading: newValue);
    // 持久化到本地存储
    StorageService.setBool(StorageKeys.enableSyncCoverLoading, newValue);
  }

  /// 从本地存储加载设置
  void loadSettings() {
    final enableSyncCoverLoading = StorageService.getBool(StorageKeys.enableSyncCoverLoading) ?? false;
    state = state.copyWith(enableSyncCoverLoading: enableSyncCoverLoading);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isMobile) {
      return _buildMobileSettings(context, ref);
    }
    return _buildDesktopSettings(context, ref);
  }

  Widget _buildMobileSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return m.Scaffold(
      backgroundColor: AppTheme.softBlack,
      appBar: m.AppBar(
        backgroundColor: AppTheme.softBlack,
        foregroundColor: AppTheme.warmCream,
        elevation: 0,
        title: const Text('设置'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.softBlack,
              AppTheme.charcoal,
            ],
          ),
        ),
        child: _buildSettingsContent(context, ref, settings, controller),
      ),
    );
  }

  Widget _buildDesktopSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.vintageGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FluentIcons.settings,
                color: AppTheme.vintageGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '设置',
              style: TextStyle(
                color: AppTheme.warmCream,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
      ),
      content: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.softBlack,
              AppTheme.charcoal,
            ],
          ),
        ),
        child: _buildSettingsContent(context, ref, settings, controller),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            icon: FluentIcons.speakers,
            title: '音频设置',
            delay: 100.ms,
            children: [
              VintageSlider(
                label: '主音量',
                value: settings.masterVolume,
                onChanged: controller.setMasterVolume,
              ),
              const SizedBox(height: 16),
              VintageDropdown<String>(
                value: settings.audioQuality,
                label: '音频质量',
                items: [
                  DropdownItem(value: 'Low', label: '低'),
                  DropdownItem(value: 'Medium', label: '中'),
                  DropdownItem(value: 'High', label: '高'),
                  DropdownItem(value: 'Lossless', label: '无损'),
                ],
                onChanged: (value) {
                  if (value != null) controller.setAudioQuality(value);
                },
              ),
              const SizedBox(height: 12),
              VintageToggleSwitch(
                label: '自动播放',
                description: '启动时自动播放上次播放的歌曲',
                value: settings.autoPlay,
                onChanged: (_) => controller.toggleAutoPlay(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: FluentIcons.play_resume,
            title: '播放设置',
            delay: 200.ms,
            children: [
              VintageToggleSwitch(
                label: '淡入淡出',
                description: '歌曲切换时添加淡入淡出效果',
                value: settings.crossfade,
                onChanged: (_) => controller.toggleCrossfade(),
              ),
              if (settings.crossfade)
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 16),
                  child: VintageSlider(
                    label: '淡入淡出时长',
                    value: settings.crossfadeDuration / 5.0,
                    min: 0.1,
                    max: 1.0,
                    suffix: '秒',
                    onChanged: (v) => controller.setCrossfadeDuration(v * 5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: FluentIcons.view,
            title: '显示设置',
            delay: 300.ms,
            children: [
              VintageToggleSwitch(
                label: '音频可视化',
                description: '显示音频可视化效果',
                value: settings.enableVisualizer,
                onChanged: (_) => controller.toggleVisualizer(),
              ),
              const SizedBox(height: 12),
              VintageToggleSwitch(
                label: '歌词显示',
                description: '显示同步歌词',
                value: settings.enableLyrics,
                onChanged: (_) => controller.toggleLyrics(),
              ),
              const SizedBox(height: 12),
              VintageToggleSwitch(
                label: '同步加载歌曲封面',
                description: '在歌曲列表中显示封面图片（可能影响音乐播放流畅度）',
                value: settings.enableSyncCoverLoading,
                onChanged: (_) => controller.toggleSyncCoverLoading(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: FluentIcons.ringer,
            title: '通知设置',
            delay: 400.ms,
            children: [
              VintageToggleSwitch(
                label: '启用通知',
                description: '接收播放和信件通知',
                value: settings.enableNotifications,
                onChanged: (_) => controller.toggleNotifications(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: FluentIcons.save_as,
            title: '存储设置',
            delay: 500.ms,
            children: [
              _buildPathSelector(
                context,
                label: '下载路径',
                path: settings.downloadPath.isEmpty
                    ? '默认路径'
                    : settings.downloadPath,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              InfoRow(
                label: '缓存大小',
                value: '128 MB',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const MusicSourceSettings(),
          const SizedBox(height: 24),
          _buildSection(
            context,
            icon: FluentIcons.info,
            title: '关于',
            delay: 600.ms,
            children: [
              InfoRow(
                label: '版本',
                value: '1.0.0',
              ),
              const SizedBox(height: 8),
              InfoRow(
                label: '开发者',
                value: '文艺复兴团队',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  VintageButton(
                    text: '检查更新',
                    isFilled: true,
                    onPressed: () {
                      _showUpdateDialog(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  VintageButton(
                    text: '清除缓存',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    if (PlatformUtils.isMobile) {
      m.showDialog(
        context: context,
        builder: (ctx) => m.AlertDialog(
          backgroundColor: AppTheme.charcoal,
          title: const Text('检查更新', style: TextStyle(color: AppTheme.warmCream)),
          content: const Text('当前已是最新版本', style: TextStyle(color: AppTheme.warmBeige)),
          actions: [
            m.TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定', style: TextStyle(color: AppTheme.vintageGold)),
            ),
          ],
        ),
      );
    } else {
      fluent.showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('检查更新'),
          content: const Text('当前已是最新版本'),
          actions: [
            Button(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
    Duration? delay,
  }) {
    return GlassCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ).animate().fadeIn(delay: delay ?? 0.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPathSelector(
    BuildContext context, {
    required String label,
    required String path,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.warmBeige,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softBlack.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warmBrown.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  path,
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            VintageButton(
              text: '浏览',
              onPressed: onPressed,
            ),
          ],
        ),
      ],
    );
  }
}
