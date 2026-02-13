import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class VintageProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onSeek;
  final Color? activeColor;
  final bool showTimeLabels;

  const VintageProgressBar({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
    this.onSeek,
    this.activeColor,
    this.showTimeLabels = true,
  });

  @override
  State<VintageProgressBar> createState() => _VintageProgressBarState();
}

class _VintageProgressBarState extends State<VintageProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0;
  bool _isHovered = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.vintageGold;
    final displayProgress = _isDragging ? _dragValue : widget.progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() {
                _isDragging = true;
                _dragValue = widget.progress;
              });
              HapticFeedback.lightImpact();
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
              setState(() => _dragValue = newValue);
            },
            onHorizontalDragEnd: (details) {
              widget.onSeek?.call(_dragValue);
              setState(() => _isDragging = false);
              HapticFeedback.mediumImpact();
            },
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
              widget.onSeek?.call(newValue);
              HapticFeedback.lightImpact();
            },
            child: SizedBox(
              height: 24,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  height: _isHovered || _isDragging ? 24 : 16,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _VintageProgressPainter(
                      progress: displayProgress,
                      activeColor: activeColor,
                      isHovered: _isHovered || _isDragging,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showTimeLabels) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(widget.position),
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.7),
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    color: AppTheme.warmBeige.withOpacity(0.7),
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VintageProgressPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isHovered;
  final bool isDragging;

  _VintageProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.isHovered,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackHeight = isHovered ? 6.0 : 4.0;
    final thumbRadius = isHovered ? 8.0 : 6.0;
    final thumbX = progress * size.width;

    final trackPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.warmBrown.withOpacity(0.3),
          AppTheme.warmBrown.withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, trackHeight));

    final trackPath = Path();
    trackPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: size.width,
          height: trackHeight,
        ),
        Radius.circular(trackHeight / 2),
      ),
    );
    canvas.drawPath(trackPath, trackPaint);

    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      final tickPaint = Paint()
        ..color = AppTheme.warmBeige.withOpacity(i % 5 == 0 ? 0.3 : 0.15)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, centerY - trackHeight),
        Offset(x, centerY + trackHeight),
        tickPaint,
      );
    }

    if (progress > 0) {
      final activeTrackPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            activeColor.withOpacity(0.8),
            activeColor,
          ],
        ).createShader(Rect.fromLTWH(0, 0, thumbX, trackHeight));

      final activePath = Path();
      activePath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(thumbX / 2, centerY),
            width: thumbX,
            height: trackHeight,
          ),
          Radius.circular(trackHeight / 2),
        ),
      );
      canvas.drawPath(activePath, activeTrackPaint);

      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(thumbX, centerY), thumbRadius + 4, glowPaint);
    }

    final thumbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          activeColor,
          activeColor.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: Offset(thumbX, centerY), radius: thumbRadius));

    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius,
      thumbPaint,
    );

    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(thumbX - thumbRadius * 0.25, centerY - thumbRadius * 0.25),
      thumbRadius * 0.3,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const AnimatedPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 72,
  });

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: false,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed
                    ? 0.92
                    : _isHovered
                        ? 1.05 + _pulseController.value * 0.03
                        : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.vintageGold,
                        const Color(0xFFB8941F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.vintageGold.withOpacity(
                          _isHovered ? 0.6 : 0.4,
                        ),
                        blurRadius: 20 + _pulseController.value * 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildIcon(),
                      if (widget.isPlaying)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RipplePainter(_pulseController.value),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        widget.isPlaying ? FluentIcons.pause : FluentIcons.play_solid,
        key: ValueKey(widget.isPlaying),
        color: Colors.white,
        size: widget.size * 0.45,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;

  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * (0.8 + progress * 0.2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final String? tooltip;

  const AnimatedControlButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 28,
    this.color,
    this.tooltip,
  });

  @override
  State<AnimatedControlButton> createState() => _AnimatedControlButtonState();
}

class _AnimatedControlButtonState extends State<AnimatedControlButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.warmBeige;

    Widget button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(_isHovered ? 10 : 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.warmBrown.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Transform.scale(
            scale: _isPressed ? 0.9 : 1.0,
            child: Icon(
              widget.icon,
              color: _isHovered ? AppTheme.vintageGold : color,
              size: widget.size,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

class PlayModeButton extends StatefulWidget {
  final int mode;
  final VoidCallback onTap;

  const PlayModeButton({
    super.key,
    required this.mode,
    required this.onTap,
  });

  @override
  State<PlayModeButton> createState() => _PlayModeButtonState();
}

class _PlayModeButtonState extends State<PlayModeButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(PlayModeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (IconData, String, Color) _getModeInfo() {
    switch (widget.mode) {
      case 0:
        return (FluentIcons.numbered_list, '顺序播放', AppTheme.warmBeige);
      case 1:
        return (WindowsIcons.shuffle, '随机播放', AppTheme.vintageGold);
      case 2:
        return (FluentIcons.giftbox, '盲盒模式', AppTheme.vintageGold);
      default:
        return (FluentIcons.numbered_list, '顺序播放', AppTheme.warmBeige);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tooltip, color) = _getModeInfo();

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.warmBrown.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _isHovered ? AppTheme.vintageGold : color,
            size: 22,
          ),
        ),
      ),
    );
  }
}
