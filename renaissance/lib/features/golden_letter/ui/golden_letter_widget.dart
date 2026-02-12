import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Transform, Matrix4;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/letter.dart';
import '../repository/letter_repository.dart';

class GoldenLetterWidget extends ConsumerStatefulWidget {
  const GoldenLetterWidget({super.key});

  @override
  ConsumerState<GoldenLetterWidget> createState() => _GoldenLetterWidgetState();
}

class _GoldenLetterWidgetState extends ConsumerState<GoldenLetterWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final letterState = ref.watch(letterControllerProvider);

    if (letterState.isLoading) {
      return _buildLoadingState();
    }

    if (letterState.letter == null) {
      return const SizedBox.shrink();
    }

    final letter = letterState.letter!;

    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        final angle = _flipController.value * 3.14159;
        final isFront = angle < 3.14159 / 2;

        return GestureDetector(
          onTap: _flipCard,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildEnvelopeFront(letter)
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: _buildLetterContent(letter),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.vintageGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.vintageGold.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: ProgressRing(
          activeColor: AppTheme.vintageGold,
        ),
      ),
    );
  }

  Widget _buildEnvelopeFront(GoldenLetter letter) {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD4AF37),
            const Color(0xFFB8941F),
            const Color(0xFFD4AF37),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vintageGold.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 信封纹理
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),

          // 火漆印
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B0000),
                border: Border.all(
                  color: const Color(0xFFA52A2A),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  FluentIcons.heart,
                  color: Color(0x70FFFFFF),
                  size: 28,
                ),
              ),
            ),
          ),

          // 提示文字
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Text(
              '点击开启',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildLetterContent(GoldenLetter letter) {
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 纸张纹理
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warmBrown.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),

          // 内容
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.vintageGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        letter.mood ?? '心情',
                        style: const TextStyle(
                          color: AppTheme.deepBrown,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy.MM.dd').format(letter.createdAt),
                      style: TextStyle(
                        color: AppTheme.warmBrown.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 信件内容
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      letter.content,
                      style: const TextStyle(
                        color: AppTheme.deepBrown,
                        fontSize: 14,
                        height: 1.8,
                        fontFamily: 'NotoSerifSC',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 署名
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '—— ${letter.authorName}',
                        style: const TextStyle(
                          color: AppTheme.warmBrown,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (letter.location != null)
                        Text(
                          '于 ${letter.location}',
                          style: TextStyle(
                            color: AppTheme.warmBrown.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 关闭按钮
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(
                FluentIcons.chrome_close,
                size: 16,
                color: AppTheme.warmBrown,
              ),
              onPressed: () {
                _flipCard();
                ref.read(letterControllerProvider.notifier).closeLetter();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 信件通知徽章
class LetterBadge extends StatelessWidget {
  final VoidCallback onTap;

  const LetterBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD4AF37),
              Color(0xFFB8941F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vintageGold.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          FluentIcons.mail,
          color: Colors.white,
          size: 24,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 1.seconds,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1, 1),
          duration: 1.seconds,
          curve: Curves.easeInOut,
        );
  }
}
