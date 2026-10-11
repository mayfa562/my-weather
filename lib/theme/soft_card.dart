import 'package:flutter/material.dart';
import 'app_theme.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final BoxBorder? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadius.xl,
    this.color = AppColors.cardTint,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(color: AppColors.violetDeep.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, 9)),
        ],
      ),
      child: child,
    );
  }
}
