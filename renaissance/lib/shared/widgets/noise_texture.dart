import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// 噪声纹理叠加层
class NoiseOverlay extends StatelessWidget {
  final double intensity;
  final Widget child;

  const NoiseOverlay({
    super.key,
    this.intensity = 0.05,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(intensity: intensity),
            ),
          ),
        ),
      ],
    );
  }
}

// 噪声绘制器
class _NoisePainter extends CustomPainter {
  final double intensity;
  final Random _random = Random();

  _NoisePainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(intensity)
      ..style = PaintingStyle.fill;

    // 生成噪声点
    final noiseCount = (size.width * size.height * 0.1).toInt();

    for (int i = 0; i < noiseCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 颗粒感背景
class GrainyBackground extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final double grainIntensity;

  const GrainyBackground({
    super.key,
    required this.child,
    this.baseColor,
    this.grainIntensity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 基础背景色
        Container(
          color: baseColor ?? AppTheme.softBlack,
        ),

        // 颗粒纹理
        CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(intensity: grainIntensity),
        ),

        // 内容
        child,
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  final double intensity;

  _GrainPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // 固定种子以获得一致的纹理

    // 绘制细小的颗粒
    for (int i = 0; i < size.width * size.height * 0.5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // 随机选择亮色或暗色颗粒
      final isLight = random.nextBool();
      final opacity = random.nextDouble() * intensity;

      final paint = Paint()
        ..color = isLight
            ? Colors.white.withOpacity(opacity)
            : Colors.black.withOpacity(opacity)
        ..strokeWidth = 1;

      canvas.drawPoints(
        PointMode.points,
        [Offset(x, y)],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 复古纸张纹理
class PaperTexture extends StatelessWidget {
  final Widget child;
  final Color paperColor;

  const PaperTexture({
    super.key,
    required this.child,
    this.paperColor = const Color(0xFFFDF6E3),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 纸张底色
        Container(
          decoration: BoxDecoration(
            color: paperColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // 纸张纹理
        CustomPaint(
          size: Size.infinite,
          painter: _PaperTexturePainter(),
        ),

        // 边缘磨损效果
        CustomPaint(
          size: Size.infinite,
          painter: _WornEdgePainter(),
        ),

        // 内容
        child,
      ],
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(123);

    // 绘制纤维纹理
    final fiberPaint = Paint()
      ..color = AppTheme.warmBrown.withOpacity(0.03)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 200; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final length = random.nextDouble() * 30 + 10;
      final angle = random.nextDouble() * 3.14159;

      final endX = startX + cos(angle) * length;
      final endY = startY + sin(angle) * length;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        fiberPaint,
      );
    }

    // 添加一些随机的深色斑点（模拟纸张瑕疵）
    final spotPaint = Paint()
      ..color = AppTheme.warmBrown.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      canvas.drawCircle(Offset(x, y), radius, spotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WornEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(456);

    // 绘制边缘磨损
    final edgePaint = Paint()
      ..color = AppTheme.warmBrown.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 上边缘
    for (int i = 0; i < size.width; i += 2) {
      if (random.nextDouble() < 0.1) {
        canvas.drawLine(
          Offset(i.toDouble(), 0),
          Offset(i.toDouble(), random.nextDouble() * 3),
          edgePaint,
        );
      }
    }

    // 下边缘
    for (int i = 0; i < size.width; i += 2) {
      if (random.nextDouble() < 0.1) {
        canvas.drawLine(
          Offset(i.toDouble(), size.height),
          Offset(i.toDouble(), size.height - random.nextDouble() * 3),
          edgePaint,
        );
      }
    }

    // 左边缘
    for (int i = 0; i < size.height; i += 2) {
      if (random.nextDouble() < 0.1) {
        canvas.drawLine(
          Offset(0, i.toDouble()),
          Offset(random.nextDouble() * 3, i.toDouble()),
          edgePaint,
        );
      }
    }

    // 右边缘
    for (int i = 0; i < size.height; i += 2) {
      if (random.nextDouble() < 0.1) {
        canvas.drawLine(
          Offset(size.width, i.toDouble()),
          Offset(size.width - random.nextDouble() * 3, i.toDouble()),
          edgePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 黑胶唱片纹理
class VinylTexture extends StatelessWidget {
  final double size;
  final Widget? child;

  const VinylTexture({
    super.key,
    required this.size,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF0a0a0a),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _VinylGroovesPainter(),
        child: child,
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 绘制唱片纹路
    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 从外向内绘制同心圆
    for (double r = maxRadius - 5; r > 40; r -= 2) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // 绘制标签区域
    final labelPaint = Paint()
      ..color = AppTheme.vintageGold.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 35, labelPaint);

    // 中心孔
    final holePaint = Paint()
      ..color = AppTheme.softBlack
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, holePaint);

    // 添加一些光泽效果
    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
