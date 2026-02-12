import 'dart:math';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show BackdropFilter, Image;
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/audio/audio_controller.dart';

class BlurredCover extends ConsumerStatefulWidget {
  final String coverUrl;
  final String? dominantColor;
  final int year;

  const BlurredCover({
    super.key,
    required this.coverUrl,
    this.dominantColor,
    required this.year,
  });

  @override
  ConsumerState<BlurredCover> createState() => _BlurredCoverState();
}

class _BlurredCoverState extends ConsumerState<BlurredCover>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 初始化粒子
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.5 + 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioControllerProvider);
    final progress = playerState.progress;

    // 根据进度计算模糊度
    final blurSigma = _calculateBlurSigma(progress);
    final unlockStage = _getUnlockStage(progress);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverImage(),

                if (blurSigma > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      color: _parseColor(widget.dominantColor)
                              ?.withOpacity(0.3) ??
                          AppTheme.warmBrown.withOpacity(0.3),
                    ),
                  ),

                // 动态粒子效果
                if (unlockStage != UnlockStage.revealed)
                  CustomPaint(
                    size: const Size(400, 400),
                    painter: ParticlePainter(
                      particles: _particles,
                      animation: _particleController.value,
                      progress: progress,
                    ),
                  ),

                // 阶段信息覆盖层
                if (unlockStage != UnlockStage.revealed)
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                // 年份显示
                if (unlockStage == UnlockStage.mystery)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.year}',
                          style: FluentTheme.of(context)
                              .typography
                              .title
                              ?.copyWith(
                                color: AppTheme.warmCream,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.vintageGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.vintageGold.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            '盲盒旋律',
                            style: TextStyle(
                              color: AppTheme.vintageGold,
                              fontSize: 14,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 解锁成功动画
                if (unlockStage == UnlockStage.revealed)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.vintageGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            FluentIcons.check_mark,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '重逢成功',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateBlurSigma(double progress) {
    if (progress < 0.5) {
      // 阶段一：全模糊 (sigma = 30)
      return 30.0;
    } else if (progress < 0.9) {
      // 阶段二：模糊度线性降低 (30 -> 5)
      final t = (progress - 0.5) / 0.4;
      return 30.0 - (t * 25.0);
    } else if (progress < 0.95) {
      // 阶段三：轻微模糊
      return 5.0 - ((progress - 0.9) / 0.05 * 5.0);
    } else {
      // 完全清晰
      return 0.0;
    }
  }

  UnlockStage _getUnlockStage(double progress) {
    if (progress < 0.5) {
      return UnlockStage.mystery;
    } else if (progress < 0.95) {
      return UnlockStage.emerging;
    } else {
      return UnlockStage.revealed;
    }
  }

  Color? _parseColor(String? hexColor) {
    if (hexColor == null) return null;
    try {
      return Color(
        int.parse(hexColor.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildCoverImage() {
    final coverUrl = widget.coverUrl;
    final fallbackColor = _parseColor(widget.dominantColor) ?? AppTheme.warmBrown;

    Widget errorWidget = Container(
      color: fallbackColor,
      child: Center(
        child: Icon(
          FluentIcons.music_note,
          size: 80,
          color: AppTheme.warmBeige.withOpacity(0.3),
        ),
      ),
    );

    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: fallbackColor,
            child: Center(
              child: ProgressRing(
                activeColor: AppTheme.vintageGold,
              ),
            ),
          );
        },
      );
    } else if (coverUrl.startsWith('assets/')) {
      return Image.asset(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      return Image.file(
        File(coverUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    }
  }
}

enum UnlockStage {
  mystery, // 全模糊
  emerging, // 逐渐清晰
  revealed, // 完全清晰
}

// 粒子数据类
class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// 粒子绘制器
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.vintageGold.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      // 根据进度调整粒子可见度
      final visibility = 1.0 - progress;
      if (visibility <= 0) continue;

      // 计算粒子位置（随动画漂移）
      final driftX = sin(animation * 2 * 3.14159 + particle.x * 10) * 10;
      final driftY = cos(animation * 2 * 3.14159 + particle.y * 10) * 10;

      final px = particle.x * size.width + driftX;
      final py = (particle.y * size.height + animation * particle.speed * 50) %
              size.height +
          driftY;

      // 绘制粒子
      paint.color = AppTheme.vintageGold.withOpacity(
        particle.opacity * visibility * 0.6,
      );

      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
