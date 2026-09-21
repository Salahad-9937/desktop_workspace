import '../config/window_constraints.dart';
import '../engine/snap_zone_detector.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';
import 'workspace_state.dart';

/// Операции тайлинга, максимизации и возврата к плавающим габаритам.
class WindowTileOps {
  const WindowTileOps._();

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