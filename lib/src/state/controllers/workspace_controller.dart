import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../engine/geometry/magnet_snapper.dart';
import '../../engine/layout/tile_calculator.dart';
import '../../engine/seam/seam_resizer.dart';
import '../models/geometry_types.dart';
import '../models/window_state.dart';
import '../models/workspace_state.dart';
import '../models/workspace_tab.dart';

part 'workspace_controller.g.dart';

/// Контроллер управления многооконным рабочим пространством, геометрией и вкладками.
@Riverpod(keepAlive: true)
class WorkspaceController extends _$WorkspaceController {
  int _idCounter = 0;

  @override
  WorkspaceState build() {
    return WorkspaceState.initial;
  }

  String _nextId() {
    _idCounter++;
    return 'win_$_idCounter';
  }

  /// Обновляет габариты рабочей области экрана.
  void setScreenSize(Size size) {
    if (state.screenSize == size) {
      return;
    }
    state = state.copyWith(screenSize: size);
  }

  /// Перемещает окно с идентификатором [id] на передний план (Z-index) и активирует фокус.
  void bringToFront(String id) {
    final List<WindowState> currentWindows =
        List<WindowState>.from(state.windows);
    final int index = currentWindows.indexWhere((WindowState w) => w.id == id);
    if (index == -1) {
      return;
    }

    final WindowState target = currentWindows.removeAt(index);
    currentWindows.add(target);

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(currentWindows),
      focusedWindowId: () => id,
    );
  }

  /// Циклически переключает активный фокус между видимыми окнами (Alt+Tab).
  void cycleFocus({bool reverse = false}) {
    final List<WindowState> visible =
        state.windows.where((WindowState w) => !w.isMinimized).toList();
    if (visible.isEmpty) {
      return;
    }

    final int currentIndex =
        visible.indexWhere((WindowState w) => w.id == state.focusedWindowId);
    final int nextIndex = currentIndex == -1
        ? 0
        : (reverse ? (currentIndex - 1 + visible.length) : (currentIndex + 1)) %
            visible.length;

    bringToFront(visible[nextIndex].id);
  }

  /// Создает новое плавающее окно с указанной вкладкой или списком вкладок.
  void addWindow({
    WorkspaceTab? tab,
    List<WorkspaceTab>? tabs,
    Offset? at,
    double? width,
    double? height,
  }) {
    final String id = _nextId();
    final double spawnX = at?.dx ?? (60.0 + (_idCounter % 6) * 30.0);
    final double spawnY = at?.dy ?? (50.0 + (_idCounter % 6) * 30.0);

    final List<WorkspaceTab> initialTabs = tabs ??
        <WorkspaceTab>[
          tab ??
              WorkspaceTab(
                id: 'tab_$_idCounter',
                title: 'Окно $_idCounter',
              ),
        ];

    final WindowState newWindow = WindowState(
      id: id,
      tabs: List<WorkspaceTab>.unmodifiable(initialTabs),
      x: spawnX.clamp(
        0.0,
        math.max(0.0, state.screenSize.width - 240.0),
      ),
      y: spawnY.clamp(
        0.0,
        math.max(0.0, state.availableHeight - 160.0),
      ),
      width: width ?? 580.0,
      height: height ?? 420.0,
    );

    final List<WindowState> updated = <WindowState>[
      ...state.windows,
      newWindow,
    ];

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
      focusedWindowId: () => id,
    );
  }

  /// Закрывает окно по идентификатору [id].
  void closeWindow(String id) {
    final List<WindowState> updated =
        state.windows.where((WindowState w) => w.id != id).toList();
    final String? nextFocus = state.focusedWindowId == id
        ? (updated.isNotEmpty ? updated.last.id : null)
        : state.focusedWindowId;

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
      focusedWindowId: () => nextFocus,
    );
  }

  /// Переключает статус минимизации окна в панель задач.
  void toggleMinimize(String id) {
    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(isMinimized: !w.isMinimized);
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Переключает закрепление окна поверх всех остальных.
  void togglePin(String id) {
    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(isPinnedOnTop: !w.isPinnedOnTop);
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Перемещает окно с расчетом сглаженного магнитного прилипания к краям и соседям.
  void moveWindow(String id, Offset delta) {
    final WindowState? win = _findWindow(id);
    if (win == null || win.isMaximized) {
      return;
    }

    final Offset magnetized = MagnetSnapper.snap(
      win: win,
      targetX: win.x + delta.dx,
      targetY: win.y + delta.dy,
      allWindows: state.windows,
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
      magnetThreshold: state.config.magnetThreshold,
    );

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          x: magnetized.dx,
          y: magnetized.dy,
        );
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Выполняет интерактивный ресайз окна с поддержкой общего шва (Shared Seam Tiling).
  void resizeWindow(String id, ResizeHandle handle, Offset delta) {
    final List<WindowState> resized = SeamResizer.resize(
      targetId: id,
      handle: handle,
      delta: delta,
      windows: state.windows,
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
      constraints: state.config.constraints,
    );

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(resized),
    );
  }

  /// Применяет раскладку быстрого тайлинга (Quick Tile) к окну [id].
  void tileWindow(String id, String mode) {
    final WindowState? win = _findWindow(id);
    if (win == null) {
      return;
    }

    final WindowState tiled = TileCalculator.applyTile(
      win: win,
      mode: mode,
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
    );

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return tiled;
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
    bringToFront(id);
  }

  /// Обновляет оверлей зоны прилипания при перетаскивании заголовка окна к краям экрана.
  void updateSnapPreview(Offset globalPos) {
    final SnapCalculationResult result = TileCalculator.calculateSnap(
      globalPos: globalPos,
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
      edgeTriggerZone: state.config.edgeSnapTriggerZone,
    );

    state = state.copyWith(
      pendingSnapZone: result.zone,
      snapPreviewRect: () => result.previewRect,
    );
  }

  /// Сбрасывает активную зону прилипания.
  void clearSnapPreview() {
    if (state.pendingSnapZone == SnapZone.none &&
        state.snapPreviewRect == null) {
      return;
    }
    state = state.copyWith(
      pendingSnapZone: SnapZone.none,
      snapPreviewRect: () => null,
    );
  }

  /// Применяет тайлинг окна при отпускании перетаскиваемого окна над зоной прилипания.
  void commitSnapIfPending(String id) {
    if (state.pendingSnapZone == SnapZone.none) {
      return;
    }

    final String mode = switch (state.pendingSnapZone) {
      SnapZone.maximize => 'maximize',
      SnapZone.left => 'left_half',
      SnapZone.right => 'right_half',
      SnapZone.topLeft => 'top_left',
      SnapZone.topRight => 'top_right',
      SnapZone.bottomLeft => 'bottom_left',
      SnapZone.bottomRight => 'bottom_right',
      SnapZone.none => '',
    };

    clearSnapPreview();
    if (mode.isNotEmpty) {
      tileWindow(id, mode);
    }
  }

  /// Выбирает активную вкладку внутри окна.
  void selectTab(String id, int index) {
    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(activeTabIndex: index);
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
    bringToFront(id);
  }

  /// Закрывает указанную вкладку окна.
  void closeTab(String id, int index) {
    final WindowState? win = _findWindow(id);
    if (win == null) {
      return;
    }

    if (win.tabs.length <= 1) {
      closeWindow(id);
      return;
    }

    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.from(win.tabs)
      ..removeAt(index);
    final int newActiveIndex = win.activeTabIndex >= newTabs.length
        ? newTabs.length - 1
        : win.activeTabIndex;

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          tabs: List<WorkspaceTab>.unmodifiable(newTabs),
          activeTabIndex: newActiveIndex,
        );
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Закрывает активную вкладку окна в фокусе (Ctrl+W).
  void closeFocusedTab() {
    final WindowState? win = state.focusedWindow;
    if (win == null) {
      return;
    }
    closeTab(win.id, win.activeTabIndex);
  }

  /// Дублирует указанную вкладку в текущем окне.
  void duplicateTab(String id, int index) {
    final WindowState? win = _findWindow(id);
    if (win == null || index < 0 || index >= win.tabs.length) {
      return;
    }

    final WorkspaceTab original = win.tabs[index];
    final WorkspaceTab cloned = original.copyWith(
      title: '${original.title} (Копия)',
    );

    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.from(win.tabs)
      ..insert(index + 1, cloned);

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          tabs: List<WorkspaceTab>.unmodifiable(newTabs),
          activeTabIndex: index + 1,
        );
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Обновляет данные вкладки окна.
  void updateTab(String id, int index, WorkspaceTab tab) {
    final WindowState? win = _findWindow(id);
    if (win == null || index < 0 || index >= win.tabs.length) {
      return;
    }

    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.from(win.tabs)
      ..[index] = tab;

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          tabs: List<WorkspaceTab>.unmodifiable(newTabs),
        );
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Добавляет новую вкладку в окно [id].
  void addTab(String id, WorkspaceTab tab) {
    final WindowState? win = _findWindow(id);
    if (win == null) {
      return;
    }

    final List<WorkspaceTab> newTabs = List<WorkspaceTab>.from(win.tabs)
      ..add(tab);

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          tabs: List<WorkspaceTab>.unmodifiable(newTabs),
          activeTabIndex: newTabs.length - 1,
        );
      }
      return w;
    }).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
  }

  /// Отрывает вкладку в самостоятельное плавающее окно (Tear-off).
  void detachTab(String id, int index, Offset dropGlobalPos) {
    final WindowState? win = _findWindow(id);
    if (win == null || index < 0 || index >= win.tabs.length) {
      return;
    }

    if (win.tabs.length <= 1) {
      final double nx = (dropGlobalPos.dx - 40.0).clamp(
        0.0,
        math.max(0.0, state.screenSize.width - 200.0),
      );
      final double ny = (dropGlobalPos.dy - 18.0).clamp(
        0.0,
        math.max(0.0, state.availableHeight - 100.0),
      );
      final List<WindowState> updated = state.windows.map((WindowState w) {
        if (w.id == id) {
          return w.copyWith(x: nx, y: ny);
        }
        return w;
      }).toList();

      state = state.copyWith(
        windows: List<WindowState>.unmodifiable(updated),
      );
      bringToFront(id);
      return;
    }

    final List<WorkspaceTab> sourceTabs = List<WorkspaceTab>.from(win.tabs);
    final WorkspaceTab detachedTab = sourceTabs.removeAt(index);
    final int sourceActive = win.activeTabIndex >= sourceTabs.length
        ? sourceTabs.length - 1
        : win.activeTabIndex;

    final String newId = _nextId();
    final WindowState spawned = WindowState(
      id: newId,
      tabs: <WorkspaceTab>[detachedTab],
      x: (dropGlobalPos.dx - 60.0).clamp(
        0.0,
        math.max(0.0, state.screenSize.width - 200.0),
      ),
      y: (dropGlobalPos.dy - 18.0).clamp(
        0.0,
        math.max(0.0, state.availableHeight - 100.0),
      ),
      width: 520.0,
      height: 380.0,
    );

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          tabs: List<WorkspaceTab>.unmodifiable(sourceTabs),
          activeTabIndex: sourceActive,
        );
      }
      return w;
    }).toList()
      ..add(spawned);

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
      focusedWindowId: () => newId,
    );
  }

  /// Объединяет вкладку из [sourceId] в окно [targetId] при перетаскивании (Tab Merging).
  void mergeTab(String sourceId, int index, String targetId) {
    if (sourceId == targetId) {
      return;
    }

    final WindowState? source = _findWindow(sourceId);
    final WindowState? target = _findWindow(targetId);
    if (source == null || target == null) {
      return;
    }

    if (index < 0 || index >= source.tabs.length) {
      return;
    }

    final List<WorkspaceTab> sourceTabs = List<WorkspaceTab>.from(source.tabs);
    final WorkspaceTab moved = sourceTabs.removeAt(index);
    final int sourceActive = source.activeTabIndex >= sourceTabs.length
        ? math.max(0, sourceTabs.length - 1)
        : source.activeTabIndex;

    final List<WorkspaceTab> targetTabs = List<WorkspaceTab>.from(target.tabs)
      ..add(moved);

    final List<WindowState> updated = <WindowState>[];
    for (final WindowState w in state.windows) {
      if (w.id == sourceId) {
        if (sourceTabs.isNotEmpty) {
          updated.add(
            w.copyWith(
              tabs: List<WorkspaceTab>.unmodifiable(sourceTabs),
              activeTabIndex: sourceActive,
            ),
          );
        }
      } else if (w.id == targetId) {
        updated.add(
          w.copyWith(
            tabs: List<WorkspaceTab>.unmodifiable(targetTabs),
            activeTabIndex: targetTabs.length - 1,
          ),
        );
      } else {
        updated.add(w);
      }
    }

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updated),
    );
    bringToFront(targetId);
  }

  /// Горячая клавиша: тайлинг активного окна на левую половину.
  void handleMetaLeft() {
    final WindowState? win = state.focusedWindow;
    if (win != null) {
      tileWindow(win.id, 'left_half');
    }
  }

  /// Горячая клавиша: тайлинг активного окна на правую половину.
  void handleMetaRight() {
    final WindowState? win = state.focusedWindow;
    if (win != null) {
      tileWindow(win.id, 'right_half');
    }
  }

  /// Горячая клавиша: максимизация или возврат размера окна.
  void handleMetaUp() {
    final WindowState? win = state.focusedWindow;
    if (win != null) {
      tileWindow(win.id, win.isMaximized ? 'restore' : 'maximize');
    }
  }

  /// Горячая клавиша: сворачивание окна или возврат из максимизации.
  void handleMetaDown() {
    final WindowState? win = state.focusedWindow;
    if (win == null) {
      return;
    }
    if (win.isMaximized) {
      tileWindow(win.id, 'restore');
    } else {
      toggleMinimize(win.id);
    }
  }

  /// Распределяет переданные окна или генерирует сетку 2x2.
  void applyPresetLayout2x2({List<List<WorkspaceTab>>? windowsTabs}) {
    final List<List<WorkspaceTab>> tabsMatrix = windowsTabs ??
        <List<WorkspaceTab>>[
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_1', title: 'Панель 1')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_2', title: 'Панель 2')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_3', title: 'Панель 3')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_4', title: 'Панель 4')],
        ];

    final List<WindowState> presetWindows = TileCalculator.generate2x2(
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
      tabsMatrix: tabsMatrix,
      idGenerator: _nextId,
    );

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(presetWindows),
      focusedWindowId: () => presetWindows.first.id,
    );
  }

  /// Распределяет два окна по вертикальному сплиту (50% / 50%).
  void applyPresetSplit({List<List<WorkspaceTab>>? windowsTabs}) {
    final List<List<WorkspaceTab>> tabsMatrix = windowsTabs ??
        <List<WorkspaceTab>>[
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_1', title: 'Панель 1')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_2', title: 'Панель 2')],
        ];

    final List<WindowState> presetWindows = TileCalculator.generateSplit(
      screenSize: state.screenSize,
      availableHeight: state.availableHeight,
      tabsMatrix: tabsMatrix,
      idGenerator: _nextId,
    );

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(presetWindows),
      focusedWindowId: () => presetWindows.first.id,
    );
  }

  /// Закрывает все открытые окна рабочего стола.
  void clearAllWindows() {
    state = state.copyWith(
      windows: const <WindowState>[],
      focusedWindowId: () => null,
    );
  }

  /// Сериализует текущую раскладку рабочего стола в форматированную строку JSON.
  String exportLayoutJson() {
    final Map<String, Object?> data = <String, Object?>{
      'version': 1,
      'windows': state.windows.map((WindowState w) => w.toJson()).toList(),
      'focusedWindowId': state.focusedWindowId,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Восстанавливает раскладку рабочего стола из JSON-строки.
  bool importLayoutJson(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return false;
      }

      final Object? rawWindows = decoded['windows'];
      if (rawWindows is! List) {
        return false;
      }

      final List<WindowState> restored = <WindowState>[];
      for (final Object? item in rawWindows) {
        if (item is Map<String, Object?>) {
          restored.add(WindowState.fromJson(item));
        } else if (item is Map) {
          restored.add(WindowState.fromJson(Map<String, Object?>.from(item)));
        }
      }

      final Object? rawFocused = decoded['focusedWindowId'];
      final String? focused = rawFocused is String ? rawFocused : null;

      state = state.copyWith(
        windows: List<WindowState>.unmodifiable(restored),
        focusedWindowId: () => focused,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  WindowState? _findWindow(String id) {
    for (final WindowState w in state.windows) {
      if (w.id == id) {
        return w;
      }
    }
    return null;
  }
}