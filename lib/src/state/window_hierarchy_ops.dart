import '../model/window_state.dart';
import 'workspace_state.dart';

/// Обработчик операций иерархии окон, порядка наложения (Z-Index) и док-панели.
class WindowHierarchyOps {
  const WindowHierarchyOps._();

  /// Передает активный фокус целевому окну [windowId] с сохранением приоритета закрепления.
  static WorkspaceState focusWindow(WorkspaceState state, String windowId) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final List<WindowState> reordered = reorderWithTierFocus(
      state.windows,
      windowId,
    );

    return state.copyWith(
      windows: reordered,
      focusedWindowId: windowId,
    );
  }

  /// Сворачивает окно [windowId] и переводит фокус на следующее видимое окно.
  static WorkspaceState minimizeWindow(WorkspaceState state, String windowId) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = updated[index].copyWith(isMinimized: true);

    String? nextFocused = state.focusedWindowId;
    if (nextFocused == windowId) {
      nextFocused = null;
      for (int i = updated.length - 1; i >= 0; i--) {
        if (!updated[i].isMinimized) {
          nextFocused = updated[i].id;
          break;
        }
      }
    }

    return state.copyWith(
      windows: updated,
      focusedWindowId: nextFocused,
      clearFocusedWindow: nextFocused == null,
    );
  }

  /// Восстанавливает свернутое окно [windowId] на холст и активирует фокус.
  static WorkspaceState restoreWindow(WorkspaceState state, String windowId) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = updated[index].copyWith(isMinimized: false);

    final List<WindowState> reordered = reorderWithTierFocus(
      updated,
      windowId,
    );

    return state.copyWith(
      windows: reordered,
      focusedWindowId: windowId,
    );
  }

  /// Инвертирует статус постоянного закрепления окна поверх остальных (Always on Top).
  static WorkspaceState togglePinWindow(WorkspaceState state, String windowId) {
    final int index = state.windows.indexWhere(
      (WindowState w) => w.id == windowId,
    );
    if (index == -1) {
      return state;
    }

    final WindowState target = state.windows[index];
    final bool newPinned = !target.isPinnedOnTop;

    final List<WindowState> updated = List<WindowState>.of(state.windows);
    updated[index] = target.copyWith(isPinnedOnTop: newPinned);

    final List<WindowState> reordered = reorderWithTierFocus(
      updated,
      windowId,
    );

    return state.copyWith(
      windows: reordered,
      focusedWindowId: windowId,
    );
  }

  /// Переключает режим монопольного фокуса (Solo Mode).
  static WorkspaceState toggleSoloMode(WorkspaceState state, String windowId) {
    if (state.soloWindowId == windowId) {
      return state.copyWith(clearSoloWindow: true);
    }
    final WorkspaceState focusedState = focusWindow(state, windowId);
    return focusedState.copyWith(soloWindowId: windowId);
  }

  /// Удаляет окно [windowId] и переназначает активный фокус.
  static WorkspaceState closeWindow(WorkspaceState state, String windowId) {
    final List<WindowState> updated = state.windows
        .where((WindowState w) => w.id != windowId)
        .toList(growable: false);

    final List<String> updatedDockOrder = state.dockOrder
        .where((String id) => id != windowId)
        .toList(growable: false);

    String? nextFocused = state.focusedWindowId;
    if (nextFocused == windowId) {
      nextFocused = null;
      for (int i = updated.length - 1; i >= 0; i--) {
        if (!updated[i].isMinimized) {
          nextFocused = updated[i].id;
          break;
        }
      }
    }

    return state.copyWith(
      windows: updated,
      focusedWindowId: nextFocused,
      clearFocusedWindow: nextFocused == null,
      clearSoloWindow: state.soloWindowId == windowId,
      dockOrder: updatedDockOrder,
    );
  }

  /// Упорядочивает стек окон по Z-Index с абсолютным приоритетом яруса Always-on-Top.
  static List<WindowState> reorderWithTierFocus(
    List<WindowState> source,
    String targetId,
  ) {
    final int targetIdx = source.indexWhere(
      (WindowState w) => w.id == targetId,
    );
    if (targetIdx == -1) {
      return source;
    }

    final WindowState target = source[targetIdx];
    final List<WindowState> standard = source
        .where((WindowState w) => !w.isPinnedOnTop && w.id != targetId)
        .toList();
    final List<WindowState> pinned = source
        .where((WindowState w) => w.isPinnedOnTop && w.id != targetId)
        .toList();

    if (target.isPinnedOnTop) {
      pinned.add(target);
    } else {
      standard.add(target);
    }

    return <WindowState>[...standard, ...pinned];
  }

  /// Синхронизирует стабильный список идентификаторов док-панели без изменения порядка.
  static List<String> syncDockOrder(
    List<String> currentOrder,
    List<WindowState> currentWindows,
  ) {
    final Set<String> windowIds =
        currentWindows.map((WindowState w) => w.id).toSet();
    final List<String> updated =
        currentOrder.where((String id) => windowIds.contains(id)).toList();

    for (final WindowState w in currentWindows) {
      if (!updated.contains(w.id)) {
        updated.add(w.id);
      }
    }
    return updated;
  }
}