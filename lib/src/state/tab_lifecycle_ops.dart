import '../config/window_constraints.dart';
import '../engine/bounds_clamper.dart';
import '../model/tab_drag_payload.dart';
import '../model/window_state.dart';
import '../model/workspace_tab.dart';
import 'window_hierarchy_ops.dart';
import 'workspace_state.dart';

/// Обработчик жизненного цикла вкладок и механизма Drag-and-Drop (Tear-off / Merging).
class TabLifecycleOps {
  const TabLifecycleOps._();

  /// Выбирает активную вкладку окна с адаптацией ограничений.
  static WorkspaceState selectTab(
    WorkspaceState state,
    String windowId,
    int tabIndex,
  ) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    if (tabIndex < 0 || tabIndex >= current.tabs.length) {
      return state;
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    final WindowState target = current.copyWith(activeTabIndex: tabIndex);

    final WindowConstraints constraints =
        target.resolveEffectiveConstraints(state.config.defaultConstraints);

    final double clampedW = constraints.clampWidth(target.width);
    final double clampedH = constraints.clampHeight(target.height);

    updated[index] = target.copyWith(
      width: clampedW,
      height: clampedH,
    );

    final List<WindowState> reordered = WindowHierarchyOps.reorderWithTierFocus(
      updated,
      windowId,
    );

    return state.copyWith(
      windows: reordered,
      focusedWindowId: windowId,
    );
  }

  /// Закрывает вкладку с каскадным схлопыванием контейнера при опустошении.
  static WorkspaceState closeTab(
    WorkspaceState state,
    String windowId,
    String tabId,
  ) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    final List<WorkspaceTab> remainingTabs = current.tabs
        .where((WorkspaceTab t) => t.id != tabId)
        .toList(growable: false);

    if (remainingTabs.isEmpty) {
      return WindowHierarchyOps.closeWindow(state, windowId);
    }

    final int newActiveIndex =
        current.activeTabIndex.clamp(0, remainingTabs.length - 1);

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = current.copyWith(
      tabs: remainingTabs,
      activeTabIndex: newActiveIndex,
    );

    return state.copyWith(windows: updated);
  }

  /// Создает независимую копию вкладки с дублированием данных.
  static WorkspaceState duplicateTab(
    WorkspaceState state,
    String windowId,
    String tabId,
  ) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState current = state.windows[index];
    final int tabIndex =
        current.tabs.indexWhere((WorkspaceTab t) => t.id == tabId);
    if (tabIndex == -1) {
      return state;
    }

    final WorkspaceTab original = current.tabs[tabIndex];
    final WorkspaceTab clone = original.copyWith(
      id: '${original.typeId}_copy_${DateTime.now().microsecondsSinceEpoch}',
      title: '${original.title} (Копия)',
      payload: original.payload != null
          ? Map<String, dynamic>.from(original.payload!)
          : null,
    );

    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.of(current.tabs);
    newTabs.insert(tabIndex + 1, clone);

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = current.copyWith(
      tabs: newTabs,
      activeTabIndex: tabIndex + 1,
    );

    return state.copyWith(windows: updated);
  }

  /// Поглощает перенесенную вкладку в целевой оконный контейнер (Tab Merging).
  static WorkspaceState dropTabOnWindow({
    required WorkspaceState state,
    required TabDragPayload payload,
    required String targetWindowId,
    int? insertIndex,
  }) {
    if (payload.sourceWindowId == targetWindowId) {
      return state.copyWith(clearDraggingTab: true);
    }

    final WorkspaceState afterClose = closeTab(
      state,
      payload.sourceWindowId,
      payload.tab.id,
    );

    final int targetIdx = afterClose.windows.indexWhere(
      (WindowState w) => w.id == targetWindowId,
    );
    if (targetIdx == -1) {
      return afterClose.copyWith(clearDraggingTab: true);
    }

    final WindowState targetWin = afterClose.windows[targetIdx];
    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.of(targetWin.tabs);
    final int idx = insertIndex?.clamp(0, newTabs.length) ?? newTabs.length;
    newTabs.insert(idx, payload.tab);

    final List<WindowState> updated = List<WindowState>.of(afterClose.windows);
    updated[targetIdx] = targetWin.copyWith(
      tabs: newTabs,
      activeTabIndex: idx,
    );

    final List<WindowState> reordered = WindowHierarchyOps.reorderWithTierFocus(
      updated,
      targetWindowId,
    );

    return afterClose.copyWith(
      windows: reordered,
      focusedWindowId: targetWindowId,
      clearDraggingTab: true,
    );
  }

  /// Отрывает вкладку в самостоятельное новое окно на холсте (Tear-off).
  static WorkspaceState detachTabToNewWindow({
    required WorkspaceState state,
    required TabDragPayload payload,
    required double dropX,
    required double dropY,
    double? width,
    double? height,
  }) {
    final WorkspaceState afterClose = closeTab(
      state,
      payload.sourceWindowId,
      payload.tab.id,
    );

    final WindowConstraints constraints =
        payload.tab.constraints ?? afterClose.config.defaultConstraints;

    final double defaultW =
        afterClose.config.defaultConstraints.clampWidth(480.0);
    final double defaultH =
        afterClose.config.defaultConstraints.clampHeight(320.0);

    final double finalW = constraints.clampWidth(width ?? defaultW);
    final double finalH = constraints.clampHeight(height ?? defaultH);

    final (double cx, double cy) = BoundsClamper.clampWindowPosition(
      targetX: dropX,
      targetY: dropY,
      windowWidth: finalW,
      windowHeight: finalH,
      availableArea: afterClose.availableArea,
      headerHeight: afterClose.config.headerHeight,
      minVisibleWidth: afterClose.config.minVisibleHeaderWidth,
    );

    final int now = DateTime.now().microsecondsSinceEpoch;
    final String newWindowId = 'win_${payload.tab.typeId}_$now';

    final WindowState newWindow = WindowState(
      id: newWindowId,
      x: cx,
      y: cy,
      width: finalW,
      height: finalH,
      tabs: <WorkspaceTab>[payload.tab],
      activeTabIndex: 0,
      createdAt: now,
    );

    final List<WindowState> updated = List<WindowState>.of(afterClose.windows)
      ..add(newWindow);

    final List<WindowState> reordered = WindowHierarchyOps.reorderWithTierFocus(
      updated,
      newWindowId,
    );

    final List<String> updatedDockOrder = List<String>.of(afterClose.dockOrder)
      ..add(newWindowId);

    return afterClose.copyWith(
      windows: reordered,
      focusedWindowId: newWindowId,
      clearDraggingTab: true,
      dockOrder: updatedDockOrder,
    );
  }
}