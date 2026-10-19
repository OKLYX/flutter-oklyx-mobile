import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A box drawn to its dimension ratio (FEATURE_2610_20 / D26) — the mobile twin
/// of the web `BoxShape` (PLAN 2609_40 D26).
///
/// **Purpose**: tells boxes without a photo apart. Front = width × height, the
/// length lies diagonally as depth (ratio 0.4). Any dimension 0 = unset → a
/// dashed square + 「치수 미지정」.
/// **File**: lib/features/sales/presentation/widgets/package_box_shape.dart
///
/// ```dart
/// row.imageUrl != null
///     ? Image.network(row.imageUrl!, width: 44, height: 44)
///     : PackageBoxShape(
///         widthCm: row.widthCm,
///         lengthCm: row.lengthCm,
///         heightCm: row.heightCm,
///       )
/// ```
///
/// ⚠️ Shapes are normalized to [size] — do not compare the size of two shapes.
/// ❌ Do not draw another box picture in a screen; use this widget.
class PackageBoxShape extends StatelessWidget {
  final num widthCm;
  final num lengthCm;
  final num heightCm;
  final double size;

  const PackageBoxShape({
    required this.widthCm,
    required this.lengthCm,
    required this.heightCm,
    super.key,
    this.size = 44,
  });

  bool get _unset => widthCm <= 0 || lengthCm <= 0 || heightCm <= 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_unset) {
      return Tooltip(
        message: '치수 미지정',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
                size: Size.square(size * 0.7),
                painter: _DashedSquarePainter(scheme.outline)),
            Text('치수 미지정',
                style: TextStyle(fontSize: 9, color: scheme.outline)),
          ],
        ),
      );
    }
    return Tooltip(
      message: '$widthCm × $lengthCm × $heightCm cm 상자',
      child: CustomPaint(
        size: Size.square(size),
        painter: _BoxPainter(
            width: widthCm.toDouble(),
            length: lengthCm.toDouble(),
            height: heightCm.toDouble()),
      ),
    );
  }
}

/// Front · top · side faces in the web amber tones (amber-100 · amber-50 ·
/// amber-200, stroke amber-700).
class _BoxPainter extends CustomPainter {
  final double width;
  final double length;
  final double height;

  _BoxPainter(
      {required this.width, required this.length, required this.height});

  static const double _depthRatio = 0.4;
  static const double _strokePx = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final depth = length * _depthRatio;
    final boxW = width + depth;
    final boxH = height + depth;
    final inner = size.width - (_strokePx + 2);
    final scale = inner / math.max(boxW, boxH);
    final dx = (size.width - boxW * scale) / 2;
    final dy = (size.height - boxH * scale) / 2;
    Offset p(double x, double y) => Offset(dx + x * scale, dy + y * scale);
    final stroke = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokePx;
    void face(List<Offset> points, Color fill) {
      final path = Path()..addPolygon(points, true);
      canvas
        ..drawPath(path, Paint()..color = fill)
        ..drawPath(path, stroke);
    }

    face([
      p(0, depth),
      p(width, depth),
      p(width, height + depth),
      p(0, height + depth)
    ], const Color(0xFFFEF3C7));
    face([p(0, depth), p(depth, 0), p(width + depth, 0), p(width, depth)],
        const Color(0xFFFFFBEB));
    face([
      p(width, depth),
      p(width + depth, 0),
      p(width + depth, height),
      p(width, height + depth)
    ], const Color(0xFFFDE68A));
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.width != width || old.length != length || old.height != height;
}

class _DashedSquarePainter extends CustomPainter {
  final Color color;

  _DashedSquarePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final inset = size.width * 0.1;
    final corners = [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(size.width - inset, size.height - inset),
      Offset(inset, size.height - inset),
    ];
    for (var i = 0; i < 4; i++) {
      final from = corners[i];
      final to = corners[(i + 1) % 4];
      final length = (to - from).distance;
      final direction = (to - from) / length;
      for (var t = 0.0; t < length; t += 5) {
        canvas.drawLine(from + direction * t,
            from + direction * math.min(t + 3, length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSquarePainter old) => old.color != color;
}
