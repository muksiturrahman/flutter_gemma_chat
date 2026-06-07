import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated multi-stop gradient backdrop. Two large blurred "orbs" drift slowly
/// behind a base gradient so the glass surfaces overhead actually have
/// something to refract.
class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0820),
              Color(0xFF1A0E36),
              Color(0xFF0E1B36),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEDE7FF),
              Color(0xFFFCE7F3),
              Color(0xFFE0F2FE),
            ],
          );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
              child: const SizedBox.expand(),
            ),
            _Orb(
              alignment: Alignment(
                -0.6 + 0.5 * math.sin(t * 2 * math.pi),
                -0.5 + 0.4 * math.cos(t * 2 * math.pi + 1.2),
              ),
              color: isDark
                  ? const Color(0xFF7C4DFF)
                  : const Color(0xFFB39DDB),
              size: 460,
              opacity: isDark ? 0.45 : 0.55,
            ),
            _Orb(
              alignment: Alignment(
                0.6 - 0.5 * math.sin(t * 2 * math.pi + math.pi),
                0.5 - 0.4 * math.cos(t * 2 * math.pi + 2.0),
              ),
              color: isDark
                  ? const Color(0xFF00B0FF)
                  : const Color(0xFFF48FB1),
              size: 420,
              opacity: isDark ? 0.40 : 0.55,
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  const _Orb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
