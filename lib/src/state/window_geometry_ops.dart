import '../config/window_constraints.dart';
import '../engine/bounds_clamper.dart';
import '../engine/magnet_snapper.dart';
import '../engine/seam_resizer.dart';
import '../engine/snap_zone_detector.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';
import 'window_hierarchy_ops.dart';
import 'workspace_state.dart';

/// Обработчик геометрических трансформаций, тайлинга и изменения размеров окон.
class WindowGeometryOps {
  const WindowGeometryOps._();

  /// Адаптирует координаты и габариты окон при изменении размеров экрана.
  static WorkspaceState updateViewportSize(
    WorkspaceState state,
    double width,
    double height,
  ) {
    final WorkspaceRect newArea = BoundsClamper.calculateAvailableArea(
      canvasWidth: width,
      canvasHeight: height,
      dockHeight: state.config.dockHeight,
    );

    if (state.availableArea == newArea) {
      return state;
    }

    final WorkspaceRect oldArea = state.availableArea;
    final List<WindowState> adaptedWindows = state.windows
        .map(
          (WindowState w) => BoundsClamper.adaptWindowOnResize(
            window: w,
            oldArea: oldArea,
            newArea: newArea,
            globalConstraints: state.config.defaultConstraints,
          ),
        )
        .toList(growable: false);

    return state.copyWith(
      availableArea: newArea,
      windows: adaptedWindows,
      dockOrder: WindowHierarchyOps.syncDockOrder(
        state.dockOrder,
        adaptedWindows,
      ),
    );
  }

  /// Перемещает окно с вычислением магнитного захвата и оверлея тайлинга.
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
    if (current.isMaximized) {
      return untileWindow(state, windowId);
    }

    double targetX = current.x + deltaX;
    double targetY = current.y + deltaY;

    if (enableSnapping) {
      final List<WindowState> passive = state.windows
          .where((WindowState w) => w.id != windowId && !w.isMinimized)
          .toList(growable: false);

      final (double sx, double sy) = MagnetSnapper.snapPosition(
        targetX: targetX,
        targetY: targetY,
        width: current.width,
        height: current.height,
        availableArea: state.availableArea,
        otherWindows: passive,
        magnetThreshold: state.config.magnetThreshold,
        minOverlap: state.config.minEdgeOverlap,
      );
      targetX = sx;
      targetY = sy;
    }

    final (double cx, double cy) = BoundsClamper.clampWindowPosition(
      targetX: targetX,
      targetY: targetY,
      windowWidth: current.width,
      windowHeight: current.height,
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
        windowRect: WorkspaceRect(
          x: cx,
          y: cy,
          width: current.width,
          height: current.height,
        ),
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
      snapZone: SnapZone.none,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
      pendingSnapZone: detectedZone,
      snapPreviewRect: previewRect,
      clearSnapPreview: previewRect == null,
    );
  }

  /// Фиксирует позицию окна по завершении жеста перетаскивания (Commit Phase).
  static WorkspaceState commitMove(WorkspaceState state, String windowId) {
    if (state.pendingSnapZone != SnapZone.none) {
      return tileWindow(state, windowId, state.pendingSnapZone).copyWith(
        pendingSnapZone: SnapZone.none,
        clearSnapPreview: true,
      );
    }

    return state.copyWith(
      pendingSnapZone: SnapZone.none,
      clearSnapPreview: true,
    );
  }

  /// Применяет заданный режим тайлинга [zone] к окну [windowId].
  static WorkspaceState tileWindow(
    WorkspaceState state,
    String windowId,
    SnapZone zone,
  ) {
    if (zone == SnapZone.none) {
      return untileWindow(state, windowId);
    }

    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    final WorkspaceRect? targetRect = SnapZoneDetector.calculatePreviewRect(
      zone: zone,
      availableArea: state.availableArea,
    );

    if (targetRect == null) {
      return state;
    }

    final WorkspaceRect restore = (current.snapZone == SnapZone.none &&
            !current.isMaximized &&
            current.restoreRect == null)
        ? current.rect
        : (current.restoreRect ?? current.rect);

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = current.copyWith(
      x: targetRect.x,
      y: targetRect.y,
      width: targetRect.width,
      height: targetRect.height,
      snapZone: zone,
      isMaximized: zone.isMaximize,
      isMinimized: false,
      restoreRect: restore,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
    );
  }

  /// Сбрасывает тайлинг и восстанавливает плавающую геометрию окна.
  static WorkspaceState untileWindow(WorkspaceState state, String windowId) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    final WindowConstraints defaultConstraints = state.config.defaultConstraints;

    final WorkspaceRect fallbackRect = WorkspaceRect(
      x: state.availableArea.left + 40.0,
      y: state.availableArea.top + 40.0,
      width: defaultConstraints.clampWidth(480.0),
      height: defaultConstraints.clampHeight(320.0),
    );

    final WorkspaceRect target = current.restoreRect ?? fallbackRect;

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = current.copyWith(
      x: target.x,
      y: target.y,
      width: target.width,
      height: target.height,
      snapZone: SnapZone.none,
      isMaximized: false,
      restoreRect: null,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
    );
  }

  /// Выполняет деформацию габаритов окна по ортогональным и диагональным векторам.
  static WorkspaceState resizeWindow({
    required WorkspaceState state,
    required String windowId,
    required ResizeDirection direction,
    required double deltaX,
    required double deltaY,
    required bool enableSeamResizing,
  }) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1 || direction == ResizeDirection.none) {
      return state;
    }

    final WindowState primary = state.windows[index];

    if (enableSeamResizing) {
      final List<WindowState> resized = SeamResizer.resizeSeam(
        primaryWindow: primary,
        allWindows: state.windows,
        direction: direction,
        deltaX: deltaX,
        deltaY: deltaY,
        seamEpsilon: state.config.seamEpsilon,
        minSeamOverlap: state.config.minSeamOverlap,
        globalConstraints: state.config.defaultConstraints,
      );

      return state.copyWith(
        windows: resized,
        focusedWindowId: windowId,
      );
    }

    final WindowConstraints constraints =
        primary.resolveEffectiveConstraints(state.config.defaultConstraints);

    double newX = primary.x;
    double newY = primary.y;
    double newW = primary.width;
    double newH = primary.height;

    if (direction.affectsRight) {
      newW = constraints.clampWidth(primary.width + deltaX);
    } else if (direction.affectsLeft) {
      final double targetW = primary.width - deltaX;
      newW = constraints.clampWidth(targetW);
      newX = primary.x + (primary.width - newW);
    }

    if (direction.affectsBottom) {
      newH = constraints.clampHeight(primary.height + deltaY);
    } else if (direction.affectsTop) {
      final double targetH = primary.height - deltaY;
      newH = constraints.clampHeight(targetH);
      newY = primary.y + (primary.height - newH);
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = primary.copyWith(
      x: newX,
      y: newY,
      width: newW,
      height: newH,
      snapZone: SnapZone.none,
    );

    return state.copyWith(
      windows: updated,
      focusedWindowId: windowId,
    );
  }

  /// Переключает развертывание окна во весь экран.
  static WorkspaceState toggleMaximizeWindow(
    WorkspaceState state,
    String windowId,
  ) {
    final WindowState? win = state.windows
        .where((WindowState w) => w.id == windowId)
        .firstOrNull;
    if (win == null) {
      return state;
    }

    if (win.isMaximized || win.snapZone == SnapZone.maximize) {
      return untileWindow(state, windowId);
    }
    return tileWindow(state, windowId, SnapZone.maximize);
  }
}