import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Slider, SliderTheme, SliderThemeData, Colors, IconButton, ButtonStyle, Divider, DividerThemeData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import 'lofi_mixer.dart';

class MixerPanel extends ConsumerWidget {
  const MixerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixerState = ref.watch(loFiMixerProvider);
    final mixer = ref.read(loFiMixerProvider.notifier);

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmBrown.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                FluentIcons.equalizer,
                color: AppTheme.vintageGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '混音台',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  color: AppTheme.warmCream,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // 停止全部按钮
              if (mixerState.activeTrackCount > 0)
                IconButton(
                  icon: Icon(
                    FluentIcons.stop_solid,
                    color: Colors.orange.withOpacity(0.8),
                    size: 16,
                  ),
                  onPressed: () => mixer.stopAll(),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 旋律滑块
          _buildSlider(
            context,
            icon: FluentIcons.music_note,
            label: '旋律',
            value: mixerState.mainVolume,
            color: AppTheme.vintageGold,
            onChanged: mixer.setMainVolume,
          ),
          const SizedBox(height: 20),

          // 白噪音总音量（当有多轨时显示）
          if (mixerState.activeTrackCount > 1)
            Column(
              children: [
                _buildSlider(
                  context,
                  icon: FluentIcons.volume3,
                  label: '白噪音总音量',
                  value: mixerState.totalWhiteNoiseVolume,
                  color: AppTheme.warmBeige,
                  onChanged: mixer.setWhiteNoiseVolume,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppTheme.warmBrown.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // 活跃的白噪音轨道
          if (mixerState.activeTrackCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '活跃音效',
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ...mixerState.activeTracks.entries.map((entry) {
                  return _buildActiveTrackControl(
                    context,
                    category: entry.key,
                    track: entry.value,
                    mixer: mixer,
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppTheme.warmBrown.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // 可添加的白噪音类别
          Text(
            '添加音效',
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WhiteNoiseCategory.values
                .where((c) => !mixerState.isCategoryActive(c))
                .map((category) {
              return _buildCategoryChip(
                context,
                category: category,
                onTap: () => mixer.toggleCategory(category),
              );
            }).toList(),
          ),

          // 错误提示
          if (mixerState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.warning,
                    color: Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mixerState.errorMessage!,
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildActiveTrackControl(
    BuildContext context, {
    required WhiteNoiseCategory category,
    required ActiveTrack track,
    required LoFiMixer mixer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warmBrown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
                _getIconForCategory(category),
                color: AppTheme.vintageGold,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  track.track.displayName,
                  style: TextStyle(
                    color: AppTheme.warmCream,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 切换该类别下的其他音频
              if (_getTrackCountForCategory(category) > 1)
                IconButton(
                  icon: Icon(
                    FluentIcons.sync,
                    color: AppTheme.warmBeige.withOpacity(0.7),
                    size: 14,
                  ),
                  onPressed: () => mixer.switchTrackInCategory(category),
                ),
              // 移除按钮
              IconButton(
                icon: Icon(
                  FluentIcons.chrome_close,
                  color: Colors.orange.withOpacity(0.7),
                  size: 14,
                ),
                onPressed: () => mixer.toggleCategory(category),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 音量滑块
          Row(
            children: [
              Icon(
                FluentIcons.volume0,
                color: AppTheme.warmBeige.withOpacity(0.5),
                size: 12,
              ),
              Expanded(
                child: Slider(
                  min: 0.0,
                  max: 100.0,
                  value: (track.volume * 100).clamp(0.0, 100.0),
                  onChanged: (v) => mixer.setCategoryVolume(category, v / 100),
                ),
              ),
              Icon(
                FluentIcons.volume3,
                color: AppTheme.warmBeige.withOpacity(0.5),
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                '${(track.volume * 100).toInt()}%',
                style: TextStyle(
                  color: AppTheme.warmBeige,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required WhiteNoiseCategory category,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.warmBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.warmBrown.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForCategory(category),
              color: AppTheme.warmBeige.withOpacity(0.8),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              category.displayName,
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              FluentIcons.add,
              color: AppTheme.vintageGold,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
    bool disabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: FluentTheme.of(context).typography.caption?.copyWith(
                color: disabled ? Colors.grey : AppTheme.warmBeige,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).toInt()}%',
              style: FluentTheme.of(context).typography.caption?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          min: 0.0,
          max: 100.0,
          value: (value * 100).clamp(0.0, 100.0),
          onChanged: disabled ? null : (v) => onChanged(v / 100),
        ),
      ],
    );
  }

  IconData _getIconForCategory(WhiteNoiseCategory category) {
    switch (category) {
      case WhiteNoiseCategory.whitenoise:
        return FluentIcons.volume3;
      case WhiteNoiseCategory.tv:
        return FluentIcons.t_v_monitor;
      case WhiteNoiseCategory.clock:
        return FluentIcons.clock;
      case WhiteNoiseCategory.paper:
        return FluentIcons.page;
      case WhiteNoiseCategory.rain:
        return FluentIcons.cloud_weather;
      case WhiteNoiseCategory.grass:
        return FluentIcons.flower;
      case WhiteNoiseCategory.wind:
        return FluentIcons.air_tickets;
      case WhiteNoiseCategory.bird:
        return FluentIcons.trophy;
      case WhiteNoiseCategory.village:
        return FluentIcons.home;
      case WhiteNoiseCategory.ocean:
        return FluentIcons.rain;
      case WhiteNoiseCategory.street:
        return FluentIcons.people;
    }
  }

  int _getTrackCountForCategory(WhiteNoiseCategory category) {
    return whiteNoiseTracks.where((t) => t.category == category).length;
  }
}
