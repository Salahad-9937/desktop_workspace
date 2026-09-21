import 'dart:math' as math;

import '../config/window_constraints.dart';
import '../engine/bounds_clamper.dart';
import '../engine/layout_generator.dart';
import '../model/view_definition.dart';
import '../model/window_state.dart';
import '../model/workspace_profile.dart';
import '../model/workspace_tab.dart';
import 'window_hierarchy_ops.dart';
import 'workspace_state.dart';

/// Обработчик компоновок холста, стартовых сеток, профилей и каталога панелей.
class WorkspaceLayoutOps {
  const WorkspaceLayoutOps._();

  /// Открывает панель из каталога без деструкции существующих окон.
  static WorkspaceState openView(
    WorkspaceState state, {
    required ViewDefinition definition,
    Map<String, dynamic>? payload,
  }) {
    // 1. Активация существующего окна для сингулярных представлений
    if (definition.strategy == ViewInstanceStrategy.singleton) {
      for (final WindowState win in state.windows) {
        final int tabIndex = win.tabs.indexWhere(
          (WorkspaceTab t) => t.typeId == definition.typeId,
        );
        if (tabIndex != -1) {
          WorkspaceState targetState = state;
          if (win.isMinimized) {
            targetState = WindowHierarchyOps.restoreWindow(targetState, win.id);
          }
          if (win.activeTabIndex != tabIndex) {
            final List<WindowState> updated =
                List<WindowState>.of(targetState.windows);
            final int winIdx = updated.indexWhere((w) => w.id == win.id);
            if (winIdx != -1) {
              updated[winIdx] = updated[winIdx].copyWith(activeTabIndex: tabIndex);
              targetState = targetState.copyWith(windows: updated);
            }
          }
          return WindowHierarchyOps.focusWindow(targetState, win.id);
        }
      }
    }

    // 2. Инстанцирование нового плавающего окна на холсте
    final WindowConstraints constraints =
        definition.constraints ?? state.config.defaultConstraints;

    final double width = constraints.clampWidth(480.0);
    final double height = constraints.clampHeight(340.0);

    final double offsetStep = (state.windows.length % 6) * 32.0;
    final double initialX = state.availableArea.left + 64.0 + offsetStep;
    final double initialY = state.availableArea.top + 48.0 + offsetStep;

    final (double cx, double cy) = BoundsClamper.clampWindowPosition(
      targetX: initialX,
      targetY: initialY,
      windowWidth: width,
      windowHeight: height,
      availableArea: state.availableArea,
      headerHeight: state.config.headerHeight,
      minVisibleWidth: state.config.minVisibleHeaderWidth,
    );

    final int now = DateTime.now().microsecondsSinceEpoch;
    final String newWindowId = 'win_${definition.typeId}_$now';

    final WindowState newWindow = WindowState(
      id: newWindowId,
      x: cx,
      y: cy,
      width: width,
      height: height,
      tabs: <WorkspaceTab>[
        definition.toTab(payload: payload),
      ],
      activeTabIndex: 0,
      createdAt: now,
    );

    final List<WindowState> updatedWindows = List<WindowState>.of(state.windows)
      ..add(newWindow);
    final List<WindowState> reordered = WindowHierarchyOps.reorderWithTierFocus(
      updatedWindows,
      newWindowId,
    );

    final List<String> updatedDockOrder = List<String>.of(state.dockOrder)
      ..add(newWindowId);

    return state.copyWith(
      windows: reordered,
      focusedWindowId: newWindowId,
      dockOrder: updatedDockOrder,
      clearSoloWindow: state.isSoloMode,
    );
  }

  /// Применяет декларативный макет регулярной сетки 2x2.
  static WorkspaceState applyPresetGrid(
    WorkspaceState state,
    List<List<WorkspaceTab>> slotsTabs,
  ) {
    final List<WindowState> grid = LayoutGenerator.generateGrid2x2(
      availableArea: state.availableArea,
      slotsTabs: slotsTabs,
    );

    return state.copyWith(
      windows: grid,
      focusedWindowId: grid.firstOrNull?.id,
      clearSoloWindow: true,
      dockOrder: grid.map((WindowState w) => w.id).toList(),
    );
  }

  /// Применяет декларативный макет пропорционального сплита.
  static WorkspaceState applyPresetSplit(
    WorkspaceState state, {
    required List<List<WorkspaceTab>> windowsTabs,
    SplitOrientation orientation = SplitOrientation.horizontal,
    double splitRatio = 0.5,
  }) {
    if (windowsTabs.length < 2) {
      return state;
    }

    final List<WindowState> split = LayoutGenerator.generateSplit(
      availableArea: state.availableArea,
      primaryTabs: windowsTabs[0],
      secondaryTabs: windowsTabs[1],
      orientation: orientation,
      splitRatio: splitRatio,
    );

    return state.copyWith(
      windows: split,
      focusedWindowId: split.firstOrNull?.id,
      clearSoloWindow: true,
      dockOrder: split.map((WindowState w) => w.id).toList(),
    );
  }

  /// Применяет макет одиночного окна.
  static WorkspaceState applyPresetSolo(
    WorkspaceState state,
    List<WorkspaceTab> tabs,
  ) {
    final List<WindowState> solo = LayoutGenerator.generateSolo(
      availableArea: state.availableArea,
      tabs: tabs,
    );

    return state.copyWith(
      windows: solo,
      focusedWindowId: solo.firstOrNull?.id,
      clearSoloWindow: true,
      dockOrder: solo.map((WindowState w) => w.id).toList(),
    );
  }

  /// Восстанавливает окна из именованного профиля раскладки.
  static WorkspaceState applyProfile(
    WorkspaceState state,
    WorkspaceProfile profile,
  ) {
    final double w = state.availableArea.width;
    final double h = state.availableArea.height;
    final double x0 = state.availableArea.left;
    final double y0 = state.availableArea.top;

    final List<WindowState> restored = profile.placements
        .map(
          (RelativeWindowPlacement p) => WindowState(
            id: p.windowId,
            x: x0 + (p.relativeX * w),
            y: y0 + (p.relativeY * h),
            width: p.relativeWidth * w,
            height: p.relativeHeight * h,
            tabs: p.tabs,
            activeTabIndex: p.activeTabIndex,
            isPinnedOnTop: p.isPinnedOnTop,
            isMinimized: p.isMinimized,
            isMaximized: p.isMaximized,
            snapZone: p.snapZone,
          ),
        )
        .toList(growable: false);

    return state.copyWith(
      windows: restored,
      focusedWindowId: restored.firstOrNull?.id,
      clearSoloWindow: true,
      dockOrder: restored.map((WindowState w) => w.id).toList(),
    );
  }

  /// Фиксирует текущую компоновку окон в именованный профиль.
  static WorkspaceProfile createCurrentProfile(
    WorkspaceState state, {
    required String id,
    required String name,
    bool isFactory = false,
  }) {
    final double w = math.max(1.0, state.availableArea.width);
    final double h = math.max(1.0, state.availableArea.height);
    final double x0 = state.availableArea.left;
    final double y0 = state.availableArea.top;

    final List<RelativeWindowPlacement> placements = state.windows
        .map(
          (WindowState win) => RelativeWindowPlacement(
            windowId: win.id,
            relativeX: (win.x - x0) / w,
            relativeY: (win.y - y0) / h,
            relativeWidth: win.width / w,
            relativeHeight: win.height / h,
            tabs: win.tabs,
            activeTabIndex: win.activeTabIndex,
            isPinnedOnTop: win.isPinnedOnTop,
            isMinimized: win.isMinimized,
            isMaximized: win.isMaximized,
            snapZone: win.snapZone,
          ),
        )
        .toList(growable: false);

    return WorkspaceProfile(
      id: id,
      name: name,
      isFactory: isFactory,
      placements: placements,
    );
  }
}