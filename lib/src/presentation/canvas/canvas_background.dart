import 'package:flutter/material.dart';

import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Базовый фоновый слой холста с координатной сеткой.
class CanvasBackground extends StatelessWidget {
  /// Шаг координатной сетки в пикселях.
  final double gridSpacing;

  /// Создает экземпляр [CanvasBackground].
  const CanvasBackground({
    super.key,
    this.gridSpacing = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _GridPainter(
          backgroundColor: theme.spaceBackground,
          lineColor: theme.borderInactive.withValues(alpha: 0.12),
          spacing: gridSpacing,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color backgroundColor;
  final Color lineColor;
  final double spacing;

  const _GridPainter({
    required this.backgroundColor,
    required this.lineColor,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0.0), Offset(x, size.height), linePaint);
    }

    for (double y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0.0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.spacing != spacing;
  }
}