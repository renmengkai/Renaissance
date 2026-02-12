import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 通知类型
enum NotificationType {
  info,
  success,
  warning,
  error,
}

// 通知数据
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Duration duration;
  final VoidCallback? onTap;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onTap,
  }) : timestamp = DateTime.now();

  Color get backgroundColor {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.error:
        return const Color(0xFFE53935);
      case NotificationType.info:
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
      default:
        return Icons.info;
    }
  }
}

// 通知状态
class NotificationState {
  final List<AppNotification> notifications;

  const NotificationState({
    this.notifications = const [],
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
    );
  }
}

// 通知控制器
class NotificationController extends StateNotifier<NotificationState> {
  NotificationController() : super(const NotificationState());

  void show({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
    );

    state = state.copyWith(
      notifications: [...state.notifications, notification],
    );

    // 自动移除
    Future.delayed(duration, () {
      dismiss(notification.id);
    });
  }

  void showSuccess(String message, {String title = '成功'}) {
    show(
      title: title,
      message: message,
      type: NotificationType.success,
    );
  }

  void showError(String message, {String title = '错误'}) {
    show(
      title: title,
      message: message,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    );
  }

  void showWarning(String message, {String title = '警告'}) {
    show(
      title: title,
      message: message,
      type: NotificationType.warning,
    );
  }

  void showInfo(String message, {String title = '提示'}) {
    show(
      title: title,
      message: message,
      type: NotificationType.info,
    );
  }

  void dismiss(String id) {
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }

  void dismissAll() {
    state = const NotificationState();
  }
}

// Provider
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController();
});

// 通知覆盖层
class NotificationOverlay extends ConsumerWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider).notifications;

    return Stack(
      children: [
        child,
        Positioned(
          top: 60,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: notifications.map((notification) {
              return _NotificationItem(
                notification: notification,
                onDismiss: () {
                  ref
                      .read(notificationControllerProvider.notifier)
                      .dismiss(notification.id);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 自动消失动画
    Future.delayed(
      widget.notification.duration - const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onDismiss();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTap: () {
            widget.notification.onTap?.call();
            _controller.reverse().then((_) {
              widget.onDismiss();
            });
          },
          child: Container(
            width: 320,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.notification.backgroundColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.notification.icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.notification.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
