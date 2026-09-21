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
      return tileWindow(state, windowId, state.pendingSnapZone).copyWith(
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

  /// Применяет заданный режим тайлинга [zone] к окну [windowId] с сохранением плавающих габаритов.
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

    // Если окно находилось в свободном режиме, фиксируем его текущие фактические габариты
    final WorkspaceRect restore =
        (current.snapZone == SnapZone.none && !current.isMaximized)
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
    final WindowConstraints defaultConstraints =
        state.config.defaultConstraints;

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

  /// Выполняет деформацию габаритов окна с магнитным притягиванием к граням и швам.
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

    // Если активен режим масштабирования состыкованной группы по общему шву
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