import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// 音频可视化组件
class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;

  const AudioVisualizer({
    super.key,
    this.isPlaying = false,
    this.barCount = 20,
    this.height = 60,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(400)),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.value = 0.2;
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.vintageGold;

    return Container(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 4,
                height: widget.height * _animations[index].value,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// 圆形音频可视化
class CircularVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color? color;

  const CircularVisualizer({
    super.key,
    this.isPlaying = false,
    this.size = 200,
    this.color,
  });

  @override
  State<CircularVisualizer> createState() => _CircularVisualizerState();
}

class _CircularVisualizerState extends State<CircularVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _amplitudes = List.filled(60, 0.3);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _amplitudes.length; i++) {
            if (widget.isPlaying) {
              _amplitudes[i] = 0.3 + _random.nextDouble() * 0.7;
            } else {
              _amplitudes[i] = 0.3;
            }
          }
        });
      }
    });
    _controller.repeat();
  }

  @override
  void didUpdateWidget(CircularVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.vintageGold;

    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _CircularVisualizerPainter(
        amplitudes: _amplitudes,
        color: color,
      ),
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _CircularVisualizerPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final angle = (i / amplitudes.length) * 2 * 3.14159;
      final radius = baseRadius * amplitudes[i];

      final startX = center.dx + cos(angle) * baseRadius * 0.8;
      final startY = center.dy + sin(angle) * baseRadius * 0.8;
      final endX = center.dx + cos(angle) * radius;
      final endY = center.dy + sin(angle) * radius;

      // 渐变透明度
      final opacity = 0.3 + (amplitudes[i] - 0.3) * 0.7;
      paint.color = color.withOpacity(opacity);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // 绘制中心圆
    final centerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius * 0.7, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 波形可视化
class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double width;
  final double height;
  final Color? color;

  const WaveformVisualizer({
    super.key,
    this.isPlaying = false,
    this.width = 300,
    this.height = 60,
    this.color,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _points = List.filled(100, 0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.addListener(() {
      if (mounted && widget.isPlaying) {
        setState(() {
          // 移位并添加新点
          for (int i = 0; i < _points.length - 1; i++) {
            _points[i] = _points[i + 1];
          }
          _points[_points.length - 1] = _random.nextDouble() * 0.8 + 0.2;
        });
      }
    });
    _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.vintageGold;

    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: _WaveformPainter(
        points: _points,
        color: color,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _WaveformPainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final centerY = size.height / 2;
    final stepX = size.width / (points.length - 1);

    path.moveTo(0, centerY);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = centerY - (points[i] - 0.5) * size.height * 0.8;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 绘制填充
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
