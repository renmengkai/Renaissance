import 'dart:math';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class VinylCover extends StatefulWidget {
  final String? coverPath;
  final String? dominantColor;
  final bool isPlaying;
  final double size;

  const VinylCover({
    super.key,
    this.coverPath,
    this.dominantColor,
    this.isPlaying = false,
    this.size = 320,
  });

  @override
  State<VinylCover> createState() => _VinylCoverState();
}

class _VinylCoverState extends State<VinylCover>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _floatController.repeat(reverse: true);

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return AppTheme.warmBrown;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.warmBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dominantColor = _parseColor(widget.dominantColor);

    return Semantics(
      container: false,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * 0.3),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedScale(
                scale: _isHovered ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildGlowEffect(dominantColor),
                    _buildVinylRecord(dominantColor),
                    _buildCoverImage(dominantColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowEffect(Color dominantColor) {
    return Container(
      width: widget.size + 80,
      height: widget.size + 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: dominantColor.withOpacity(_isHovered ? 0.4 : 0.2),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: AppTheme.vintageGold.withOpacity(0.1),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    ).animate(target: widget.isPlaying ? 1 : 0).shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.05),
        );
  }

  Widget _buildVinylRecord(Color dominantColor) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: widget.size + 40,
        height: widget.size + 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0d0d0d),
              Color(0xFF1a1a1a),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size + 40, widget.size + 40),
              painter: _VinylGroovePainter(),
            ),
            CustomPaint(
              size: Size(widget.size + 40, widget.size + 40),
              painter: _VinylShinePainter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(Color dominantColor) {
    final coverSize = widget.size * 0.65;

    return Container(
      width: coverSize,
      height: coverSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            dominantColor.withOpacity(0.8),
            dominantColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(coverSize, dominantColor),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.vintageGold.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.softBlack,
                  border: Border.all(
                    color: AppTheme.vintageGold.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double size, Color fallbackColor) {
    if (widget.coverPath == null || widget.coverPath!.isEmpty) {
      return Container(
        color: fallbackColor,
        child: Center(
          child: Icon(
            FluentIcons.music_note,
            size: size * 0.3,
            color: AppTheme.warmBeige.withOpacity(0.3),
          ),
        ),
      );
    }

    final coverUrl = widget.coverPath!;

    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(fallbackColor),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: fallbackColor,
            child: Center(
              child: ProgressRing(
                activeColor: AppTheme.vintageGold,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    } else if (coverUrl.startsWith('assets/')) {
      return Image.asset(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(fallbackColor),
      );
    } else {
      return Image.file(
        File(coverUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(fallbackColor),
      );
    }
  }

  Widget _buildFallback(Color color) {
    return Container(
      color: color,
      child: Center(
        child: Icon(
          FluentIcons.music_note,
          size: 60,
          color: AppTheme.warmBeige.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _VinylGroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double r = maxRadius; r > 50; r -= 2) {
      canvas.drawCircle(center, r, groovePaint);
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final r = maxRadius - i * 30;
      if (r > 50) {
        canvas.drawCircle(center, r, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VinylShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, shinePaint);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DynamicBackground extends StatelessWidget {
  final String? dominantColor;
  final Widget child;

  const DynamicBackground({
    super.key,
    this.dominantColor,
    required this.child,
  });

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return AppTheme.warmBrown;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.warmBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(dominantColor);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 1.0),
                radius: 1.0,
                colors: [
                  AppTheme.vintageGold.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class FloatingParticles extends StatefulWidget {
  final Color? color;
  final int particleCount;

  const FloatingParticles({
    super.key,
    this.color,
    this.particleCount = 20,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(widget.particleCount, (_) => _Particle(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.vintageGold;

    return Semantics(
      container: false,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              animation: _controller.value,
              color: color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 3 + 1,
        speed = random.nextDouble() * 0.3 + 0.1,
        opacity = random.nextDouble() * 0.5 + 0.2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final y = (particle.y + animation * particle.speed) % 1.0;
      final x = particle.x + sin(animation * 2 * pi + particle.y * 10) * 0.02;

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * (1 - y))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
