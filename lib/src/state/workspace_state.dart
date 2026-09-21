import '../config/workspace_config.dart';
import '../model/geometry_types.dart';
import '../model/tab_drag_payload.dart';
import '../model/window_state.dart';

/// Неизменяемый снимок глобального состояния рабочего пространства.
class WorkspaceState {
  /// Список всех оконных контейнеров на холсте.
  final List<WindowState> windows;

  /// Идентификатор активного сфокусированного окна.
  final String? focusedWindowId;

  /// Активная зона тайлинга при перетаскивании.
  final SnapZone pendingSnapZone;

  /// Геометрический прямоугольник оверлея предпросмотра тайлинга.
  final WorkspaceRect? snapPreviewRect;

  /// Полезная доступная область холста.
  final WorkspaceRect availableArea;

  /// Идентификатор окна, находящегося в режиме сольного фокуса.
  final String? soloWindowId;

  /// Полезная нагрузка активного жеста перетаскивания вкладки.
  final TabDragPayload? draggingTabPayload;

  /// Стабильный порядок следования идентификаторов окон на док-панели.
  final List<String> dockOrder;

  /// Глобальная конфигурация рабочего пространства.
  final WorkspaceConfig config;

  /// Создает неизменяемый экземпляр [WorkspaceState].
  const WorkspaceState({
    this.windows = const <WindowState>[],
    this.focusedWindowId,
    this.pendingSnapZone = SnapZone.none,
    this.snapPreviewRect,
    this.availableArea =
        const WorkspaceRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0),
    this.soloWindowId,
    this.draggingTabPayload,
    this.dockOrder = const <String>[],
    this.config = const WorkspaceConfig(),
  });

  /// Возвращает текущее сфокусированное окно либо `null`.
  WindowState? get focusedWindow {
    if (focusedWindowId == null) {
      return null;
    }
    for (final WindowState w in windows) {
      if (w.id == focusedWindowId) {
        return w;
      }
    }
    return null;
  }

  /// Возвращает окно в режиме сольного фокуса либо `null`.
  WindowState? get soloWindow {
    if (soloWindowId == null) {
      return null;
    }
    for (final WindowState w in windows) {
      if (w.id == soloWindowId) {
        return w;
      }
    }
    return null;
  }

  /// Активен ли режим сольного фокуса.
  bool get isSoloMode => soloWindowId != null;

  /// Список обычных окон стандартного яруса (не закрепленных и не свернутых).
  List<WindowState> get standardWindows => windows
      .where((WindowState w) => !w.isPinnedOnTop && !w.isMinimized)
      .toList(growable: false);

  /// Список окон приоритетного яруса закрепления (Always on Top).
  List<WindowState> get pinnedWindows => windows
      .where((WindowState w) => w.isPinnedOnTop && !w.isMinimized)
      .toList(growable: false);

  /// Список свернутых в док-панель окон.
  List<WindowState> get minimizedWindows =>
      windows.where((WindowState w) => w.isMinimized).toList(growable: false);

  /// Список всех видимых (не свернутых) окон.
  List<WindowState> get visibleWindows =>
      windows.where((WindowState w) => !w.isMinimized).toList(growable: false);

  /// Создает копию состояния рабочего пространства с заменой выбранных свойств.
  WorkspaceState copyWith({
    List<WindowState>? windows,
    String? focusedWindowId,
    bool clearFocusedWindow = false,
    SnapZone? pendingSnapZone,
    WorkspaceRect? snapPreviewRect,
    bool clearSnapPreview = false,
    WorkspaceRect? availableArea,
    String? soloWindowId,
    bool clearSoloWindow = false,
    TabDragPayload? draggingTabPayload,
    bool clearDraggingTab = false,
    List<String>? dockOrder,
    WorkspaceConfig? config,
  }) {
    return WorkspaceState(
      windows: windows ?? this.windows,
      focusedWindowId: clearFocusedWindow
          ? null
          : (focusedWindowId ?? this.focusedWindowId),
      pendingSnapZone: pendingSnapZone ?? this.pendingSnapZone,
      snapPreviewRect:
          clearSnapPreview ? null : (snapPreviewRect ?? this.snapPreviewRect),
      availableArea: availableArea ?? this.availableArea,
      soloWindowId:
          clearSoloWindow ? null : (soloWindowId ?? this.soloWindowId),
      draggingTabPayload: clearDraggingTab
          ? null
          : (draggingTabPayload ?? this.draggingTabPayload),
      dockOrder: dockOrder ?? this.dockOrder,
      config: config ?? this.config,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkspaceState &&
        other.focusedWindowId == focusedWindowId &&
        other.pendingSnapZone == pendingSnapZone &&
        other.snapPreviewRect == snapPreviewRect &&
        other.availableArea == availableArea &&
        other.soloWindowId == soloWindowId &&
        other.draggingTabPayload == draggingTabPayload &&
        other.config == config &&
        _listEquals(other.windows, windows) &&
        _listStringEquals(other.dockOrder, dockOrder);
  }

  static bool _listEquals(List<WindowState> a, List<WindowState> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _listStringEquals(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        focusedWindowId,
        pendingSnapZone,
        snapPreviewRect,
        availableArea,
        soloWindowId,
        draggingTabPayload,
        config,
      );

  @override
  String toString() {
    return 'WorkspaceState(windows: ${windows.length}, focused: $focusedWindowId, solo: $soloWindowId)';
  }
}