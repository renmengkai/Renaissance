import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'player_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _vinylController;
  bool _showContent = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 启动动画序列
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // 等待一小段时间后开始动画
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _showContent = true);
    }

    // 开始唱片旋转
    _vinylController.repeat();

    // 等待后显示按钮
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showButton = true);
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
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
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 黑胶唱片动画
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
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 唱片纹路
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _VinylGroovesPainter(),
                        ),

                        // 标签
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.vintageGold.withOpacity(0.3),
                                AppTheme.vintageGold.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              FluentIcons.music_note,
                              size: 28,
                              color: AppTheme.vintageGold.withOpacity(0.8),
                            ),
                          ),
                        ),

                        // 中心孔
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

              // 标题
              if (_showContent)
                Column(
                  children: [
                    Text(
                      '文艺复兴',
                      style: FluentTheme.of(context).typography.title?.copyWith(
                        color: AppTheme.warmCream,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 16,
                        shadows: [
                          Shadow(
                            color: AppTheme.vintageGold.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
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

                    // 分隔线
                    Container(
                      width: 60,
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.vintageGold.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 400.ms)
                        .scaleX(begin: 0, end: 1, duration: 400.ms),

                    // 特性标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeatureTag(
                          icon: FluentIcons.equalizer,
                          label: 'Lo-Fi 氛围',
                          delay: 1000.ms,
                        ),
                        const SizedBox(width: 24),
                        _FeatureTag(
                          icon: FluentIcons.hide,
                          label: '盲盒旋律',
                          delay: 1100.ms,
                        ),
                        const SizedBox(width: 24),
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

              // 进入按钮
              if (_showButton)
                GestureDetector(
                  onTap: _enterApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
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
                          color: AppTheme.vintageGold.withOpacity(0.4),
                          blurRadius: 20,
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
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '开启旅程',
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
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

              // 底部提示
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
      ),
    );
  }
}

// 特性标签
class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Duration delay;

  const _FeatureTag({
    required this.icon,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.vintageGold.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.warmBeige.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideX(begin: -0.2, end: 0, duration: 400.ms);
  }
}

// 唱片纹路绘制器
class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 5;

    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 绘制同心圆纹路
    for (double r = maxRadius; r > 40; r -= 3) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // 添加光泽效果
    final shinePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
