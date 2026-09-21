import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';
import '../../model/tab_drag_payload.dart';
import '../../model/view_definition.dart';
import '../../model/window_state.dart';
import '../../state/workspace_controller.dart';
import '../window/window_frame.dart';

/// Визуальный слой отрисовки группы оконных фреймов определенного яруса.
class CanvasWindowLayer extends StatelessWidget {
  /// Список окон целевого яруса.
  final List<WindowState> windows;

  /// Идентификатор сфокусированного окна.
  final String? focusedWindowId;

  /// Реестр зарегистрированных прикладных представлений.
  final Map<String, ViewDefinition> registeredViews;

  /// Фабрика контента по умолчанию.
  final WorkspaceContentBuilder? fallbackBuilder;

  /// Контроллер рабочего пространства.
  final WorkspaceController controller;

  /// Создает экземпляр [CanvasWindowLayer].
  const CanvasWindowLayer({
    super.key,
    required this.windows,
    required this.focusedWindowId,
    required this.registeredViews,
    this.fallbackBuilder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final WindowState win in windows)
          WindowFrame(
            key: ValueKey<String>(win.id),
            window: win,
            isFocused: win.id == focusedWindowId,
            registeredViews: registeredViews,
            fallbackBuilder: fallbackBuilder,
            onFocus: () => controller.focusWindow(win.id),
            onMove: (
              double dx,
              double dy,
              Offset pointer,
            ) {
              controller.moveWindow(
                windowId: win.id,
                deltaX: dx,
                deltaY: dy,
                pointerX: pointer.dx,
                pointerY: pointer.dy,
              );
            },
            onMoveEnd: () => controller.commitMove(win.id),
            onResize: (
              ResizeDirection dir,
              double dx,
              double dy,
            ) {
              controller.resizeWindow(
                windowId: win.id,
                direction: dir,
                deltaX: dx,
                deltaY: dy,
                enableSeamResizing: false,
              );
            },
            onResizeEnd: () => controller.commitResize(),
            onToggleMaximize: () => controller.toggleMaximizeWindow(win.id),
            onSelectTab: (int idx) => controller.selectTab(win.id, idx),
            onCloseTab: (String tId) => controller.closeTab(
              windowId: win.id,
              tabId: tId,
            ),
            onDuplicateTab: (String tId) => controller.duplicateTab(
              windowId: win.id,
              tabId: tId,
            ),
            onTabDropped: (TabDragPayload p, int? dropIndex) =>
                controller.dropTabOnWindow(
              payload: p,
              targetWindowId: win.id,
              insertIndex: dropIndex,
            ),
            onTogglePin: () => controller.togglePinWindow(win.id),
            onTileSelect: (SnapZone z) => controller.tileWindow(win.id, z),
            onMinimize: () => controller.minimizeWindow(win.id),
            onCloseWindow: () => controller.closeWindow(win.id),
          ),
      ],
    );
  }
}