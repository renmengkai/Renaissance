import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class VintageToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;

  const VintageToggleSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
  });

  @override
  State<VintageToggleSwitch> createState() => _VintageToggleSwitchState();
}

class _VintageToggleSwitchState extends State<VintageToggleSwitch>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(VintageToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onChanged?.call(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.warmBrown.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: AppTheme.warmCream,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.description!,
                        style: TextStyle(
                          color: AppTheme.warmBeige.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch() {
    return Semantics(
      container: false,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: widget.value
                    ? [
                        AppTheme.vintageGold.withOpacity(0.3),
                        AppTheme.vintageGold.withOpacity(0.2),
                      ]
                    : [
                        AppTheme.warmBrown.withOpacity(0.3),
                        AppTheme.warmBrown.withOpacity(0.2),
                      ],
              ),
              border: Border.all(
                color: widget.value
                    ? AppTheme.vintageGold.withOpacity(0.5)
                    : AppTheme.warmBrown.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: widget.value
                  ? [
                      BoxShadow(
                        color: AppTheme.vintageGold.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 4 + _animation.value * 24,
                  top: 3,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.value
                            ? [
                                AppTheme.vintageGold,
                                const Color(0xFFB8941F),
                              ]
                            : [
                                AppTheme.warmBeige,
                                AppTheme.warmBrown,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VintageSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? label;
  final String? suffix;

  const VintageSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.label,
    this.suffix,
  });

  @override
  State<VintageSlider> createState() => _VintageSliderState();
}

class _VintageSliderState extends State<VintageSlider> {
  bool _isHovered = false;
  bool _isDragging = false;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(VintageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isDragging) {
      _currentValue = widget.value;
    }
  }

  void _updateValue(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    final newValue = widget.min + (widget.max - widget.min) * ratio;
    setState(() {
      _currentValue = newValue.clamp(widget.min, widget.max);
    });
    widget.onChanged?.call(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      color: AppTheme.warmBeige,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(_currentValue * 100).toInt()}${widget.suffix ?? '%'}',
                    style: TextStyle(
                      color: AppTheme.vintageGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() => _isDragging = true);
              HapticFeedback.lightImpact();
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              _updateValue(localPosition.dx, box.size.width);
            },
            onHorizontalDragEnd: (details) {
              setState(() => _isDragging = false);
            },
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              _updateValue(details.localPosition.dx, box.size.width);
              HapticFeedback.lightImpact();
            },
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CustomPaint(
                size: Size.infinite,
                painter: _VintageSliderPainter(
                  value: (_currentValue - widget.min) / (widget.max - widget.min),
                  isHovered: _isHovered,
                  isDragging: _isDragging,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VintageSliderPainter extends CustomPainter {
  final double value;
  final bool isHovered;
  final bool isDragging;

  _VintageSliderPainter({
    required this.value,
    required this.isHovered,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackHeight = 4.0;
    final thumbRadius = isHovered || isDragging ? 8.0 : 6.0;
    final thumbX = value * size.width;

    final trackPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.warmBrown.withOpacity(0.3),
          AppTheme.warmBrown.withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, trackHeight));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: size.width,
          height: trackHeight,
        ),
        Radius.circular(trackHeight / 2),
      ),
      trackPaint,
    );

    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      final tickPaint = Paint()
        ..color = AppTheme.warmBeige.withOpacity(i % 5 == 0 ? 0.25 : 0.12)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, centerY - 6),
        Offset(x, centerY + 6),
        tickPaint,
      );
    }

    if (value > 0) {
      final activeTrackPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.vintageGold.withOpacity(0.7),
            AppTheme.vintageGold,
          ],
        ).createShader(Rect.fromLTWH(0, 0, thumbX, trackHeight));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(thumbX / 2, centerY),
            width: thumbX,
            height: trackHeight,
          ),
          Radius.circular(trackHeight / 2),
        ),
        activeTrackPaint,
      );
    }

    final thumbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.vintageGold,
          const Color(0xFFB8941F),
        ],
      ).createShader(Rect.fromCircle(center: Offset(thumbX, centerY), radius: thumbRadius));

    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius + 3,
      Paint()..color = AppTheme.vintageGold.withOpacity(0.2),
    );

    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius,
      thumbPaint,
    );

    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
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

class VintageDropdown<T> extends StatefulWidget {
  final T value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;

  const VintageDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.label,
  });

  @override
  State<VintageDropdown<T>> createState() => _VintageDropdownState<T>();
}

class _VintageDropdownState<T> extends State<VintageDropdown<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label!,
                style: const TextStyle(
                  color: AppTheme.warmBeige,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppTheme.warmBrown.withOpacity(0.15)
                  : AppTheme.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? AppTheme.vintageGold.withOpacity(0.3)
                    : AppTheme.warmBrown.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.items.firstWhere((e) => e.value == widget.value).label,
                    style: const TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  FluentIcons.chevron_down,
                  size: 12,
                  color: AppTheme.warmBeige.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownItem<T> {
  final T value;
  final String label;

  const DropdownItem({
    required this.value,
    required this.label,
  });
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final IconData? icon;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.icon,
    this.title,
    this.padding,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.acrylicDark.withOpacity(0.9)
              : AppTheme.acrylicDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppTheme.vintageGold.withOpacity(0.2)
                : AppTheme.warmBrown.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.icon != null || widget.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    if (widget.icon != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.vintageGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: AppTheme.vintageGold,
                          size: 18,
                        ),
                      ),
                    if (widget.icon != null && widget.title != null)
                      const SizedBox(width: 12),
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          color: AppTheme.warmCream,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            widget.child,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.warmCream,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class VintageButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFilled;

  const VintageButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFilled = false,
  });

  @override
  State<VintageButton> createState() => _VintageButtonState();
}

class _VintageButtonState extends State<VintageButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isFilled
                ? _isHovered
                    ? AppTheme.vintageGold
                    : const Color(0xFFB8941F)
                : _isHovered
                    ? AppTheme.warmBrown.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isFilled
                  ? Colors.transparent
                  : AppTheme.warmBrown.withOpacity(0.5),
            ),
            boxShadow: widget.isFilled && _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.vintageGold.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.isFilled
                  ? Colors.white
                  : _isHovered
                      ? AppTheme.vintageGold
                      : AppTheme.warmBeige,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
