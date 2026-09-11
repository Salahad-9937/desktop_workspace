import 'package:flutter/material.dart';

/// Фоновый холст рабочего стола с координатной точечной сеткой и системным водяным знаком.
class DesktopBackground extends StatelessWidget {
  /// Создает экземпляр [DesktopBackground].
  const DesktopBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF06090F),
      child: Stack(
        children: <Widget>[
          const CustomPaint(
            painter: DesktopGridPainter(),
            child: SizedBox.expand(),
          ),
          Positioned(
            right: 20.0,
            bottom: 55.0,
            child: Opacity(
              opacity: 0.15,
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.space_dashboard_rounded,
                    size: 28.0,
                    color: Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'DESKTOP WORKSPACE',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Изолированный отрисовщик точечной координатной сетки рабочего стола.
class DesktopGridPainter extends CustomPainter {
  /// Создает экземпляр [DesktopGridPainter].
  const DesktopGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF131A28).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    const double step = 40.0;
    for (double x = 0.0; x < size.width; x += step) {
      for (double y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
