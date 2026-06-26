import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Border? border;

  /// Whether to apply the expensive [BackdropFilter] blur effect.
  /// Set to `false` for list items and repeated cards where the visual
  /// benefit is minimal but the rendering cost is significant.
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.color,
    this.border,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
      ),
      child: child,
    );

    if (!enableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: container,
      ),
    );
  }
}
