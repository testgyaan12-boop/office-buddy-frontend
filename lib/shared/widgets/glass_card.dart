import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 16,
    this.opacity = 0.62,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? Colors.white).withValues(alpha: opacity) : null,
              gradient: gradient,
              borderRadius: borderRadius,
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                    width: 1.1,
                  ),
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Industry mesh background for full glass pages
class GlassMeshBackground extends StatelessWidget {
  final List<Color> colors;
  const GlassMeshBackground({super.key, this.colors = const [Color(0xFFEEF2FF), Color(0xFFF0FDFA), Color(0xFFFFF7ED)]});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -60, right: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF6366F1).withValues(alpha: 0.14), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 140, left: -50,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF14B8A6).withValues(alpha: 0.13), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 80, right: 20,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFFF59E0B).withValues(alpha: 0.10), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40, left: -20,
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.11), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
