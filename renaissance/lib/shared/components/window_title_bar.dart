import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_theme.dart';

class WindowTitleBar extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const WindowTitleBar({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warmBrown.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 拖动区域
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(
                          FluentIcons.back,
                          size: 16,
                          color: AppTheme.warmBeige,
                        ),
                        onPressed: onBackPressed,
                      ),
                    if (showBackButton)
                      const SizedBox(width: 12),
                    Icon(
                      FluentIcons.music_note,
                      size: 16,
                      color: AppTheme.vintageGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title ?? '文艺复兴',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.warmCream,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 自定义操作按钮
          if (actions != null) ...actions!,

          // 窗口控制按钮
          _WindowControlButton(
            icon: FluentIcons.remove,
            onPressed: () => windowManager.minimize(),
          ),
          _WindowControlButton(
            icon: FluentIcons.square,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WindowControlButton(
            icon: FluentIcons.chrome_close,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovering
                ? (widget.isClose
                    ? const Color(0xFFE81123)
                    : Colors.white.withOpacity(0.1))
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 12,
            color: _isHovering && widget.isClose
                ? Colors.white
                : AppTheme.warmBeige,
          ),
        ),
      ),
    );
  }
}
