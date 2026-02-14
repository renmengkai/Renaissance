import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart' hide showDialog;
import 'package:flutter/material.dart' hide Colors, Slider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/vintage_settings.dart';
import '../models/music_source.dart';
import '../services/music_source_manager.dart';
import '../services/local_music_service.dart';
import '../services/webdav_music_service.dart';

class MusicSourceSettings extends ConsumerStatefulWidget {
  const MusicSourceSettings({super.key});

  @override
  ConsumerState<MusicSourceSettings> createState() => _MusicSourceSettingsState();
}

class _MusicSourceSettingsState extends ConsumerState<MusicSourceSettings> {
  bool _isTestingConnection = false;
  bool? _connectionTestResult;
  String _connectionErrorMessage = '';

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
                text: '添加WebDAV',
                onPressed: () => _showAddWebDAVDialog(context, manager),
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
            fluent.IconButton(
              icon: Icon(
                FluentIcons.edit,
                color: AppTheme.warmBeige.withOpacity(0.6),
                size: 16,
              ),
              onPressed: () => _showEditCloudDialog(context, manager, source),
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
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
      case MusicSourceType.webdav:
        return const Color(0xFF4A90D9);
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
      case MusicSourceType.webdav:
        return FluentIcons.cloud;
      case MusicSourceType.cloud:
        return FluentIcons.cloud_upload;
    }
  }

  String _getSourceTypeLabel(MusicSource source) {
    switch (source.type) {
      case MusicSourceType.local:
        return '本地';
      case MusicSourceType.webdav:
        return 'WebDAV';
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
      case MusicSourceType.webdav:
        return source.baseUrl ?? 'WebDAV';
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

  void _showAddWebDAVDialog(BuildContext context, MusicSourceManager manager) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final pathController = TextEditingController(text: '/');

    _connectionTestResult = null;
    _connectionErrorMessage = '';
    _isTestingConnection = false;

    fluent.showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ContentDialog(
          title: Row(
            children: [
              Icon(FluentIcons.cloud_add, color: AppTheme.vintageGold, size: 20),
              const SizedBox(width: 12),
              const Text('添加WebDAV'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildInputField('名称', nameController, '例如：我的阿里云盘'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      'WebDAV URL',
                      urlController,
                      'https://dav.aliyundrive.com',
                      onChanged: (value) {
                        if (nameController.text.isEmpty && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri != null) {
                            if (uri.host.contains('aliyundrive')) {
                              nameController.text = '阿里云盘';
                            } else if (uri.host.contains('teambition')) {
                              nameController.text = 'Teambition';
                            } else if (uri.host.contains('terabox')) {
                              nameController.text = '天翼云盘';
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInputField('用户名', usernameController, '您的用户名或邮箱'),
                    const SizedBox(height: 12),
                    _buildInputField('密码', passwordController, '您的密码或授权码', obscureText: true),
                    const SizedBox(height: 12),
                    _buildInputField('音乐目录', pathController, '音乐文件所在目录'),
                    const SizedBox(height: 16),
                    if (_connectionTestResult != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_connectionTestResult! ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _connectionTestResult! ? FluentIcons.check_mark : FluentIcons.error,
                              color: _connectionTestResult! ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionErrorMessage,
                                style: TextStyle(
                                  color: _connectionTestResult! ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        VintageButton(
                          text: '测试连接',
                          onPressed: _isTestingConnection
                              ? null
                              : () async {
                                  setState(() {
                                    _isTestingConnection = true;
                                    _connectionTestResult = null;
                                  });

                                  final result = await WebDAVMusicService.testConnection2(
                                    urlController.text,
                                    usernameController.text,
                                    passwordController.text,
                                  );

                                  setState(() {
                                    _connectionTestResult = result.success;
                                    _connectionErrorMessage = result.message;
                                    _isTestingConnection = false;
                                  });
                                },
                        ),
                        const SizedBox(width: 12),
                        VintageButton(
                          text: '取消',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        const SizedBox(width: 8),
                        VintageButton(
                          text: '添加',
                          isFilled: true,
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              setState(() {
                                _connectionTestResult = false;
                                _connectionErrorMessage = '请输入名称';
                              });
                              return;
                            }
                            if (urlController.text.isEmpty) {
                              setState(() {
                                _connectionTestResult = false;
                                _connectionErrorMessage = '请输入WebDAV URL';
                              });
                              return;
                            }

                            final source = MusicSource(
                              id: 'webdav_${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text,
                              type: MusicSourceType.webdav,
                              isEnabled: true,
                              baseUrl: urlController.text,
                              accessKey: usernameController.text,
                              secretKey: passwordController.text,
                              webdavPath: pathController.text.isEmpty ? '/' : pathController.text,
                            );

                            await manager.addSource(source);
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCloudDialog(BuildContext context, MusicSourceManager manager) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final customDomainController = TextEditingController();
    final bucketController = TextEditingController();
    final regionController = TextEditingController();
    final accessKeyController = TextEditingController();
    final secretKeyController = TextEditingController();
    CloudProvider selectedProvider = CloudProvider.qiniu;

    _connectionTestResult = null;
    _connectionErrorMessage = '';
    _isTestingConnection = false;

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
            width: 480,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildInputField('名称', nameController, '例如：我的七牛云音乐'),
                    const SizedBox(height: 12),
                    Text(
                      '云服务商',
                      style: TextStyle(
                        color: AppTheme.warmBeige,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: Container(
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
                                final exampleUrl = CloudProviderHelper.getExampleUrl(provider);
                                urlController.text = exampleUrl;
                                final result = CloudProviderHelper.parseBucketAndRegionFromUrl(exampleUrl);
                                bucketController.text = result.bucket ?? CloudProviderHelper.getExampleBucket(provider);
                                regionController.text = result.region ?? CloudProviderHelper.getExampleRegion(provider);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      'S3 端点',
                      urlController,
                      'https://bucket.s3.region.qiniucs.com',
                      onChanged: (value) {
                        final result = CloudProviderHelper.parseBucketAndRegionFromUrl(value);
                        if (result.bucket != null && bucketController.text.isEmpty) {
                          bucketController.text = result.bucket!;
                        }
                        if (result.region != null && regionController.text.isEmpty) {
                          regionController.text = result.region!;
                        }
                        if (result.bucket != null && nameController.text.isEmpty) {
                          nameController.text = result.bucket!;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      '自定义域名',
                      customDomainController,
                      'https://music.example.com',
                      onChanged: (value) {
                        if (value.isNotEmpty && !value.startsWith('http')) {
                          customDomainController.text = 'https://$value';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField('存储桶', bucketController, '自动解析或手动填写')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField('区域', regionController, '自动解析或手动填写')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInputField('AccessKey', accessKeyController, '在云服务商控制台获取'),
                    const SizedBox(height: 12),
                    _buildInputField('SecretKey', secretKeyController, '在云服务商控制台获取', obscureText: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '提示：${CloudProviderHelper.getAuthGuide(selectedProvider)}',
                            style: TextStyle(
                              color: AppTheme.warmBeige.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (CloudProviderHelper.getOfficialWebsite(selectedProvider).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final url = CloudProviderHelper.getOfficialWebsite(selectedProvider);
                              if (url.isNotEmpty) {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  print('Could not launch $url');
                                }
                              }
                            },
                            child: Text(
                              '官方网站',
                              style: TextStyle(
                                color: AppTheme.vintageGold,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_connectionTestResult != null)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (_connectionTestResult! ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_connectionTestResult! ? Colors.green : Colors.red).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _connectionTestResult! ? FluentIcons.check_mark : FluentIcons.cancel,
                                  color: _connectionTestResult! ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _connectionTestResult! ? '连接成功' : '连接失败',
                                        style: TextStyle(
                                          color: _connectionTestResult! ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!_connectionTestResult! && _connectionErrorMessage.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _connectionErrorMessage,
                                            style: TextStyle(
                                              color: Colors.red.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Button(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 90),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTestingConnection)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    else
                      const Icon(FluentIcons.plug_connected, size: 14),
                    const SizedBox(width: 4),
                    const Text('测试连接'),
                  ],
                ),
              ),
              onPressed: _isTestingConnection
                  ? null
                  : () async {
                      if (urlController.text.isEmpty ||
                          accessKeyController.text.isEmpty ||
                          secretKeyController.text.isEmpty ||
                          bucketController.text.isEmpty ||
                          regionController.text.isEmpty) {
                        setState(() {
                          _connectionTestResult = false;
                          _connectionErrorMessage = '请填写所有必填字段';
                        });
                        return;
                      }
                      setState(() {
                        _isTestingConnection = true;
                        _connectionTestResult = null;
                        _connectionErrorMessage = '';
                      });
                      final result = await manager.testCloudConnection(
                        urlController.text,
                        accessKey: accessKeyController.text,
                        secretKey: secretKeyController.text,
                        bucketName: bucketController.text,
                        region: regionController.text,
                      );
                      setState(() {
                        _isTestingConnection = false;
                        _connectionTestResult = result.success;
                        _connectionErrorMessage = result.errorMessage ?? '测试完成';
                      });
                    },
            ),
            Button(
              child: const Text('取消'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            fluent.FilledButton(
              child: const Text('添加'),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写名称';
                  });
                  return;
                }
                if (urlController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 S3 端点';
                  });
                  return;
                }
                if (bucketController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写存储桶';
                  });
                  return;
                }
                if (regionController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写区域';
                  });
                  return;
                }
                if (accessKeyController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 AccessKey';
                  });
                  return;
                }
                if (secretKeyController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 SecretKey';
                  });
                  return;
                }
                await manager.addCloudSource(
                  name: nameController.text,
                  baseUrl: urlController.text,
                  customDomain: customDomainController.text,
                  provider: selectedProvider,
                  bucketName: bucketController.text,
                  accessKey: accessKeyController.text,
                  secretKey: secretKeyController.text,
                  region: regionController.text,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String placeholder, {bool obscureText = false, void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.warmBeige,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextBox(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          style: TextStyle(color: AppTheme.warmCream),
          placeholderStyle: TextStyle(
            color: AppTheme.warmBeige.withOpacity(0.4),
            fontSize: 12,
          ),
          onChanged: onChanged,
        ),
      ],
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

  void _showEditCloudDialog(BuildContext context, MusicSourceManager manager, MusicSource source) {
    final nameController = TextEditingController(text: source.name);
    final urlController = TextEditingController(text: source.baseUrl);
    final customDomainController = TextEditingController(text: source.customDomain);
    final bucketController = TextEditingController(text: source.bucketName);
    final regionController = TextEditingController(text: source.region);
    final accessKeyController = TextEditingController(text: source.accessKey);
    final secretKeyController = TextEditingController(text: source.secretKey);
    final selectedProvider = source.cloudProvider ?? CloudProvider.qiniu;

    _connectionTestResult = null;
    _connectionErrorMessage = '';
    _isTestingConnection = false;

    fluent.showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ContentDialog(
          title: Row(
            children: [
              Icon(FluentIcons.edit, color: AppTheme.vintageGold, size: 20),
              const SizedBox(width: 12),
              const Text('编辑云存储'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildInputField('名称', nameController, '例如：我的七牛云音乐'),
                    const SizedBox(height: 12),
                    Text(
                      '云服务商',
                      style: TextStyle(
                        color: AppTheme.warmBeige,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: Container(
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
                                final exampleUrl = CloudProviderHelper.getExampleUrl(provider);
                                urlController.text = exampleUrl;
                                final result = CloudProviderHelper.parseBucketAndRegionFromUrl(exampleUrl);
                                bucketController.text = result.bucket ?? CloudProviderHelper.getExampleBucket(provider);
                                regionController.text = result.region ?? CloudProviderHelper.getExampleRegion(provider);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      'S3 端点',
                      urlController,
                      'https://bucket.s3.region.qiniucs.com',
                      onChanged: (value) {
                        final result = CloudProviderHelper.parseBucketAndRegionFromUrl(value);
                        if (result.bucket != null && bucketController.text.isEmpty) {
                          bucketController.text = result.bucket!;
                        }
                        if (result.region != null && regionController.text.isEmpty) {
                          regionController.text = result.region!;
                        }
                        if (result.bucket != null && nameController.text.isEmpty) {
                          nameController.text = result.bucket!;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      '自定义域名',
                      customDomainController,
                      'https://music.example.com',
                      onChanged: (value) {
                        if (value.isNotEmpty && !value.startsWith('http')) {
                          customDomainController.text = 'https://$value';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInputField('存储桶', bucketController, '自动解析或手动填写')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField('区域', regionController, '自动解析或手动填写')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInputField('AccessKey', accessKeyController, '在云服务商控制台获取'),
                    const SizedBox(height: 12),
                    _buildInputField('SecretKey', secretKeyController, '在云服务商控制台获取', obscureText: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '提示：${CloudProviderHelper.getAuthGuide(selectedProvider)}',
                            style: TextStyle(
                              color: AppTheme.warmBeige.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (CloudProviderHelper.getOfficialWebsite(selectedProvider).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final url = CloudProviderHelper.getOfficialWebsite(selectedProvider);
                              if (url.isNotEmpty) {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  print('Could not launch $url');
                                }
                              }
                            },
                            child: Text(
                              '官方网站',
                              style: TextStyle(
                                color: AppTheme.vintageGold,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_connectionTestResult != null)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (_connectionTestResult! ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_connectionTestResult! ? Colors.green : Colors.red).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _connectionTestResult! ? FluentIcons.check_mark : FluentIcons.cancel,
                                  color: _connectionTestResult! ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _connectionTestResult! ? '连接成功' : '连接失败',
                                        style: TextStyle(
                                          color: _connectionTestResult! ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!_connectionTestResult! && _connectionErrorMessage.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _connectionErrorMessage,
                                            style: TextStyle(
                                              color: Colors.red.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Button(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 90),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTestingConnection)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    else
                      const Icon(FluentIcons.plug_connected, size: 14),
                    const SizedBox(width: 4),
                    const Text('测试连接'),
                  ],
                ),
              ),
              onPressed: _isTestingConnection
                  ? null
                  : () async {
                      if (urlController.text.isEmpty ||
                          accessKeyController.text.isEmpty ||
                          secretKeyController.text.isEmpty ||
                          bucketController.text.isEmpty ||
                          regionController.text.isEmpty) {
                        setState(() {
                          _connectionTestResult = false;
                          _connectionErrorMessage = '请填写所有必填字段';
                        });
                        return;
                      }
                      setState(() {
                        _isTestingConnection = true;
                        _connectionTestResult = null;
                        _connectionErrorMessage = '';
                      });
                      final result = await manager.testCloudConnection(
                        urlController.text,
                        accessKey: accessKeyController.text,
                        secretKey: secretKeyController.text,
                        bucketName: bucketController.text,
                        region: regionController.text,
                      );
                      setState(() {
                        _isTestingConnection = false;
                        _connectionTestResult = result.success;
                        _connectionErrorMessage = result.errorMessage ?? '测试完成';
                      });
                    },
            ),
            Button(
              child: const Text('取消'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            fluent.FilledButton(
              child: const Text('保存'),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写名称';
                  });
                  return;
                }
                if (urlController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 S3 端点';
                  });
                  return;
                }
                if (bucketController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写存储桶';
                  });
                  return;
                }
                if (regionController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写区域';
                  });
                  return;
                }
                if (accessKeyController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 AccessKey';
                  });
                  return;
                }
                if (secretKeyController.text.isEmpty) {
                  setState(() {
                    _connectionTestResult = false;
                    _connectionErrorMessage = '请填写 SecretKey';
                  });
                  return;
                }
                final updatedSource = source.copyWith(
                  name: nameController.text,
                  baseUrl: urlController.text,
                  customDomain: customDomainController.text,
                  bucketName: bucketController.text,
                  accessKey: accessKeyController.text,
                  secretKey: secretKeyController.text,
                  region: regionController.text,
                );
                await manager.updateSource(updatedSource);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
