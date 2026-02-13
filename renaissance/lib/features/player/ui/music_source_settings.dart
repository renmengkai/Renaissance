import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart' hide showDialog;
import 'package:flutter/material.dart' hide Colors, Slider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/vintage_settings.dart';
import '../models/music_source.dart';
import '../services/music_source_manager.dart';
import '../services/local_music_service.dart';
import 'package:file_selector/file_selector.dart';

class MusicSourceSettings extends ConsumerStatefulWidget {
  const MusicSourceSettings({super.key});

  @override
  ConsumerState<MusicSourceSettings> createState() => _MusicSourceSettingsState();
}

class _MusicSourceSettingsState extends ConsumerState<MusicSourceSettings> {
  bool _isTestingConnection = false;
  bool? _connectionTestResult;

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(musicSourceManagerProvider);
    final manager = ref.read(musicSourceManagerProvider.notifier);

    return GlassCard(
      icon: FluentIcons.cloud_upload,
      title: '音乐源',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '管理本地和云端音乐源',
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ...sources.map((source) => _buildSourceItem(source, manager)),
          const SizedBox(height: 16),
          Row(
            children: [
              VintageButton(
                text: '添加本地文件夹',
                onPressed: () => _addLocalSource(manager),
              ),
              const SizedBox(width: 12),
              VintageButton(
                text: '添加云存储',
                isFilled: true,
                onPressed: () => _showAddCloudDialog(context, manager),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSourceItem(MusicSource source, MusicSourceManager manager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softBlack.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: source.isEnabled
              ? AppTheme.vintageGold.withOpacity(0.2)
              : AppTheme.warmBrown.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getSourceColor(source).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSourceIcon(source),
              color: _getSourceColor(source),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      source.name,
                      style: const TextStyle(
                        color: AppTheme.warmCream,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSourceColor(source).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSourceTypeLabel(source),
                        style: TextStyle(
                          color: _getSourceColor(source),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getSourceDescription(source),
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          VintageToggleSwitch(
            value: source.isEnabled,
            onChanged: (enabled) => manager.toggleSource(source.id, enabled),
          ),
          if (source.type == MusicSourceType.cloud) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                FluentIcons.delete,
                color: AppTheme.warmBeige.withOpacity(0.6),
                size: 16,
              ),
              onPressed: () => _confirmDeleteSource(source, manager),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSourceColor(MusicSource source) {
    switch (source.type) {
      case MusicSourceType.local:
        return AppTheme.warmBeige;
      case MusicSourceType.cloud:
        switch (source.cloudProvider) {
          case CloudProvider.qiniu:
            return const Color(0xFF00C1DE);
          case CloudProvider.aliyun:
            return const Color(0xFFFF6A00);
          case CloudProvider.tencent:
            return const Color(0xFF00A4FF);
          default:
            return AppTheme.vintageGold;
        }
    }
  }

  IconData _getSourceIcon(MusicSource source) {
    switch (source.type) {
      case MusicSourceType.local:
        return FluentIcons.folder_open;
      case MusicSourceType.cloud:
        return FluentIcons.cloud_upload;
    }
  }

  String _getSourceTypeLabel(MusicSource source) {
    switch (source.type) {
      case MusicSourceType.local:
        return '本地';
      case MusicSourceType.cloud:
        return source.cloudProvider != null
            ? CloudProviderHelper.getDisplayName(source.cloudProvider!)
            : '云端';
    }
  }

  String _getSourceDescription(MusicSource source) {
    switch (source.type) {
      case MusicSourceType.local:
        return '本地音乐文件夹';
      case MusicSourceType.cloud:
        return source.baseUrl ?? '云存储';
    }
  }

  Future<void> _addLocalSource(MusicSourceManager manager) async {
    final directory = await LocalMusicService.selectMusicDirectory();
    if (directory != null) {
      final source = MusicSource(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: directory.split('\\').last,
        type: MusicSourceType.local,
        isEnabled: true,
      );
      await manager.addSource(source);
    }
  }

  void _showAddCloudDialog(BuildContext context, MusicSourceManager manager) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    CloudProvider selectedProvider = CloudProvider.custom;

    fluent.showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ContentDialog(
          title: Row(
            children: [
              Icon(FluentIcons.cloud_add, color: AppTheme.vintageGold, size: 20),
              const SizedBox(width: 12),
              const Text('添加云存储'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  '名称',
                  style: TextStyle(
                    color: AppTheme.warmBeige,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextBox(
                  controller: nameController,
                  placeholder: '例如：我的七牛云音乐',
                  style: TextStyle(color: AppTheme.warmCream),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '云服务商',
                  style: TextStyle(
                    color: AppTheme.warmBeige,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warmBrown.withOpacity(0.3)),
                  ),
                  child: DropdownButton<CloudProvider>(
                    value: selectedProvider,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.charcoal,
                    items: CloudProvider.values.map((provider) {
                      return DropdownMenuItem(
                        value: provider,
                        child: Text(
                          CloudProviderHelper.getDisplayName(provider),
                          style: TextStyle(color: AppTheme.warmCream),
                        ),
                      );
                    }).toList(),
                    onChanged: (provider) {
                      if (provider != null) {
                        setState(() {
                          selectedProvider = provider;
                          urlController.text = CloudProviderHelper.getExampleUrl(provider);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '外链地址',
                  style: TextStyle(
                    color: AppTheme.warmBeige,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextBox(
                  controller: urlController,
                  placeholder: '例如：http://xxx.sabkt.gdipper.com',
                  style: TextStyle(color: AppTheme.warmCream),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '示例：http://taec9n7kt.sabkt.gdipper.com',
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                if (_connectionTestResult != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _connectionTestResult! ? FluentIcons.check_mark : FluentIcons.cancel,
                        color: _connectionTestResult! ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connectionTestResult! ? '连接成功' : '连接失败',
                        style: TextStyle(
                          color: _connectionTestResult! ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Button(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTestingConnection)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  else
                    const Icon(FluentIcons.plug_connected, size: 14),
                  const SizedBox(width: 8),
                  const Text('测试连接'),
                ],
              ),
              onPressed: _isTestingConnection
                  ? null
                  : () async {
                      if (urlController.text.isEmpty) return;
                      setState(() {
                        _isTestingConnection = true;
                        _connectionTestResult = null;
                      });
                      final result = await manager.testCloudConnection(urlController.text);
                      setState(() {
                        _isTestingConnection = false;
                        _connectionTestResult = result;
                      });
                    },
            ),
            Button(
              child: const Text('取消'),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _connectionTestResult = null;
                });
              },
            ),
            fluent.FilledButton(
              child: const Text('添加'),
              onPressed: () async {
                if (nameController.text.isEmpty || urlController.text.isEmpty) {
                  return;
                }
                await manager.addCloudSource(
                  name: nameController.text,
                  baseUrl: urlController.text,
                  provider: selectedProvider,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                setState(() {
                  _connectionTestResult = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSource(MusicSource source, MusicSourceManager manager) {
    fluent.showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除音乐源 "${source.name}" 吗？'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          fluent.FilledButton(
            child: const Text('删除'),
            onPressed: () {
              manager.removeSource(source.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
