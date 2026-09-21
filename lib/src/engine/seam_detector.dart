import 'dart:math' as math;

import '../model/geometry_types.dart';
import '../model/shared_seam.dart';
import '../model/window_state.dart';

/// Вычислительный модуль обнаружения непрерывных общих швов между окнами.
class SeamDetector {
  const SeamDetector._();

  /// Находит все уникальные общие непрерывные швы между парами окон на холсте.
  static List<SharedSeam> findSharedSeams({
    required List<WindowState> windows,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    final List<SharedSeam> seams = <SharedSeam>[];
    final List<WindowState> visible = windows
        .where((WindowState w) => !w.isMinimized)
        .toList(growable: false);

    for (int i = 0; i < visible.length; i++) {
      final WindowState a = visible[i];

      for (int j = 0; j < visible.length; j++) {
        if (i == j) {
          continue;
        }
        final WindowState b = visible[j];

        // 1. Вертикальный шов: правое ребро A соприкасается с левым ребром B
        if ((a.rect.right - b.rect.left).abs() <= seamEpsilon) {
          final double overlapStart = math.max(a.rect.top, b.rect.top);
          final double overlapEnd = math.min(a.rect.bottom, b.rect.bottom);
          final double overlap = overlapEnd - overlapStart;

          if (overlap >= minSeamOverlap) {
            final double avgPos = (a.rect.right + b.rect.left) / 2.0;
            final bool alreadyExists = seams.any(
              (SharedSeam s) =>
                  s.isVertical &&
                  ((s.primaryWindowId == a.id &&
                          s.secondaryWindowId == b.id) ||
                      (s.primaryWindowId == b.id &&
                          s.secondaryWindowId == a.id)),
            );
            if (!alreadyExists) {
              seams.add(
                SharedSeam(
                  isVertical: true,
                  position: avgPos,
                  start: overlapStart,
                  end: overlapEnd,
                  primaryWindowId: a.id,
                  secondaryWindowId: b.id,
                  direction: ResizeDirection.east,
                ),
              );
            }
          }
        }

        // 2. Горизонтальный шов: нижнее ребро A соприкасается с верхним ребром B
        if ((a.rect.bottom - b.rect.top).abs() <= seamEpsilon) {
          final double overlapStart = math.max(a.rect.left, b.rect.left);
          final double overlapEnd = math.min(a.rect.right, b.rect.right);
          final double overlap = overlapEnd - overlapStart;

          if (overlap >= minSeamOverlap) {
            final double avgPos = (a.rect.bottom + b.rect.top) / 2.0;
            final bool alreadyExists = seams.any(
              (SharedSeam s) =>
                  !s.isVertical &&
                  ((s.primaryWindowId == a.id &&
                          s.secondaryWindowId == b.id) ||
                      (s.primaryWindowId == b.id &&
                          s.secondaryWindowId == a.id)),
            );
            if (!alreadyExists) {
              seams.add(
                SharedSeam(
                  isVertical: false,
                  position: avgPos,
                  start: overlapStart,
                  end: overlapEnd,
                  primaryWindowId: a.id,
                  secondaryWindowId: b.id,
                  direction: ResizeDirection.south,
                ),
              );
            }
          }
        }
      }
    }

    return seams;
  }

  /// Проверяет, граничит ли ребро окна с соседними окнами по непрерывному общему шву.
  static bool hasSharedSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    if (primaryWindow.isMinimized || direction == ResizeDirection.none) {
      return false;
    }

    if (direction.affectsRight) {
      final double seamPosition = primaryWindow.rect.right;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.left - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isContinuous && overlapY >= minSeamOverlap;
      });
    }

    if (direction.affectsLeft) {
      final double seamPosition = primaryWindow.rect.left;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.right - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isContinuous && overlapY >= minSeamOverlap;
      });
    }

    if (direction.affectsBottom) {
      final double seamPosition = primaryWindow.rect.bottom;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.top - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isContinuous && overlapX >= minSeamOverlap;
      });
    }

    if (direction.affectsTop) {
      final double seamPosition = primaryWindow.rect.top;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.bottom - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isContinuous && overlapX >= minSeamOverlap;
      });
    }

    return false;
  }
}