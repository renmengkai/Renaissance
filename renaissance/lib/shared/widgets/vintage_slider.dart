import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class VintageSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double trackHeight;
  final double thumbRadius;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final String? label;

  const VintageSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.trackHeight = 4.0,
    this.thumbRadius = 12.0,
    this.leftIcon,
    this.rightIcon,
    this.label,
  });

  @override
  State<VintageSlider> createState() => _VintageSliderState();
}

class _VintageSliderState extends State<VintageSlider> {
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
    final activeColor = widget.activeColor ?? AppTheme.vintageGold;
    final inactiveColor = widget.inactiveColor ?? AppTheme.warmBrown.withOpacity(0.3);
    final thumbColor = widget.thumbColor ?? AppTheme.vintageGold;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Row(
          children: [
            if (widget.leftIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  widget.leftIcon,
                  size: 16,
                  color: AppTheme.warmBeige.withOpacity(0.6),
                ),
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragStart: (details) {
                  setState(() => _isDragging = true);
                  widget.onChangeStart?.call(_currentValue);
                  HapticFeedback.lightImpact();
                },
                onHorizontalDragUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  _updateValue(localPosition.dx, box.size.width);
                },
                onHorizontalDragEnd: (details) {
                  setState(() => _isDragging = false);
                  widget.onChangeEnd?.call(_currentValue);
                },
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  _updateValue(details.localPosition.dx, box.size.width);
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 32,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _VintageSliderPainter(
                      value: (_currentValue - widget.min) / (widget.max - widget.min),
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      thumbColor: thumbColor,
                      trackHeight: widget.trackHeight,
                      thumbRadius: widget.thumbRadius,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.rightIcon != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  widget.rightIcon,
                  size: 16,
                  color: AppTheme.warmBeige.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _VintageSliderPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double trackHeight;
  final double thumbRadius;
  final bool isDragging;

  _VintageSliderPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.trackHeight,
    required this.thumbRadius,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackRadius = trackHeight / 2;
    final thumbX = value * size.width;

    // 绘制轨道背景
    final trackPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: size.width,
          height: trackHeight,
        ),
        Radius.circular(trackRadius),
      ),
      trackPaint,
    );

    // 绘制活动轨道
    if (value > 0) {
      final activeTrackPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(thumbX / 2, centerY),
            width: thumbX,
            height: trackHeight,
          ),
          Radius.circular(trackRadius),
        ),
        activeTrackPaint,
      );
    }

    // 绘制刻度线（复古风格）
    final tickPaint = Paint()
      ..color = AppTheme.warmBeige.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, centerY - 4),
        Offset(x, centerY + 4),
        tickPaint,
      );
    }

    // 滑块阴影
    canvas.drawCircle(
      Offset(thumbX, centerY),
      isDragging ? thumbRadius + 2 : thumbRadius,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 绘制滑块
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // 滑块主体
    canvas.drawCircle(
      Offset(thumbX, centerY),
      isDragging ? thumbRadius + 2 : thumbRadius,
      thumbPaint,
    );

    // 滑块内部装饰
    final innerThumbPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius * 0.4,
      innerThumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 垂直滑块（用于混音台）
class VintageVerticalSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? label;

  const VintageVerticalSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.label,
  });

  @override
  State<VintageVerticalSlider> createState() => _VintageVerticalSliderState();
}

class _VintageVerticalSliderState extends State<VintageVerticalSlider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.vintageGold;
    final inactiveColor = widget.inactiveColor ?? AppTheme.warmBrown.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 滑块轨道
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final ratio = 1.0 - (localPosition.dy / 150).clamp(0.0, 1.0);
            final newValue = widget.min + (widget.max - widget.min) * ratio;
            widget.onChanged?.call(newValue.clamp(widget.min, widget.max));
          },
          onTapDown: (details) {
            final ratio = 1.0 - (details.localPosition.dy / 150).clamp(0.0, 1.0);
            final newValue = widget.min + (widget.max - widget.min) * ratio;
            widget.onChanged?.call(newValue.clamp(widget.min, widget.max));
            HapticFeedback.lightImpact();
          },
          child: Container(
            width: 60,
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.acrylicDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warmBrown.withOpacity(0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 背景轨道
                Container(
                  width: 4,
                  height: 130,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: inactiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 活动轨道
                Container(
                  width: 4,
                  height: 130 * (widget.value - widget.min) / (widget.max - widget.min),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 滑块指示器
                Positioned(
                  bottom: 10 + 130 * (widget.value - widget.min) / (widget.max - widget.min) - 8,
                  child: Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 标签
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.label!,
              style: const TextStyle(
                color: AppTheme.warmBeige,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
