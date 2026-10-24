// lib/core/widgets/charts.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated line/area chart drawn with CustomPaint (no chart dependency).
class LineChart extends StatelessWidget {
  final List<Offset> points;
  final Offset? marker;
  final String? markerLabel;
  final String xUnit;
  final String yUnit;
  final double height;

  const LineChart({
    super.key,
    required this.points,
    required this.xUnit,
    required this.yUnit,
    this.marker,
    this.markerLabel,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, progress, __) => CustomPaint(
          size: Size.infinite,
          painter: _LineChartPainter(
            points: points,
            marker: marker,
            markerLabel: markerLabel,
            xUnit: xUnit,
            yUnit: yUnit,
            progress: progress,
            line: scheme.primary,
            accent: scheme.tertiary,
            grid: scheme.outlineVariant.withValues(alpha: 0.6),
            label: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Offset> points;
  final Offset? marker;
  final String? markerLabel;
  final String xUnit, yUnit;
  final double progress;
  final Color line, accent, grid, label;

  _LineChartPainter({
    required this.points,
    required this.marker,
    required this.markerLabel,
    required this.xUnit,
    required this.yUnit,
    required this.progress,
    required this.line,
    required this.accent,
    required this.grid,
    required this.label,
  });

  static const _left = 44.0, _right = 12.0, _top = 16.0, _bottom = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxX = points.map((p) => p.dx).reduce(math.max);
    final maxY = points.map((p) => p.dy).reduce(math.max) * 1.18;
    if (maxX <= 0 || maxY <= 0) return;

    final plot = Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);
    Offset toPx(Offset p) => Offset(
          plot.left + p.dx / maxX * plot.width,
          plot.bottom - p.dy / maxY * plot.height,
        );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(canvas, _fmt(maxY * i / 4), Offset(plot.left - 6, y), align: TextAlign.right);
    }
    for (var i = 0; i <= 4; i++) {
      final x = plot.left + plot.width * i / 4;
      _text(canvas, _fmt(maxX * i / 4), Offset(x, plot.bottom + 12), align: TextAlign.center);
    }
    _text(canvas, yUnit, Offset(plot.left + 4, plot.top - 8), align: TextAlign.left);
    _text(canvas, xUnit, Offset(plot.right, plot.bottom - 10), align: TextAlign.right);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, plot.left + plot.width * progress + 2, size.height));

    final path = Path()..moveTo(toPx(points.first).dx, toPx(points.first).dy);
    for (final p in points.skip(1)) {
      final px = toPx(p);
      path.lineTo(px.dx, px.dy);
    }
    final fill = Path.from(path)
      ..lineTo(toPx(points.last).dx, plot.bottom)
      ..lineTo(toPx(points.first).dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.35), line.withValues(alpha: 0.02)],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final m = marker;
    if (m != null && progress > 0.95) {
      final px = toPx(m);
      final dash = Paint()
        ..color = accent
        ..strokeWidth = 1.5;
      for (var y = plot.bottom; y > px.dy; y -= 8) {
        canvas.drawLine(Offset(px.dx, y), Offset(px.dx, math.max(y - 4, px.dy)), dash);
      }
      canvas.drawCircle(px, 7, Paint()..color = accent.withValues(alpha: 0.25));
      canvas.drawCircle(px, 4.5, Paint()..color = accent);
      if (markerLabel != null) {
        final alignRight = px.dx > plot.center.dx;
        _text(canvas, markerLabel!, px + Offset(alignRight ? -10 : 10, -14),
            align: alignRight ? TextAlign.right : TextAlign.left, bold: true, color: accent);
      }
    }
  }

  void _text(Canvas canvas, String s, Offset anchor, {required TextAlign align, bool bold = false, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 10.5, color: color ?? label, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => anchor.dx - tp.width,
      TextAlign.center => anchor.dx - tp.width / 2,
      _ => anchor.dx,
    };
    tp.paint(canvas, Offset(dx, anchor.dy - tp.height / 2));
  }

  static String _fmt(double v) {
    if (v == 0) return '0';
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(3);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress || old.points != points || old.marker != marker || old.line != line;
}

/// Animated donut chart; [values] and [colors] are parallel lists.
class DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final Widget center;
  final double size;

  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    required this.center,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => CustomPaint(
          painter: _DonutPainter(values, colors, t, track),
          child: child,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;
  final Color track;

  _DonutPainter(this.values, this.colors, this.progress, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    const gap = 0.03;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2 * progress;
      final visible = values.length > 1 ? math.max(0.0, sweep - gap) : sweep;
      canvas.drawArc(rect, start, visible, false, base..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.values != values;
}
