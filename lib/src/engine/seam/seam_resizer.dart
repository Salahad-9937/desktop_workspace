import 'dart:ui';
import '../../config/workspace_config.dart';
import '../../state/models/geometry_types.dart';
import '../../state/models/window_state.dart';
import '../geometry/magnet_snapper.dart';

/// Алгоритм изменения размера окна с поддержкой синхронного изменения общего шва (Shared Seam Tiling).
abstract class SeamResizer {
  /// Выполняет расчет изменения размеров окна [targetId] и смежных окон при наличии общего шва.
  static List<WindowState> resize({
    required String targetId,
    required ResizeHandle handle,
    required Offset delta,
    required List<WindowState> windows,
    required Size screenSize,
    required double availableHeight,
    required WindowConstraints defaultConstraints,
  }) {
    final int targetIndex =
        windows.indexWhere((WindowState w) => w.id == targetId);
    if (targetIndex == -1) {
      return windows;
    }
    final WindowState win = windows[targetIndex];

    final double screenW = screenSize.width;
    final double screenH = availableHeight;

    final bool touchesEast = handle == ResizeHandle.e ||
        handle == ResizeHandle.ne ||
        handle == ResizeHandle.se;
    final bool touchesWest = handle == ResizeHandle.w ||
        handle == ResizeHandle.nw ||
        handle == ResizeHandle.sw;
    final bool touchesSouth = handle == ResizeHandle.s ||
        handle == ResizeHandle.se ||
        handle == ResizeHandle.sw;
    final bool touchesNorth = handle == ResizeHandle.n ||
        handle == ResizeHandle.ne ||
        handle == ResizeHandle.nw;

    final Map<String, WindowState> windowMap = <String, WindowState>{
      for (final WindowState w in windows) w.id: w,
    };

    bool horizontalSeamHandled = false;
    bool verticalSeamHandled = false;

    const double edgeTolerance = 4.0;
    const double seamTolerance = 8.0;

    // 1. Горизонтальный режим (общий вертикальный шов)
    if (touchesEast || touchesWest) {
      final bool winTouchesLeft = win.x.abs() <= edgeTolerance;
      final bool winTouchesRight =
          (win.x + win.width - screenW).abs() <= edgeTolerance;

      if (touchesEast && winTouchesLeft) {
        final double seamX = win.x + win.width;

        final List<WindowState> leftGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.x.abs() <= edgeTolerance &&
                  (w.x + w.width - seamX).abs() <= seamTolerance,
            )
            .toList();

        final List<WindowState> rightGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.x + w.width - screenW).abs() <= edgeTolerance &&
                  (w.x - seamX).abs() <= seamTolerance,
            )
            .toList();

        if (leftGroup.isNotEmpty && rightGroup.isNotEmpty) {
          horizontalSeamHandled = true;
          double dx = delta.dx;

          for (final WindowState w in leftGroup) {
            final double minW = w.effectiveConstraints(defaultConstraints).minWidth;
            if (w.width + dx < minW) {
              dx = minW - w.width;
            }
          }
          for (final WindowState w in rightGroup) {
            final double minW = w.effectiveConstraints(defaultConstraints).minWidth;
            if (w.width - dx < minW) {
              dx = w.width - minW;
            }
          }

          for (final WindowState w in leftGroup) {
            windowMap[w.id] = w.copyWith(
              width: w.width + dx,
              isMaximized: false,
            );
          }
          for (final WindowState w in rightGroup) {
            windowMap[w.id] = w.copyWith(
              x: w.x + dx,
              width: w.width - dx,
              isMaximized: false,
            );
          }
        }
      } else if (touchesWest && winTouchesRight) {
        final double seamX = win.x;

        final List<WindowState> leftGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.x.abs() <= edgeTolerance &&
                  (w.x + w.width - seamX).abs() <= seamTolerance,
            )
            .toList();

        final List<WindowState> rightGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.x + w.width - screenW).abs() <= edgeTolerance &&
                  (w.x - seamX).abs() <= seamTolerance,
            )
            .toList();

        if (leftGroup.isNotEmpty && rightGroup.isNotEmpty) {
          horizontalSeamHandled = true;
          double dx = delta.dx;

          for (final WindowState w in leftGroup) {
            final double minW = w.effectiveConstraints(defaultConstraints).minWidth;
            if (w.width + dx < minW) {
              dx = minW - w.width;
            }
          }
          for (final WindowState w in rightGroup) {
            final double minW = w.effectiveConstraints(defaultConstraints).minWidth;
            if (w.width - dx < minW) {
              dx = w.width - minW;
            }
          }

          for (final WindowState w in leftGroup) {
            windowMap[w.id] = w.copyWith(
              width: w.width + dx,
              isMaximized: false,
            );
          }
          for (final WindowState w in rightGroup) {
            windowMap[w.id] = w.copyWith(
              x: w.x + dx,
              width: w.width - dx,
              isMaximized: false,
            );
          }
        }
      }
    }

    // 2. Вертикальный режим (общий горизонтальный шов)
    if (touchesSouth || touchesNorth) {
      final bool winTouchesTop = win.y.abs() <= edgeTolerance;
      final bool winTouchesBottom =
          (win.y + win.height - screenH).abs() <= edgeTolerance;

      if (touchesSouth && winTouchesTop) {
        final double seamY = win.y + win.height;

        final List<WindowState> topGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.y.abs() <= edgeTolerance &&
                  (w.y + w.height - seamY).abs() <= seamTolerance &&
                  CollisionDetector.hasHorizontalOverlap(w, win),
            )
            .toList();

        final List<WindowState> bottomGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.y + w.height - screenH).abs() <= edgeTolerance &&
                  (w.y - seamY).abs() <= seamTolerance &&
                  CollisionDetector.hasHorizontalOverlap(w, win),
            )
            .toList();

        if (topGroup.isNotEmpty && bottomGroup.isNotEmpty) {
          verticalSeamHandled = true;
          double dy = delta.dy;

          for (final WindowState w in topGroup) {
            final double minH =
                w.effectiveConstraints(defaultConstraints).minHeight;
            if (w.height + dy < minH) {
              dy = minH - w.height;
            }
          }
          for (final WindowState w in bottomGroup) {
            final double minH =
                w.effectiveConstraints(defaultConstraints).minHeight;
            if (w.height - dy < minH) {
              dy = w.height - minH;
            }
          }

          for (final WindowState w in topGroup) {
            windowMap[w.id] = w.copyWith(
              height: w.height + dy,
              isMaximized: false,
            );
          }
          for (final WindowState w in bottomGroup) {
            windowMap[w.id] = w.copyWith(
              y: w.y + dy,
              height: w.height - dy,
              isMaximized: false,
            );
          }
        }
      } else if (touchesNorth && winTouchesBottom) {
        final double seamY = win.y;

        final List<WindowState> topGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.y.abs() <= edgeTolerance &&
                  (w.y + w.height - seamY).abs() <= seamTolerance &&
                  CollisionDetector.hasHorizontalOverlap(w, win),
            )
            .toList();

        final List<WindowState> bottomGroup = windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.y + w.height - screenH).abs() <= edgeTolerance &&
                  (w.y - seamY).abs() <= seamTolerance &&
                  CollisionDetector.hasHorizontalOverlap(w, win),
            )
            .toList();

        if (topGroup.isNotEmpty && bottomGroup.isNotEmpty) {
          verticalSeamHandled = true;
          double dy = delta.dy;

          for (final WindowState w in topGroup) {
            final double minH =
                w.effectiveConstraints(defaultConstraints).minHeight;
            if (w.height + dy < minH) {
              dy = minH - w.height;
            }
          }
          for (final WindowState w in bottomGroup) {
            final double minH =
                w.effectiveConstraints(defaultConstraints).minHeight;
            if (w.height - dy < minH) {
              dy = w.height - minH;
            }
          }

          for (final WindowState w in topGroup) {
            windowMap[w.id] = w.copyWith(
              height: w.height + dy,
              isMaximized: false,
            );
          }
          for (final WindowState w in bottomGroup) {
            windowMap[w.id] = w.copyWith(
              y: w.y + dy,
              height: w.height - dy,
              isMaximized: false,
            );
          }
        }
      }
    }

    // 3. Одиночный свободный ресайз
    if (!horizontalSeamHandled || !verticalSeamHandled) {
      final WindowState currentWin = windowMap[targetId] ?? win;
      final WindowConstraints targetLimits =
          currentWin.effectiveConstraints(defaultConstraints);

      double x = currentWin.x;
      double y = currentWin.y;
      double w = currentWin.width;
      double h = currentWin.height;

      if (!horizontalSeamHandled) {
        if (touchesEast) {
          w = (w + delta.dx).clamp(targetLimits.minWidth, targetLimits.maxWidth);
        }
        if (touchesWest) {
          final double newW =
              (w - delta.dx).clamp(targetLimits.minWidth, targetLimits.maxWidth);
          x += w - newW;
          w = newW;
        }
      }

      if (!verticalSeamHandled) {
        if (touchesSouth) {
          h = (h + delta.dy).clamp(targetLimits.minHeight, targetLimits.maxHeight);
        }
        if (touchesNorth) {
          final double newH =
              (h - delta.dy).clamp(targetLimits.minHeight, targetLimits.maxHeight);
          y += h - newH;
          h = newH;
        }
      }

      windowMap[targetId] = currentWin.copyWith(
        x: x,
        y: y,
        width: w,
        height: h,
        isMaximized: false,
      );
    }

    return windows.map((WindowState w) => windowMap[w.id] ?? w).toList();
  }
}