import '../config/window_constraints.dart';
import '../engine/bounds_clamper.dart';
import '../engine/magnet_snapper.dart';
import '../engine/snap_zone_detector.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';
import 'window_tile_ops.dart';
import 'workspace_state.dart';

/// Операции свободного перемещения окон, отрыва от магнита и срыва тайлинга.
class WindowMoveOps {
  const WindowMoveOps._();

  /// Перемещает окно с детерминированным расчетом отрыва от магнита и срывом тайлинга.
  static WorkspaceState moveWindow({
    required WorkspaceState state,
    required String windowId,
    required double deltaX,
    required double deltaY,
    required bool enableSnapping,
    required bool enableTilingDetection,
    double? pointerX,
    double? pointerY,
  }) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    final bool isTiledOrMaximized =
        current.isMaximized || current.snapZone != SnapZone.none;

    double targetWidth = current.width;
    double targetHeight = current.height;
    WorkspaceRect? restoredRect = current.restoreRect;

    double rawX;
    double rawY;

    // Срыв тайлинга: восстанавливаем точный размер окна, зафиксированный до входа в тайлинг
    if (isTiledOrMaximized) {
      final WindowConstraints defaultConstraints =
          state.config.defaultConstraints;

      final WorkspaceRect fallbackRect = WorkspaceRect(
        x: state.availableArea.left + 40.0,
        y: state.availableArea.top + 40.0,
        width: defaultConstraints.clampWidth(480.0),
        height: defaultConstraints.clampHeight(320.0),
      );

      final WorkspaceRect targetRestore = current.restoreRect ?? fallbackRect;
      targetWidth = targetRestore.width;
      targetHeight = targetRestore.height;

      if (pointerX != null && pointerY != null) {
        rawX = pointerX - (targetWidth / 2.0);
        rawY = pointerY - (state.config.headerHeight / 2.0);
      } else {
        rawX = current.x + deltaX;
        rawY = current.y + deltaY;
      }

      restoredRect = null;
    } else {
      rawX = (state.rawDragX ?? current.x) + deltaX;
      rawY = (state.rawDragY ?? current.y) + deltaY;
    }

    double snappedX = rawX;
    double snappedY = rawY;

    if (enableSnapping) {
      final List<WindowState> passive = state.windows
          .where((WindowState w) => w.id != windowId && !w.isMinimized)
          .toList(growable: false);

      final (double sx, double sy) = MagnetSnapper.snapPosition(
        targetX: rawX,
        targetY: rawY,
        width: targetWidth,
        height: targetHeight,
        availableArea: state.availableArea,
        otherWindows: passive,
        magnetThreshold: state.config.magnetThreshold,
        minOverlap: state.config.minEdgeOverlap,
      );
      snappedX = sx;
      snappedY = sy;
    }

    final (double cx, double cy) = BoundsClamper.clampWindowPosition(
      targetX: snappedX,
      targetY: snappedY,
      windowWidth: targetWidth,
      windowHeight: targetHeight,
      availableArea: state.availableArea,
      headerHeight: state.config.headerHeight,
      minVisibleWidth: state.config.minVisibleHeaderWidth,
    );

    SnapZone detectedZone = SnapZone.none;
    WorkspaceRect? previewRect;

    if (enableTilingDetection && pointerX != null && pointerY != null) {
      detectedZone = SnapZoneDetector.detectZone(
        pointerX: pointerX,
        pointerY: pointerY,
        availableArea: state.availableArea,
        edgeThreshold: state.config.edgeTilingThreshold,
      );
      previewRect = SnapZoneDetector.calculatePreviewRect(
        zone: detectedZone,
        availableArea: state.availableArea,
      );
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = current.copyWith(
      x: cx,
      y: cy,
      width: targetWidth,
      height: targetHeight,
      snapZone: SnapZone.none,
      isMaximized: false,
      restoreRect: restoredRect,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
      pendingSnapZone: detectedZone,
      snapPreviewRect: previewRect,
      clearSnapPreview: previewRect == null,
      rawDragX: rawX,
      rawDragY: rawY,
    );
  }

  /// Фиксирует позицию окна по завершении жеста перетаскивания (Commit Phase).
  static WorkspaceState commitMove(WorkspaceState state, String windowId) {
    if (state.pendingSnapZone != SnapZone.none) {
      return WindowTileOps.tileWindow(
        state,
        windowId,
        state.pendingSnapZone,
      ).copyWith(
        pendingSnapZone: SnapZone.none,
        clearSnapPreview: true,
        clearRawDrag: true,
      );
    }

    return state.copyWith(
      pendingSnapZone: SnapZone.none,
      clearSnapPreview: true,
      clearRawDrag: true,
    );
  }
}