import 'dart:math' as math;
import 'dart:ui';
import '../../state/models/window_state.dart';

/// Утилита детекции геометрического перекрытия окон.
abstract class CollisionDetector {
  /// Проверяет наличие горизонтального перекрытия между окнами [a] и [b].
  static bool hasHorizontalOverlap(WindowState a, WindowState b) {
    final double left = math.max(a.x, b.x);
    final double right = math.min(a.x + a.width, b.x + b.width);
    return (right - left) > 20.0;
  }
}

/// Алгоритм расчета магнитного притяжения окна к краям экрана и соседним окнам.
abstract class MagnetSnapper {
  /// Вычисляет новые координаты с учетом магнитного притяжения.
  static Offset snap({
    required WindowState win,
    required double targetX,
    required double targetY,
    required List<WindowState> allWindows,
    required Size screenSize,
    required double availableHeight,
    required double magnetThreshold,
  }) {
    double left = targetX;
    double top = targetY;

    if (left.abs() < magnetThreshold) {
      left = 0.0;
    }
    if (top.abs() < magnetThreshold) {
      top = 0.0;
    }
    if ((left + win.width - screenSize.width).abs() < magnetThreshold) {
      left = screenSize.width - win.width;
    }
    if ((top + win.height - availableHeight).abs() < magnetThreshold) {
      top = availableHeight - win.height;
    }

    for (final WindowState other in allWindows) {
      if (other.id == win.id || other.isMinimized) {
        continue;
      }
      final double oLeft = other.x;
      final double oTop = other.y;
      final double oRight = other.x + other.width;
      final double oBottom = other.y + other.height;

      if ((left - oRight).abs() < magnetThreshold) {
        left = oRight;
      }
      if ((left + win.width - oLeft).abs() < magnetThreshold) {
        left = oLeft - win.width;
      }
      if ((top - oBottom).abs() < magnetThreshold) {
        top = oBottom;
      }
      if ((top + win.height - oTop).abs() < magnetThreshold) {
        top = oTop - win.height;
      }
    }

    return Offset(left, top);
  }
}