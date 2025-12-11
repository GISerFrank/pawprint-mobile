import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum NotificationType { success, error, info }

/// 显示顶部通知的工具方法
void showAppNotification(
  BuildContext context, {
  required String message,
  NotificationType type = NotificationType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _NotificationOverlay(
      message: message,
      type: type,
      onDismiss: () => entry.remove(),
      duration: duration,
    ),
  );

  overlay.insert(entry);
}

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _NotificationOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconColor, icon) = switch (widget.type) {
      NotificationType.success => (
          AppColors.mint100,
          AppColors.mint500,
          Icons.check_circle,
        ),
      NotificationType.error => (
          const Color(0xFFFEE2E2),
          AppColors.error,
          Icons.error,
        ),
      NotificationType.info => (
          AppColors.sky100,
          AppColors.sky500,
          Icons.info,
        ),
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.float,
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: AppColors.stone800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.stone400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 简化的 SnackBar 通知（备用）
void showSnackBarNotification(
  BuildContext context, {
  required String message,
  NotificationType type = NotificationType.info,
}) {
  final color = switch (type) {
    NotificationType.success => AppColors.success,
    NotificationType.error => AppColors.error,
    NotificationType.info => AppColors.info,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}
