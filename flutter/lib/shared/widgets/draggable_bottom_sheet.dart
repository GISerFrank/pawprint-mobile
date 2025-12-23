import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/shell/main_shell.dart';

/// 统一的可拖动底部弹出菜单
/// 支持拖动拉伸，弹出时隐藏底部导航栏
class DraggableBottomSheet extends StatelessWidget {
  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;
  final ScrollController? scrollController;

  const DraggableBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
    this.expand = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动手柄
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (_) {}, // 确保手柄区域可拖动
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.stone300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 显示可拖动底部弹出菜单的辅助函数
/// 自动隐藏底部导航栏
Future<T?> showDraggableBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.9,
  bool isDismissible = true,
  bool enableDrag = true,
}) async {
  // 隐藏导航栏
  NavBarVisibility.hide(context);

  try {
    final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      // 使用 useSafeArea: false 让弹出菜单可以覆盖底部导航栏区域
      useSafeArea: false,
      builder: (context) => DraggableBottomSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
    return result;
  } finally {
    // 恢复导航栏
    if (context.mounted) {
      NavBarVisibility.show(context);
    }
  }
}

/// 带键盘适配的底部弹出菜单内容包装器
/// 用于包含输入框的表单
class KeyboardAwareSheetContent extends StatelessWidget {
  final Widget child;

  const KeyboardAwareSheetContent({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}
