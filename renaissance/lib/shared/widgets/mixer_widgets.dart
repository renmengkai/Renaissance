import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class VintageKnob extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double size;
  final Color? color;
  final String? label;

  const VintageKnob({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 60,
    this.color,
    this.label,
  });

  @override
  State<VintageKnob> createState() => _VintageKnobState();
}

class _VintageKnobState extends State<VintageKnob> {
  bool _isDragging = false;
  double _startY = 0;
  double _startValue = 0;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.vintageGold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (details) {
            _startY = details.globalPosition.dy;
            _startValue = widget.value;
            setState(() => _isDragging = true);
            HapticFeedback.lightImpact();
          },
          onPanUpdate: (details) {
            final deltaY = _startY - details.globalPosition.dy;
            final sensitivity = 0.005;
            final newValue = (_startValue + deltaY * sensitivity).clamp(0.0, 1.0);
            widget.onChanged?.call(newValue);
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            HapticFeedback.mediumImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.charcoal,
                  AppTheme.softBlack,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (_isDragging)
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _KnobPainter(
                value: widget.value,
                color: color,
                isDragging: _isDragging,
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
        Text(
          '${(widget.value * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool isDragging;

  _KnobPainter({
    required this.value,
    required this.color,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final arcPaint = Paint()
      ..color = AppTheme.warmBrown.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5,
      false,
      arcPaint,
    );

    final activeArcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: pi * 0.75,
        endAngle: pi * 0.75 + pi * 1.5 * value,
        colors: [
          color.withOpacity(0.5),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5 * value,
      false,
      activeArcPaint,
    );

    final angle = pi * 0.75 + pi * 1.5 * value;
    final indicatorX = center.dx + cos(angle) * (radius - 2);
    final indicatorY = center.dy + sin(angle) * (radius - 2);

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 6 : 3);

    canvas.drawCircle(Offset(indicatorX, indicatorY), 5, indicatorPaint);

    for (int i = 0; i <= 10; i++) {
      final tickAngle = pi * 0.75 + pi * 1.5 * i / 10;
      final innerRadius = radius - 12;
      final outerRadius = radius - 8;

      final tickPaint = Paint()
        ..color = i <= (value * 10).round()
            ? color.withOpacity(0.6)
            : AppTheme.warmBeige.withOpacity(0.2)
        ..strokeWidth = i % 5 == 0 ? 2 : 1;

      canvas.drawLine(
        Offset(
          center.dx + cos(tickAngle) * innerRadius,
          center.dy + sin(tickAngle) * innerRadius,
        ),
        Offset(
          center.dx + cos(tickAngle) * outerRadius,
          center.dy + sin(tickAngle) * outerRadius,
        ),
        tickPaint,
      );
    }

    final centerPaint = Paint()
      ..color = AppTheme.softBlack
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, centerPaint);

    final innerRingPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 10, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MixerTrackCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final double volume;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onRemove;
  final bool isActive;

  const MixerTrackCard({
    super.key,
    required this.name,
    required this.icon,
    required this.volume,
    this.onVolumeChanged,
    this.onRemove,
    this.isActive = false,
  });

  @override
  State<MixerTrackCard> createState() => _MixerTrackCardState();
}

class _MixerTrackCardState extends State<MixerTrackCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isActive) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(MixerTrackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.warmBrown.withOpacity(0.15)
              : AppTheme.warmBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isActive
                ? AppTheme.vintageGold.withOpacity(0.4)
                : AppTheme.warmBrown.withOpacity(0.2),
          ),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: AppTheme.vintageGold.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.vintageGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppTheme.vintageGold,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onRemove != null)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        FluentIcons.chrome_close,
                        color: Colors.orange.withOpacity(0.7),
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.isActive)
              SizedBox(
                height: 24,
                child: Semantics(
                  container: false,
                  excludeSemantics: true,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _MiniWavePainter(
                          animation: _waveController.value,
                          color: AppTheme.vintageGold,
                        ),
                        size: const Size(double.infinity, 24),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '已静音',
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  FluentIcons.volume0,
                  color: AppTheme.warmBeige.withOpacity(0.5),
                  size: 12,
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 100,
                    value: widget.volume * 100,
                    onChanged: (v) => widget.onVolumeChanged?.call(v / 100),
                  ),
                ),
                Text(
                  '${(widget.volume * 100).toInt()}%',
                  style: TextStyle(
                    color: AppTheme.warmBeige,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _MiniWavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final barWidth = 3.0;
    final barSpacing = 4.0;
    final barCount = (size.width / (barWidth + barSpacing)).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final phase = animation * 2 * pi + i * 0.5;
      final height = (sin(phase) * 0.5 + 0.5) * size.height * 0.8 + size.height * 0.1;

      path.moveTo(x, centerY - height / 2);
      path.lineTo(x, centerY + height / 2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PresetChip extends StatefulWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const PresetChip({
    super.key,
    required this.name,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<PresetChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.vintageGold.withOpacity(0.2)
                : _isHovered
                    ? AppTheme.warmBrown.withOpacity(0.2)
                    : AppTheme.warmBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.vintageGold.withOpacity(0.5)
                  : AppTheme.warmBrown.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? AppTheme.vintageGold
                    : AppTheme.warmBeige.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                widget.name,
                style: TextStyle(
                  color: widget.isSelected
                      ? AppTheme.vintageGold
                      : AppTheme.warmBeige.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MixerPreset {
  final String name;
  final IconData icon;
  final Map<String, double> volumes;

  const MixerPreset({
    required this.name,
    required this.icon,
    required this.volumes,
  });

  static List<MixerPreset> get defaults => [
    MixerPreset(
      name: '雨天咖啡馆',
      icon: FluentIcons.cloud_weather,
      volumes: {'rain': 0.6, 'coffee': 0.4},
    ),
    MixerPreset(
      name: '深夜书房',
      icon: FluentIcons.book_answers,
      volumes: {'clock': 0.3, 'fire': 0.5},
    ),
    MixerPreset(
      name: '森林漫步',
      icon: FluentIcons.trophy,
      volumes: {'bird': 0.5, 'wind': 0.4, 'grass': 0.3},
    ),
    MixerPreset(
      name: '海边日落',
      icon: FluentIcons.clear,
      volumes: {'ocean': 0.7, 'wind': 0.2},
    ),
    MixerPreset(
      name: '城市夜晚',
      icon: FluentIcons.people,
      volumes: {'street': 0.4, 'tv': 0.2},
    ),
  ];
}

class EnhancedMixerPanel extends StatelessWidget {
  final List<MixerTrackCard> activeTracks;
  final List<PresetChip> availablePresets;
  final VoidCallback? onStopAll;
  final ValueChanged<String>? onPresetSelected;

  const EnhancedMixerPanel({
    super.key,
    required this.activeTracks,
    required this.availablePresets,
    this.onStopAll,
    this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmBrown.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          if (activeTracks.isNotEmpty) ...[
            Text(
              '活跃音效',
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...activeTracks,
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.warmBrown.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '场景预设',
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePresets,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.vintageGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FluentIcons.equalizer,
            color: AppTheme.vintageGold,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '混音台',
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
                color: AppTheme.warmCream,
                fontSize: 18,
              ),
        ),
        const Spacer(),
        if (activeTracks.isNotEmpty && onStopAll != null)
          Tooltip(
            message: '停止全部',
            child: GestureDetector(
              onTap: onStopAll,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  FluentIcons.stop_solid,
                  color: Colors.orange.withOpacity(0.8),
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
