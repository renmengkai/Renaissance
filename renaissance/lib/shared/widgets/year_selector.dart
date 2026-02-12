import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show FixedExtentScrollController;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class YearSelector extends StatefulWidget {
  final int initialYear;
  final int minYear;
  final int maxYear;
  final ValueChanged<int>? onYearSelected;
  final VoidCallback? onClose;

  const YearSelector({
    super.key,
    this.initialYear = 1995,
    this.minYear = 1980,
    this.maxYear = 2010,
    this.onYearSelected,
    this.onClose,
  });

  @override
  State<YearSelector> createState() => _YearSelectorState();
}

class _YearSelectorState extends State<YearSelector> {
  late int _selectedYear;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _scrollController = FixedExtentScrollController(
      initialItem: widget.initialYear - widget.minYear,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.warmBrown.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.calendar,
                    color: AppTheme.vintageGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '选择年份',
                    style: FluentTheme.of(context).typography.subtitle?.copyWith(
                      color: AppTheme.warmCream,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  FluentIcons.chrome_close,
                  color: AppTheme.warmBeige.withOpacity(0.6),
                  size: 16,
                ),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 年份显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.vintageGold.withOpacity(0.2),
                  AppTheme.vintageGold.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.vintageGold.withOpacity(0.3),
              ),
            ),
            child: Text(
              '$_selectedYear',
              style: FluentTheme.of(context).typography.title?.copyWith(
                color: AppTheme.vintageGold,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 300.ms,
              ),

          const SizedBox(height: 24),

          // 年份滑块
          _buildYearSlider(),

          const SizedBox(height: 24),

          // 快速选择按钮
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickYearButton(
                year: 1985,
                isSelected: _selectedYear == 1985,
                onTap: () => _selectYear(1985),
              ),
              _QuickYearButton(
                year: 1990,
                isSelected: _selectedYear == 1990,
                onTap: () => _selectYear(1990),
              ),
              _QuickYearButton(
                year: 1995,
                isSelected: _selectedYear == 1995,
                onTap: () => _selectYear(1995),
              ),
              _QuickYearButton(
                year: 2000,
                isSelected: _selectedYear == 2000,
                onTap: () => _selectYear(2000),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onYearSelected?.call(_selectedYear);
                widget.onClose?.call();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppTheme.vintageGold),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: const Text(
                '确认选择',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildYearSlider() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.softBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 选中指示器
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.vintageGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.vintageGold.withOpacity(0.3),
              ),
            ),
          ),

          // 列表
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.maxYear - widget.minYear + 1,
            itemBuilder: (context, index) {
              final year = widget.minYear + index;
              final isSelected = year == _selectedYear;

              return GestureDetector(
                onTap: () => _selectYear(year),
                child: Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    '$year',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.vintageGold
                          : AppTheme.warmBeige.withOpacity(0.5),
                      fontSize: isSelected ? 18 : 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),

          // 左右渐变遮罩
          Positioned(
            left: 0,
            child: Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.softBlack.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    AppTheme.softBlack.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectYear(int year) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedYear = year;
    });

    // 滚动到选中位置
    _scrollController.animateTo(
      (year - widget.minYear) * 60.0 - 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

// 快速年份按钮
class _QuickYearButton extends StatelessWidget {
  final int year;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickYearButton({
    required this.year,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.vintageGold.withOpacity(0.2)
              : AppTheme.warmBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.vintageGold
                : AppTheme.warmBrown.withOpacity(0.3),
          ),
        ),
        child: Text(
          '$year',
          style: TextStyle(
            color: isSelected ? AppTheme.vintageGold : AppTheme.warmBeige,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// 复古旋钮选择器
class VintageKnob extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? label;

  const VintageKnob({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.onChanged,
    this.label,
  });

  @override
  State<VintageKnob> createState() => _VintageKnobState();
}

class _VintageKnobState extends State<VintageKnob> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.value - widget.min) / (widget.max - widget.min);
    final angle = -135 + percentage * 270;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (_) {
            setState(() => _isDragging = true);
            HapticFeedback.lightImpact();
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          onPanUpdate: (details) {
            // 根据拖动更新值
            final delta = details.delta.dy * -0.5;
            final newValue = (widget.value + delta).clamp(widget.min, widget.max);
            widget.onChanged?.call(newValue);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.warmBrown.withOpacity(0.4),
                  AppTheme.softBlack,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: AppTheme.warmBrown.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: angle / 360,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3a3a3a),
                        Color(0xFF1a1a1a),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 指示器
                      Positioned(
                        top: 8,
                        child: Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.vintageGold,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.vintageGold.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 中心点
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
