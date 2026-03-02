import 'package:flutter/material.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';

/// Reusable Kumi-styled card with high border radius
class KumiCard extends StatelessWidget {
  const KumiCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color = Colors.white,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: KumiColors.warmGray.withValues(alpha: 0.15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
