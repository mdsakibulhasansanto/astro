import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Sweeps a soft highlight across its [child] while content loads. Put
/// [SkeletonBox] shapes inside; one shimmer can cover many of them.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.onDark = false});

  final Widget child;

  /// Use on dark (night-sky) backgrounds.
  final bool onDark;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion": show still placeholders.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final dark = widget.onDark || Theme.of(context).brightness == Brightness.dark;
    final base = dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFDCE0D8);
    final glow = dark ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFF7F8F4);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value * 3 - 1; // -1 → 2 so the band fully enters and leaves
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + t * 2 - 1, -0.3),
            end: Alignment(1 + t * 2 - 1, 0.3),
            colors: [base, glow, base],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A rounded placeholder block. Its colour is replaced by the shimmer.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
  );
}

/// Card-shaped frame that matches the app's real cards while they load.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Shimmer(child: child),
    );
  }
}

/// Generic skeleton: a few text lines.
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.lines = 3, this.title = true});

  final int lines;
  final bool title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title) ...[const SkeletonBox(width: 140, height: 20), const SizedBox(height: 12)],
        for (var i = 0; i < lines; i++) ...[
          FractionallySizedBox(
            widthFactor: i == lines - 1 ? 0.6 : 1,
            child: const SkeletonBox(height: 12),
          ),
          if (i < lines - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
