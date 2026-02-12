import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/components/window_title_bar.dart';

// 设置状态
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

  const SettingsState({
    this.masterVolume = 1.0,
    this.enableVisualizer = true,
    this.enableLyrics = true,
    this.enableNotifications = true,
    this.audioQuality = 'High',
    this.downloadPath = '',
    this.autoPlay = false,
    this.crossfade = true,
    this.crossfadeDuration = 2.0,
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
    );
  }
}

// 设置控制器
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState());

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
}

// Provider
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('设置'),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 音频设置
            _buildSection(
              context,
              icon: FluentIcons.speakers,
              title: '音频设置',
              children: [
                _buildVolumeSlider(
                  context,
                  label: '主音量',
                  value: settings.masterVolume,
                  onChanged: controller.setMasterVolume,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  context,
                  label: '音频质量',
                  value: settings.audioQuality,
                  items: const ['Low', 'Medium', 'High', 'Lossless'],
                  onChanged: (value) {
                    if (value != null) controller.setAudioQuality(value);
                  },
                ),
                const SizedBox(height: 16),
                _buildToggle(
                  context,
                  label: '自动播放',
                  description: '启动时自动播放上次播放的歌曲',
                  value: settings.autoPlay,
                  onChanged: (_) => controller.toggleAutoPlay(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 播放设置
            _buildSection(
              context,
              icon: FluentIcons.play_resume,
              title: '播放设置',
              children: [
                _buildToggle(
                  context,
                  label: '淡入淡出',
                  description: '歌曲切换时添加淡入淡出效果',
                  value: settings.crossfade,
                  onChanged: (_) => controller.toggleCrossfade(),
                ),
                if (settings.crossfade)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 8),
                    child: _buildSlider(
                      context,
                      label: '淡入淡出时长',
                      value: settings.crossfadeDuration,
                      min: 0.5,
                      max: 5.0,
                      suffix: '秒',
                      onChanged: controller.setCrossfadeDuration,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // 显示设置
            _buildSection(
              context,
              icon: FluentIcons.view,
              title: '显示设置',
              children: [
                _buildToggle(
                  context,
                  label: '音频可视化',
                  description: '显示音频可视化效果',
                  value: settings.enableVisualizer,
                  onChanged: (_) => controller.toggleVisualizer(),
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  context,
                  label: '歌词显示',
                  description: '显示同步歌词',
                  value: settings.enableLyrics,
                  onChanged: (_) => controller.toggleLyrics(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 通知设置
            _buildSection(
              context,
              icon: FluentIcons.ringer,
              title: '通知设置',
              children: [
                _buildToggle(
                  context,
                  label: '启用通知',
                  description: '接收播放和信件通知',
                  value: settings.enableNotifications,
                  onChanged: (_) => controller.toggleNotifications(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 存储设置
            _buildSection(
              context,
              icon: FluentIcons.save_as,
              title: '存储设置',
              children: [
                _buildPathSelector(
                  context,
                  label: '下载路径',
                  path: settings.downloadPath.isEmpty
                      ? '默认路径'
                      : settings.downloadPath,
                  onPressed: () {
                    // 打开文件夹选择器
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  label: '缓存大小',
                  value: '128 MB',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 关于
            _buildSection(
              context,
              icon: FluentIcons.info,
              title: '关于',
              children: [
                _buildInfoRow(
                  context,
                  label: '版本',
                  value: '1.0.0',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  label: '开发者',
                  value: '文艺复兴团队',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ContentDialog(
                        title: const Text('检查更新'),
                        content: const Text('当前已是最新版本'),
                        actions: [
                          Button(
                            child: const Text('确定'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('检查更新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Icon(
                icon,
                color: AppTheme.vintageGold,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  color: AppTheme.warmCream,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.warmCream,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ToggleSwitch(
          checked: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.warmCream,
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: AppTheme.vintageGold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${value.toStringAsFixed(1)}$suffix',
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.warmCream,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ComboBox<String>(
            value: value,
            items: items.map((item) {
              return ComboBoxItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPathSelector(
    BuildContext context, {
    required String label,
    required String path,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.warmCream,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.warmBrown.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    path,
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: onPressed,
                child: const Text('浏览'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.warmCream,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
