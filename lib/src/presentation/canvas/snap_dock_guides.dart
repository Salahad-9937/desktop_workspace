import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Слой пассивных направляющих контуров прилипания и зон тайлинга.
class SnapDockGuides extends StatelessWidget {
  /// Доступная рабочая область холста.
  final WorkspaceRect availableArea;

  /// Активная зона тайлинга при перетаскивании.
  final SnapZone activeZone;

  /// Создает экземпляр [SnapDockGuides].
  const SnapDockGuides({
    super.key,
    required this.availableArea,
    this.activeZone = SnapZone.none,
  });

  @override
  Widget build(BuildContext context) {
    if (availableArea.width <= 0.0 || availableArea.height <= 0.0) {
      return const SizedBox.shrink();
    }

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(availableArea.width, availableArea.height),
          painter: _SnapGuidesPainter(
            availableArea: availableArea,
            activeZone: activeZone,
            idleColor: theme.borderInactive.withValues(alpha: 0.25),
            activeColor: theme.borderActive.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _SnapGuidesPainter extends CustomPainter {
  final WorkspaceRect availableArea;
  final SnapZone activeZone;
  final Color idleColor;
  final Color activeColor;

  const _SnapGuidesPainter({
    required this.availableArea,
    required this.activeZone,
    required this.idleColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double halfW = w / 2.0;
    final double halfH = h / 2.0;

    final Paint defaultPaint = Paint()
      ..color = idleColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Внешний контур холста
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, w, h), defaultPaint);

    // Центральный разделитель
    _drawDashedLine(canvas, Offset(halfW, 0.0), Offset(halfW, h), defaultPaint);
    _drawDashedLine(canvas, Offset(0.0, halfH), Offset(w, halfH), defaultPaint);

    // Краевые индикаторы зон
    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(0.0, 0.0, 48.0, h * 0.35),
      activeZone == SnapZone.topLeft,
    );
    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(0.0, h * 0.35, 48.0, h * 0.3),
      activeZone == SnapZone.leftHalf,
    );
    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(0.0, h * 0.65, 48.0, h * 0.35),
      activeZone == SnapZone.bottomLeft,
    );

    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(w - 48.0, 0.0, 48.0, h * 0.35),
      activeZone == SnapZone.topRight,
    );
    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(w - 48.0, h * 0.35, 48.0, h * 0.3),
      activeZone == SnapZone.rightHalf,
    );
    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(w - 48.0, h * 0.65, 48.0, h * 0.35),
      activeZone == SnapZone.bottomRight,
    );

    _drawZoneMarker(
      canvas,
      Rect.fromLTWH(48.0, 0.0, w - 96.0, 40.0),
      activeZone == SnapZone.maximize,
    );
  }

  void _drawZoneMarker(Canvas canvas, Rect rect, bool isActive) {
    final Paint fill = Paint()
      ..color = isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = isActive ? activeColor : idleColor
      ..strokeWidth = isActive ? 1.5 : 0.75
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (dx * dx + dy * dy);
    final double totalLength = (distance > 0.0) ? (dx != 0 ? dx.abs() : dy.abs()) : 0.0;

    double current = 0.0;
    while (current < totalLength) {
      final double progressStart = current / totalLength;
      final double progressEnd =
          ((current + dashWidth).clamp(0.0, totalLength)) / totalLength;

      canvas.drawLine(
        Offset(p1.dx + (dx * progressStart), p1.dy + (dy * progressStart)),
        Offset(p1.dx + (dx * progressEnd), p1.dy + (dy * progressEnd)),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidesPainter oldDelegate) {
    return oldDelegate.activeZone != activeZone ||
        oldDelegate.availableArea != availableArea;
  }
}