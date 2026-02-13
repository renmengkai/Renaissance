import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Colors;
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class AppAnimations {
  static Duration get instant => 100.ms;
  static Duration get quick => 200.ms;
  static Duration get normal => 400.ms;
  static Duration get slow => 800.ms;
  static Duration get verySlow => 1200.ms;

  static const kDefaultCurve = Curves.easeOutCubic;
  static const kBounceCurve = Curves.elasticOut;
  static const kSmoothCurve = Curves.easeInOutCubic;
}

extension AnimateExtensions on Widget {
  Widget fadeInUp({Duration? duration, Duration? delay}) {
    return animate()
        .fadeIn(duration: duration ?? AppAnimations.normal, delay: delay)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration ?? AppAnimations.normal,
          curve: AppAnimations.kDefaultCurve,
        );
  }

  Widget fadeInScale({Duration? duration, Duration? delay}) {
    return animate()
        .fadeIn(duration: duration ?? AppAnimations.normal, delay: delay)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: duration ?? AppAnimations.normal,
          curve: AppAnimations.kDefaultCurve,
        );
  }

  Widget shimmerEffect({Duration? duration}) {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration ?? 2000.ms,
          color: AppTheme.vintageGold.withOpacity(0.1),
        );
  }

  Widget pulseGlow({Duration? duration}) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .custom(
          duration: duration ?? 1500.ms,
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vintageGold.withOpacity(0.3 * (0.5 + 0.5 * sin(value * pi))),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}

class StaggeredListAnimation {
  static List<Widget> wrap(List<Widget> children, {Duration? staggerDelay}) {
    final delay = staggerDelay ?? 50.ms;
    return children.asMap().entries.map((entry) {
      return entry.value
          .animate()
          .fadeIn(delay: delay * entry.key, duration: AppAnimations.normal)
          .slideX(
            begin: 0.1,
            end: 0,
            delay: delay * entry.key,
            duration: AppAnimations.normal,
          );
    }).toList();
  }
}

class PageTransitions {
  static Widget fadeTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget slideFadeTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: AppAnimations.kDefaultCurve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget scaleFadeTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: AppAnimations.kDefaultCurve,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class HoverEffect extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const HoverEffect({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressEffect({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 1.0, end: widget.pressedScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}
