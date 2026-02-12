import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Scrollbar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/noise_texture.dart';
import '../repository/letter_repository.dart';

class WriteLetterDialog extends ConsumerStatefulWidget {
  final String songId;
  final String songTitle;

  const WriteLetterDialog({
    super.key,
    required this.songId,
    required this.songTitle,
  });

  @override
  ConsumerState<WriteLetterDialog> createState() => _WriteLetterDialogState();
}

class _WriteLetterDialogState extends ConsumerState<WriteLetterDialog> {
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  String? _selectedMood;
  bool _isSubmitting = false;

  final List<String> _moods = [
    '怀念',
    '温暖',
    '感动',
    '遗憾',
    '希望',
    '诗意',
    '治愈',
    '感伤',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _submitLetter() async {
    if (_contentController.text.trim().isEmpty) {
      _showError('请写下你的感悟');
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      _showError('请留下你的名字');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(letterControllerProvider.notifier).writeLetter(
            widget.songId,
            _contentController.text.trim(),
            _authorController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showError('提交失败，请重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          Button(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Row(
          children: [
            Icon(
              FluentIcons.check_mark,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('提交成功'),
          ],
        ),
        content: const Text(
          '你的信件已封装进黑胶唱片，\n等待下一个有缘人听完这首歌。',
        ),
        actions: [
          FilledButton(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      content: Container(
        width: 600,
        height: 700,
        child: PaperTexture(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.edit_mail,
                          color: AppTheme.vintageGold,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '写一封信',
                          style: FluentTheme.of(context)
                              .typography
                              .subtitle
                              ?.copyWith(
                                color: AppTheme.deepBrown,
                                fontSize: 20,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        FluentIcons.chrome_close,
                        color: AppTheme.warmBrown.withOpacity(0.6),
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 歌曲信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.vintageGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.vintageGold.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.music_note,
                        size: 16,
                        color: AppTheme.vintageGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '致《${widget.songTitle}》',
                        style: TextStyle(
                          color: AppTheme.warmBrown,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 心情选择
                Text(
                  '选择心情',
                  style: TextStyle(
                    color: AppTheme.deepBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedMood = mood);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.vintageGold.withOpacity(0.2)
                              : AppTheme.warmBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.vintageGold
                                : AppTheme.warmBrown.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          mood,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.vintageGold
                                : AppTheme.warmBrown,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 信件内容
                Text(
                  '写下你的感悟',
                  style: TextStyle(
                    color: AppTheme.deepBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warmBrown.withOpacity(0.2),
                      ),
                    ),
                    child: TextBox(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      placeholder: '这首歌让你想起了什么？\n写下你的故事，等待下一个有缘人...',
                       style: const TextStyle(
                         color: AppTheme.deepBrown,
                         fontSize: 14,
                         height: 1.8,
                       ),
                      decoration: const WidgetStatePropertyAll(
                        BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 署名
                Row(
                  children: [
                    Text(
                      '署名：',
                      style: TextStyle(
                        color: AppTheme.deepBrown,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        width: 200,
                        child: TextBox(
                          controller: _authorController,
                          placeholder: '你的名字或昵称',
                          style: const TextStyle(
                            color: AppTheme.deepBrown,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Button(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitLetter,
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(AppTheme.vintageGold),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: ProgressRing(
                                activeColor: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '封装进黑胶',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
