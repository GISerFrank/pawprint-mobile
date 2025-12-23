import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';

class HealthStatusIndicator extends StatefulWidget {
  final HealthStatus status;
  final VoidCallback onTap;
  final bool showLabel;

  const HealthStatusIndicator({
    super.key,
    required this.status,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  State<HealthStatusIndicator> createState() => _HealthStatusIndicatorState();
}

class _HealthStatusIndicatorState extends State<HealthStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.status == HealthStatus.sick) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HealthStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == HealthStatus.sick && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.status == HealthStatus.healthy && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSick = widget.status == HealthStatus.sick;
    final color = isSick ? AppColors.peach500 : AppColors.mint500;
    final bgColor = isSick ? AppColors.peach100 : AppColors.mint50.withOpacity(0.2);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        listenable: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSick
                  ? [BoxShadow(color: color.withOpacity(0.3 * (_pulseAnimation.value - 0.7)), blurRadius: 12 * _pulseAnimation.value, spreadRadius: 1)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                if (widget.showLabel) ...[
                  const SizedBox(width: 6),
                  Text(widget.status.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSick ? AppColors.peach800 : Colors.white)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnimatedBuilder extends StatelessWidget {
  final Listenable listenable;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({super.key, required this.listenable, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(listenable: listenable, builder: builder, child: child);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder2({super.key, required Listenable listenable, required this.builder, this.child}) : super(listenable: listenable);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
