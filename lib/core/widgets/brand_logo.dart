import 'package:flutter/material.dart';

/// True Root brand colors used by the logo (kept separate so the logo
/// renders identically in-app and when exported to PNG icons).
class BrandPalette {
  static const Color tealLight = Color(0xFF00A892);
  static const Color teal = Color(0xFF007E6E);
  static const Color tealDeep = Color(0xFF003D35);
  static const Color mint = Color(0xFFB8F3DC);
  static const Color leaf = Color(0xFF34D399);
}

/// Paints the True Root mark (a leaf rising from branching roots) inside a
/// 100x100 unit square scaled to the available size.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    this.leafColors = const [Colors.white, BrandPalette.mint],
    this.rootColor = Colors.white,
    this.veinColor = BrandPalette.teal,
    this.progress = 1,
  });

  final List<Color> leafColors;
  final Color rootColor;
  final Color veinColor;

  /// 0..1 draw-in animation progress (leaf scales up, roots draw down).
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    final p = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    // Roots
    final rootPaint = Paint()
      ..color = rootColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.2;
    final roots = Path()
      ..moveTo(50, 52)
      ..lineTo(50, 92)
      ..moveTo(50, 66)
      ..quadraticBezierTo(38, 68, 27, 84)
      ..moveTo(50, 66)
      ..quadraticBezierTo(62, 68, 73, 84)
      ..moveTo(50, 78)
      ..quadraticBezierTo(43, 80, 38, 91)
      ..moveTo(50, 78)
      ..quadraticBezierTo(57, 80, 62, 91);
    for (final m in roots.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * p), rootPaint);
    }

    // Leaf
    canvas.save();
    canvas.translate(50, 54);
    canvas.scale(0.4 + 0.6 * p);
    canvas.translate(-50, -54);
    final leaf = Path()
      ..moveTo(50, 6)
      ..cubicTo(82, 20, 84, 48, 50, 54)
      ..cubicTo(16, 48, 18, 20, 50, 6)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: leafColors,
        ).createShader(const Rect.fromLTWH(18, 6, 66, 48)),
    );
    final vein = Paint()
      ..color = veinColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawPath(
      Path()
        ..moveTo(50, 46)
        ..lineTo(50, 18)
        ..moveTo(50, 36)
        ..lineTo(60, 28)
        ..moveTo(50, 30)
        ..lineTo(40, 23)
        ..moveTo(50, 42)
        ..lineTo(40, 36),
      vein,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress ||
      old.rootColor != rootColor ||
      old.veinColor != veinColor ||
      old.leafColors != leafColors;
}

/// Brand logo widget.
///
/// * [BrandLogo] – gradient rounded tile with the mark (app-icon style).
/// * [BrandLogo.mark] – the bare mark, tinted for the current surface.
/// * Set [showWordmark] for a horizontal "True Root" lockup.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.progress = 1,
    this.light = false,
  }) : bare = false;

  const BrandLogo.mark({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.progress = 1,
    this.light = false,
  }) : bare = true;

  final double size;
  final bool showWordmark;
  final double progress;

  /// Use on dark/brand-colored backgrounds (white wordmark).
  final bool light;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget mark = bare
        ? CustomPaint(
            size: Size.square(size),
            painter: BrandMarkPainter(
              leafColors: light
                  ? const [Colors.white, BrandPalette.mint]
                  : [BrandPalette.leaf, scheme.primary],
              rootColor: light ? Colors.white : scheme.primary,
              veinColor: light ? BrandPalette.teal : Colors.white,
              progress: progress,
            ),
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandPalette.tealLight, BrandPalette.tealDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: BrandPalette.teal.withValues(alpha: 0.35),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            child: CustomPaint(
              painter: BrandMarkPainter(progress: progress),
            ),
          );

    if (!showWordmark) {
      return Semantics(label: 'True Root', image: true, child: mark);
    }
    final color = light ? Colors.white : scheme.onSurface;
    return Semantics(
      label: 'True Root',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.28),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'True',
                  style: TextStyle(color: color),
                ),
                TextSpan(
                  text: 'Root',
                  style: TextStyle(
                    color: light ? BrandPalette.mint : scheme.primary,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
