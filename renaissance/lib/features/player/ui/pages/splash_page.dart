import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'player_page.dart';
import 'dart:math';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _vinylController;
  late AnimationController _particleController;
  bool _showContent = false;
  bool _showButton = false;

  final List<_FloatingNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 15; i++) {
      _notes.add(_FloatingNote(Random()));
    }

    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _showContent = true);
    }

    _vinylController.repeat();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showButton = true);
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _enterApp() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.softBlack,
            AppTheme.deepBrown.withOpacity(0.8),
            AppTheme.softBlack,
          ],
        ),
      ),
      child: ScaffoldPage(
        content: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                container: false,
                excludeSemantics: true,
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _FloatingNotesPainter(
                        notes: _notes,
                        animation: _particleController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showContent)
                    RotationTransition(
                      turns: _vinylController,
                      child: Container(
                        width: 200,
                        height: 200,
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
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: AppTheme.vintageGold.withOpacity(0.2),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: _VinylGroovesPainter(),
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.vintageGold.withOpacity(0.4),
                                    AppTheme.vintageGold.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  FluentIcons.music_note,
                                  size: 28,
                                  color: AppTheme.vintageGold.withOpacity(0.9),
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.softBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),

                  const SizedBox(height: 60),

                  if (_showContent)
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.warmCream,
                              AppTheme.vintageGold,
                              AppTheme.warmCream,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '文艺复兴',
                            style: GoogleFonts.zcoolXiaoWei(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 16,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0, duration: 600.ms),

                        const SizedBox(height: 16),

                        Text(
                          '让老歌的旋律重新焕发生命力',
                          style: FluentTheme.of(context).typography.body?.copyWith(
                            color: AppTheme.warmBeige.withOpacity(0.7),
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms),

                        const SizedBox(height: 8),

                        Container(
                          width: 80,
                          height: 2,
                          margin: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.vintageGold.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 400.ms)
                            .scaleX(begin: 0, end: 1, duration: 400.ms),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeatureTag(
                              icon: FluentIcons.equalizer,
                              label: 'Lo-Fi 氛围',
                              delay: 1000.ms,
                            ),
                            const SizedBox(width: 28),
                            _FeatureTag(
                              icon: FluentIcons.hide,
                              label: '盲盒旋律',
                              delay: 1100.ms,
                            ),
                            const SizedBox(width: 28),
                            _FeatureTag(
                              icon: FluentIcons.mail,
                              label: '黄金信件',
                              delay: 1200.ms,
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 80),

                  if (_showButton)
                    GestureDetector(
                      onTap: _enterApp,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 52,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.vintageGold,
                                Color(0xFFB8941F),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.vintageGold.withOpacity(0.5),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                FluentIcons.play_solid,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                '开启旅程',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.15),
                        ),

                  if (_showButton)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        '点击按钮开始你的音乐之旅',
                        style: TextStyle(
                          color: AppTheme.warmBeige.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTag extends StatefulWidget {
  final IconData icon;
  final String label;
  final Duration delay;

  const _FeatureTag({
    required this.icon,
    required this.label,
    required this.delay,
  });

  @override
  State<_FeatureTag> createState() => _FeatureTagState();
}

class _FeatureTagState extends State<_FeatureTag> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.vintageGold.withOpacity(0.15)
              : AppTheme.warmBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? AppTheme.vintageGold.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _isHovered
                  ? AppTheme.vintageGold
                  : AppTheme.vintageGold.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: _isHovered
                    ? AppTheme.warmCream
                    : AppTheme.warmBeige.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 400.ms)
        .slideX(begin: -0.2, end: 0, duration: 400.ms);
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 5;

    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double r = maxRadius; r > 40; r -= 3) {
      canvas.drawCircle(center, r, groovePaint);
    }

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

class _FloatingNote {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double rotation;

  _FloatingNote(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 8 + 4,
        speed = random.nextDouble() * 0.3 + 0.1,
        opacity = random.nextDouble() * 0.3 + 0.1,
        rotation = random.nextDouble() * 2 * pi;
}

class _FloatingNotesPainter extends CustomPainter {
  final List<_FloatingNote> notes;
  final double animation;

  _FloatingNotesPainter({
    required this.notes,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var note in notes) {
      final y = (note.y + animation * note.speed) % 1.0;
      final x = note.x + sin(animation * 2 * pi + note.y * 10) * 0.02;
      final opacity = note.opacity * (1 - y * 0.5);

      final paint = Paint()
        ..color = AppTheme.vintageGold.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final notePath = _createNotePath(note.size);
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(note.rotation + animation * pi);
      canvas.drawPath(notePath, paint);
      canvas.restore();
    }
  }

  Path _createNotePath(double size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size * 0.1, -size * 0.8);
    path.quadraticBezierTo(
      size * 0.5, -size * 0.9,
      size * 0.5, -size * 0.6,
    );
    path.quadraticBezierTo(
      size * 0.5, -size * 0.3,
      size * 0.2, -size * 0.3,
    );
    path.quadraticBezierTo(
      0, -size * 0.3,
      0, -size * 0.5,
    );
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
