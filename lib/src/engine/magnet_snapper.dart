import 'dart:math' as math;

import '../model/geometry_types.dart';
import '../model/window_state.dart';

/// Модуль расчета векторного магнитного притягивания окон к граням холста и смежным панелям.
class MagnetSnapper {
  const MagnetSnapper._();

  /// Вычисляет скорректированную позицию окна с учетом магнитного поля.
  static (double x, double y) snapPosition({
    required double targetX,
    required double targetY,
    required double width,
    required double height,
    required WorkspaceRect availableArea,
    required List<WindowState> otherWindows,
    required double magnetThreshold,
    required double minOverlap,
  }) {
    double snappedX = targetX;
    double snappedY = targetY;

    bool snappedHorizontal = false;
    bool snappedVertical = false;

    // 1. Приоритетное притягивание к граням доступной области холста
    if ((targetX - availableArea.left).abs() < magnetThreshold) {
      snappedX = availableArea.left;
      snappedHorizontal = true;
    } else if (((targetX + width) - availableArea.right).abs() <
        magnetThreshold) {
      snappedX = availableArea.right - width;
      snappedHorizontal = true;
    }

    if ((targetY - availableArea.top).abs() < magnetThreshold) {
      snappedY = availableArea.top;
      snappedVertical = true;
    } else if (((targetY + height) - availableArea.bottom).abs() <
        magnetThreshold) {
      snappedY = availableArea.bottom - height;
      snappedVertical = true;
    }

    // 2. Межоконное притягивание граней при отсутствии прилипания к экрану
    for (final WindowState other in otherWindows) {
      if (other.isMinimized) {
        continue;
      }

      final WorkspaceRect b = other.rect;

      if (!snappedHorizontal) {
        final double overlapY = math.max(
          0.0,
          math.min(targetY + height, b.bottom) - math.max(targetY, b.top),
        );

        if (overlapY >= minOverlap) {
          if ((targetX - b.right).abs() < magnetThreshold) {
            snappedX = b.right;
            snappedHorizontal = true;
          } else if (((targetX + width) - b.left).abs() < magnetThreshold) {
            snappedX = b.left - width;
            snappedHorizontal = true;
          } else if ((targetX - b.left).abs() < magnetThreshold) {
            snappedX = b.left;
            snappedHorizontal = true;
          } else if (((targetX + width) - b.right).abs() < magnetThreshold) {
            snappedX = b.right - width;
            snappedHorizontal = true;
          }
        }
      }

      if (!snappedVertical) {
        final double overlapX = math.max(
          0.0,
          math.min(targetX + width, b.right) - math.max(targetX, b.left),
        );

        if (overlapX >= minOverlap) {
          if ((targetY - b.bottom).abs() < magnetThreshold) {
            snappedY = b.bottom;
            snappedVertical = true;
          } else if (((targetY + height) - b.top).abs() < magnetThreshold) {
            snappedY = b.top - height;
            snappedVertical = true;
          } else if ((targetY - b.top).abs() < magnetThreshold) {
            snappedY = b.top;
            snappedVertical = true;
          } else if (((targetY + height) - b.bottom).abs() < magnetThreshold) {
            snappedY = b.bottom - height;
            snappedVertical = true;
          }
        }
      }

      if (snappedHorizontal && snappedVertical) {
        break;
      }
    }

    return (snappedX, snappedY);
  }
}