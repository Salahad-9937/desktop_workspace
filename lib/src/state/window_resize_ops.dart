import '../config/window_constraints.dart';
import '../engine/magnet_snapper.dart';
import '../engine/seam_resizer.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';
import 'workspace_state.dart';

/// Операции изменения габаритов окон, магнитного притягивания ребер и общего шва.
class WindowResizeOps {
  const WindowResizeOps._();

  /// Выполняет деформацию габаритов окна с магнитным притягиванием к граням, швам и долям холста.
  static WorkspaceState resizeWindow({
    required WorkspaceState state,
    required String windowId,
    required ResizeDirection direction,
    required double deltaX,
    required double deltaY,
    required bool enableSeamResizing,
    bool enableSnapping = true,
  }) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1 || direction == ResizeDirection.none) {
      return state;
    }

    final WindowState primary = state.windows[index];

    // Масштабирование состыкованной группы по общему шву с примагничиванием к долям холста
    if (enableSeamResizing) {
      double effectiveDeltaX = deltaX;
      double effectiveDeltaY = deltaY;

      double? nextRawX = state.rawDragX;
      double? nextRawY = state.rawDragY;

      if (enableSnapping) {
        const double magnetThreshold = 14.0;

        // Магнитный захват вертикального шва (X) к долям холста: 50%, 33.3%, 66.6%, 25%, 75%
        if (direction.affectsLeft || direction.affectsRight) {
          final double seamX = direction.affectsRight
              ? primary.rect.right
              : primary.rect.left;
          final double rawX = (state.rawDragX ?? seamX) + deltaX;
          nextRawX = rawX;

          final double w = state.availableArea.width;
          final List<double> snapTargetsX = <double>[
            w * 0.5,
            w * (1.0 / 3.0),
            w * (2.0 / 3.0),
            w * 0.25,
            w * 0.75,
          ];

          double targetX = rawX;
          for (final double snapPoint in snapTargetsX) {
            if ((rawX - snapPoint).abs() < magnetThreshold) {
              targetX = snapPoint;
              break;
            }
          }
          effectiveDeltaX = targetX - seamX;
        }

        // Магнитный захват горизонтального шва (Y) к долям холста
        if (direction.affectsTop || direction.affectsBottom) {
          final double seamY = direction.affectsBottom
              ? primary.rect.bottom
              : primary.rect.top;
          final double rawY = (state.rawDragY ?? seamY) + deltaY;
          nextRawY = rawY;

          final double h = state.availableArea.height;
          final List<double> snapTargetsY = <double>[
            h * 0.5,
            h * (1.0 / 3.0),
            h * (2.0 / 3.0),
            h * 0.25,
            h * 0.75,
          ];

          double targetY = rawY;
          for (final double snapPoint in snapTargetsY) {
            if ((rawY - snapPoint).abs() < magnetThreshold) {
              targetY = snapPoint;
              break;
            }
          }
          effectiveDeltaY = targetY - seamY;
        }
      }

      final List<WindowState> resized = SeamResizer.resizeSeam(
        primaryWindow: primary,
        allWindows: state.windows,
        direction: direction,
        deltaX: effectiveDeltaX,
        deltaY: effectiveDeltaY,
        seamEpsilon: state.config.seamEpsilon,
        minSeamOverlap: state.config.minSeamOverlap,
        globalConstraints: state.config.defaultConstraints,
      );

      // Сохраняем текущий активный фокус окна без принудительной смены на ведущее окно шва
      return state.copyWith(
        windows: resized,
        focusedWindowId: state.focusedWindowId,
        rawDragX: nextRawX,
        rawDragY: nextRawY,
      );
    }

    // Одиночная модификация габаритов конкретного окна
    final WindowConstraints constraints =
        primary.resolveEffectiveConstraints(state.config.defaultConstraints);

    final List<WindowState> passive = state.windows
        .where((WindowState w) => w.id != windowId && !w.isMinimized)
        .toList(growable: false);

    double newX = primary.x;
    double newY = primary.y;
    double newW = primary.width;
    double newH = primary.height;

    double? nextRawDragX = state.rawDragX;
    double? nextRawDragY = state.rawDragY;

    if (direction.affectsRight) {
      final double rawRight =
          (state.rawDragX ?? (primary.x + primary.width)) + deltaX;
      nextRawDragX = rawRight;

      double targetRight = rawRight;
      if (enableSnapping) {
        targetRight = MagnetSnapper.snapResizeEdge(
          rawEdge: rawRight,
          direction: ResizeDirection.east,
          currentRect: primary.rect,
          availableArea: state.availableArea,
          otherWindows: passive,
          magnetThreshold: state.config.magnetThreshold,
          minOverlap: state.config.minEdgeOverlap,
        );
      }
      newW = constraints.clampWidth(targetRight - primary.x);
    } else if (direction.affectsLeft) {
      final double rawLeft = (state.rawDragX ?? primary.x) + deltaX;
      nextRawDragX = rawLeft;

      double targetLeft = rawLeft;
      if (enableSnapping) {
        targetLeft = MagnetSnapper.snapResizeEdge(
          rawEdge: rawLeft,
          direction: ResizeDirection.west,
          currentRect: primary.rect,
          availableArea: state.availableArea,
          otherWindows: passive,
          magnetThreshold: state.config.magnetThreshold,
          minOverlap: state.config.minEdgeOverlap,
        );
      }
      final double targetW = (primary.x + primary.width) - targetLeft;
      newW = constraints.clampWidth(targetW);
      newX = (primary.x + primary.width) - newW;
    }

    if (direction.affectsBottom) {
      final double rawBottom =
          (state.rawDragY ?? (primary.y + primary.height)) + deltaY;
      nextRawDragY = rawBottom;

      double targetBottom = rawBottom;
      if (enableSnapping) {
        targetBottom = MagnetSnapper.snapResizeEdge(
          rawEdge: rawBottom,
          direction: ResizeDirection.south,
          currentRect: primary.rect,
          availableArea: state.availableArea,
          otherWindows: passive,
          magnetThreshold: state.config.magnetThreshold,
          minOverlap: state.config.minEdgeOverlap,
        );
      }
      newH = constraints.clampHeight(targetBottom - primary.y);
    } else if (direction.affectsTop) {
      final double rawTop = (state.rawDragY ?? primary.y) + deltaY;
      nextRawDragY = rawTop;

      double targetTop = rawTop;
      if (enableSnapping) {
        targetTop = MagnetSnapper.snapResizeEdge(
          rawEdge: rawTop,
          direction: ResizeDirection.north,
          currentRect: primary.rect,
          availableArea: state.availableArea,
          otherWindows: passive,
          magnetThreshold: state.config.magnetThreshold,
          minOverlap: state.config.minEdgeOverlap,
        );
      }
      final double targetH = (primary.y + primary.height) - targetTop;
      newH = constraints.clampHeight(targetH);
      newY = (primary.y + primary.height) - newH;
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = primary.copyWith(
      x: newX,
      y: newY,
      width: newW,
      height: newH,
      snapZone: SnapZone.none,
      restoreRect: null,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
      rawDragX: nextRawDragX,
      rawDragY: nextRawDragY,
    );
  }

  /// Завершает интерактивную фазу изменения размеров окна со сбросом аккумулятора магнита.
  static WorkspaceState commitResize(WorkspaceState state) {
    return state.copyWith(clearRawDrag: true);
  }
}