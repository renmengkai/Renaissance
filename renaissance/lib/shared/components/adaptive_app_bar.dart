import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_utils.dart';
import 'window_title_bar.dart';

class AdaptiveAppBar extends StatelessWidget implements m.PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
  });

  @override
  m.Size get preferredSize => const m.Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isMobile) {
      return _buildMobileAppBar(context);
    }
    return _buildDesktopAppBar(context);
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return m.AppBar(
      backgroundColor: AppTheme.softBlack,
      foregroundColor: AppTheme.warmCream,
      elevation: 0,
      leading: leading ??
          (showBackButton
              ? m.IconButton(
                  icon: const m.Icon(m.Icons.arrow_back),
                  onPressed: onBackPressed,
                )
              : null),
      title: m.Text(
        title ?? '文艺复兴',
        style: const TextStyle(
          fontFamily: 'NotoSerifSC',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
        ),
      ),
      actions: actions?.map((action) {
        if (action is m.Widget) {
          return action;
        }
        return action;
      }).toList(),
    );
  }

  Widget _buildDesktopAppBar(BuildContext context) {
    return WindowTitleBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }
}
