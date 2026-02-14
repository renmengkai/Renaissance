import 'package:fluent_ui/fluent_ui.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_utils.dart';
import 'window_controls_stub.dart'
    if (dart.library.io) 'window_controls_impl.dart';

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
          Expanded(
            child: _buildDraggableArea(context),
          ),
          if (actions != null) ...actions!,
          if (PlatformUtils.isDesktop) ...[
            _WindowControlButton(
              icon: FluentIcons.remove,
              onPressed: () => minimizeWindow(),
            ),
            _WindowControlButton(
              icon: FluentIcons.square,
              onPressed: () async {
                if (await isWindowMaximized()) {
                  await unmaximizeWindow();
                } else {
                  await maximizeWindow();
                }
              },
            ),
            _WindowControlButton(
              icon: FluentIcons.chrome_close,
              isClose: true,
              onPressed: () => closeWindow(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraggableArea(BuildContext context) {
    if (!PlatformUtils.isDesktop) {
      return Padding(
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
            if (showBackButton) const SizedBox(width: 12),
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
      );
    }

    return DragToMoveArea(
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
            if (showBackButton) const SizedBox(width: 12),
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
