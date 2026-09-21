import '../engine/bounds_clamper.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';
import 'window_hierarchy_ops.dart';
import 'window_move_ops.dart';
import 'window_resize_ops.dart';
import 'window_tile_ops.dart';
import 'workspace_state.dart';

/// Фасад геометрических трансформаций, адаптации видового экрана, перемещения и изменения размеров окон.
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

  /// Делегирует перемещение окна модулю [WindowMoveOps].
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
    return WindowMoveOps.moveWindow(
      state: state,
      windowId: windowId,
      deltaX: deltaX,
      deltaY: deltaY,
      enableSnapping: enableSnapping,
      enableTilingDetection: enableTilingDetection,
      pointerX: pointerX,
      pointerY: pointerY,
    );
  }

  /// Делегирует фиксацию перемещения модулю [WindowMoveOps].
  static WorkspaceState commitMove(WorkspaceState state, String windowId) {
    return WindowMoveOps.commitMove(state, windowId);
  }

  /// Делегирует тайлинг окна модулю [WindowTileOps].
  static WorkspaceState tileWindow(
    WorkspaceState state,
    String windowId,
    SnapZone zone,
  ) {
    return WindowTileOps.tileWindow(state, windowId, zone);
  }

  /// Делегирует сброс тайлинга модулю [WindowTileOps].
  static WorkspaceState untileWindow(WorkspaceState state, String windowId) {
    return WindowTileOps.untileWindow(state, windowId);
  }

  /// Делегирует переключение развертывания окна модулю [WindowTileOps].
  static WorkspaceState toggleMaximizeWindow(
    WorkspaceState state,
    String windowId,
  ) {
    return WindowTileOps.toggleMaximizeWindow(state, windowId);
  }

  /// Делегирует масштабирование окна модулю [WindowResizeOps].
  static WorkspaceState resizeWindow({
    required WorkspaceState state,
    required String windowId,
    required ResizeDirection direction,
    required double deltaX,
    required double deltaY,
    required bool enableSeamResizing,
    bool enableSnapping = true,
  }) {
    return WindowResizeOps.resizeWindow(
      state: state,
      windowId: windowId,
      direction: direction,
      deltaX: deltaX,
      deltaY: deltaY,
      enableSeamResizing: enableSeamResizing,
      enableSnapping: enableSnapping,
    );
  }

  /// Делегирует завершение изменения размеров модулю [WindowResizeOps].
  static WorkspaceState commitResize(WorkspaceState state) {
    return WindowResizeOps.commitResize(state);
  }
}