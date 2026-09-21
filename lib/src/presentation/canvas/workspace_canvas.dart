import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/bounds_clamper.dart';
import '../../model/geometry_types.dart';
import '../../model/tab_drag_payload.dart';
import '../../model/view_definition.dart';
import '../../model/window_state.dart';
import '../../state/workspace_controller.dart';
import '../../state/workspace_state.dart';
import '../dock/workspace_dock.dart';
import '../window/window_frame.dart';
import 'canvas_background.dart';
import 'canvas_window_layer.dart';
import 'shared_seam_overlay.dart';
import 'snap_dock_guides.dart';
import 'snap_preview_box.dart';

/// Главный композитный холст модульного рабочего пространства.
class WorkspaceCanvas extends ConsumerWidget {
  /// Зарегистрированные определения представлений каталога.
  final List<ViewDefinition> views;

  /// Фабрика сборки контента по умолчанию.
  final WorkspaceContentBuilder? fallbackBuilder;

  /// Отображать ли встроенную док-панель.
  final bool showDock;

  /// Ведущий слот док-панели.
  final Widget? dockLeading;

  /// Ведомый слот док-панели.
  final Widget? dockTrailing;

  /// Создает экземпляр [WorkspaceCanvas].
  const WorkspaceCanvas({
    super.key,
    this.views = const <ViewDefinition>[],
    this.fallbackBuilder,
    this.showDock = true,
    this.dockLeading,
    this.dockTrailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkspaceState state = ref.watch(workspaceControllerProvider);
    final WorkspaceController controller =
        ref.read(workspaceControllerProvider.notifier);

    final Map<String, ViewDefinition> registeredViewsMap =
        <String, ViewDefinition>{
      for (final ViewDefinition v in views) v.typeId: v,
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final WorkspaceRect currentArea = BoundsClamper.calculateAvailableArea(
          canvasWidth: constraints.maxWidth,
          canvasHeight: constraints.maxHeight,
          dockHeight: state.config.dockHeight,
        );

        if (state.availableArea != currentArea) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(workspaceControllerProvider.notifier).updateViewportSize(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
          });
        }

        final WorkspaceRect activeArea =
            (state.availableArea.width > 0.0 && state.availableArea.height > 0.0)
                ? state.availableArea
                : currentArea;

        return Scaffold(
          body: Column(
            children: <Widget>[
              Expanded(
                child: DragTarget<TabDragPayload>(
                  onAcceptWithDetails:
                      (DragTargetDetails<TabDragPayload> details) {
                    controller.detachTabToNewWindow(
                      payload: details.data,
                      dropX: details.offset.dx,
                      dropY: details.offset.dy,
                    );
                  },
                  builder: (
                    BuildContext context,
                    List<TabDragPayload?> candidateData,
                    List<dynamic> rejectedData,
                  ) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // Слой 0: Фоновый слой
                        const CanvasBackground(),
                        // Слой 1: Направляющие линии тайлинга
                        SnapDockGuides(
                          availableArea: activeArea,
                          activeZone: state.pendingSnapZone,
                        ),
                        // Режим сольного фокуса (Solo Mode)
                        if (state.isSoloMode && state.soloWindow != null)
                          WindowFrame(
                            window: state.soloWindow!.copyWith(
                              x: activeArea.left,
                              y: activeArea.top,
                              width: activeArea.width,
                              height: activeArea.height,
                              isMaximized: true,
                            ),
                            isFocused: true,
                            registeredViews: registeredViewsMap,
                            fallbackBuilder: fallbackBuilder,
                            onFocus: () {},
                            onMove: (_, __, ___) {},
                            onMoveEnd: () {},
                            onResize: (_, __, ___) {},
                            onResizeEnd: () {},
                            onToggleMaximize: () =>
                                controller.toggleSoloMode(state.soloWindow!.id),
                            onSelectTab: (int idx) => controller.selectTab(
                              state.soloWindow!.id,
                              idx,
                            ),
                            onCloseTab: (String tId) => controller.closeTab(
                              windowId: state.soloWindow!.id,
                              tabId: tId,
                            ),
                            onDuplicateTab: (String tId) =>
                                controller.duplicateTab(
                              windowId: state.soloWindow!.id,
                              tabId: tId,
                            ),
                            onTabDropped: (_, __) {},
                            onTogglePin: () {},
                            onTileSelect: (_) {},
                            onMinimize: () =>
                                controller.toggleSoloMode(state.soloWindow!.id),
                            onCloseWindow: () =>
                                controller.toggleSoloMode(state.soloWindow!.id),
                          )
                        else ...<Widget>[
                          // Слой 2: Окна стандартного яруса
                          CanvasWindowLayer(
                            windows: state.standardWindows,
                            focusedWindowId: state.focusedWindowId,
                            registeredViews: registeredViewsMap,
                            fallbackBuilder: fallbackBuilder,
                            controller: controller,
                          ),
                          // Слой 3: Окна приоритетного яруса (Always-on-Top)
                          CanvasWindowLayer(
                            windows: state.pinnedWindows,
                            focusedWindowId: state.focusedWindowId,
                            registeredViews: registeredViewsMap,
                            fallbackBuilder: fallbackBuilder,
                            controller: controller,
                          ),
                          // Слой 4: Интерактивный оверлей единых общих швов и перекрестков
                          SharedSeamOverlay(
                            windows: state.windows,
                            focusedWindowId: state.focusedWindowId,
                            seamEpsilon: state.config.seamEpsilon,
                            minSeamOverlap: state.config.minSeamOverlap,
                            onResizeSeam: (
                              String wId,
                              ResizeDirection dir,
                              double dx,
                              double dy,
                            ) {
                              controller.resizeWindow(
                                windowId: wId,
                                direction: dir,
                                deltaX: dx,
                                deltaY: dy,
                                enableSeamResizing: true,
                              );
                            },
                            onResizeEnd: () => controller.commitResize(),
                          ),
                        ],
                        // Слой 5: Оверлей предпросмотра тайлинга
                        SnapPreviewBox(
                          targetRect: state.snapPreviewRect,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (showDock)
                WorkspaceDock(
                  windows: state.windows,
                  focusedWindowId: state.focusedWindowId,
                  dockOrder: state.dockOrder,
                  leading: dockLeading,
                  trailing: dockTrailing,
                  onWindowTap: (String wId) {
                    final WindowState target = state.windows
                        .firstWhere((WindowState w) => w.id == wId);
                    if (target.isMinimized) {
                      controller.restoreWindow(wId);
                    } else if (state.focusedWindowId == wId) {
                      controller.minimizeWindow(wId);
                    } else {
                      controller.focusWindow(wId);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}