import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

    final Offset magnetized = _magnetizePosition(
      win,
      win.x + delta.dx,
      win.y + delta.dy,
      state.windows,
      state.screenSize,
      state.availableHeight,
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

  Offset _magnetizePosition(
    WindowState win,
    double targetX,
    double targetY,
    List<WindowState> allWindows,
    Size screenSize,
    double availableHeight,
  ) {
    double left = targetX;
    double top = targetY;

    if (left.abs() < kMagnetThreshold) {
      left = 0.0;
    }
    if (top.abs() < kMagnetThreshold) {
      top = 0.0;
    }
    if ((left + win.width - screenSize.width).abs() < kMagnetThreshold) {
      left = screenSize.width - win.width;
    }
    if ((top + win.height - availableHeight).abs() < kMagnetThreshold) {
      top = availableHeight - win.height;
    }

    for (final WindowState other in allWindows) {
      if (other.id == win.id || other.isMinimized) {
        continue;
      }
      final double oLeft = other.x;
      final double oTop = other.y;
      final double oRight = other.x + other.width;
      final double oBottom = other.y + other.height;

      if ((left - oRight).abs() < kMagnetThreshold) {
        left = oRight;
      }
      if ((left + win.width - oLeft).abs() < kMagnetThreshold) {
        left = oLeft - win.width;
      }
      if ((top - oBottom).abs() < kMagnetThreshold) {
        top = oBottom;
      }
      if ((top + win.height - oTop).abs() < kMagnetThreshold) {
        top = oTop - win.height;
      }
    }

    return Offset(left, top);
  }

  bool _hasHorizontalOverlap(WindowState a, WindowState b) {
    final double left = math.max(a.x, b.x);
    final double right = math.min(a.x + a.width, b.x + b.width);
    return (right - left) > 20.0;
  }

  /// Выполняет интерактивный ресайз окна с поддержкой общего шва (Shared Seam Tiling).
  void resizeWindow(String id, ResizeHandle handle, Offset delta) {
    final WindowState? win = _findWindow(id);
    if (win == null) {
      return;
    }

    final double screenW = state.screenSize.width;
    final double screenH = state.availableHeight;

    final bool touchesEast = handle == ResizeHandle.e ||
        handle == ResizeHandle.ne ||
        handle == ResizeHandle.se;
    final bool touchesWest = handle == ResizeHandle.w ||
        handle == ResizeHandle.nw ||
        handle == ResizeHandle.sw;
    final bool touchesSouth = handle == ResizeHandle.s ||
        handle == ResizeHandle.se ||
        handle == ResizeHandle.sw;
    final bool touchesNorth = handle == ResizeHandle.n ||
        handle == ResizeHandle.ne ||
        handle == ResizeHandle.nw;

    final Map<String, WindowState> windowMap = <String, WindowState>{
      for (final WindowState w in state.windows) w.id: w,
    };

    bool horizontalSeamHandled = false;
    bool verticalSeamHandled = false;

    const double edgeTolerance = 4.0;
    const double seamTolerance = 8.0;

    // 1. Горизонтальный режим (общий вертикальный шов)
    if (touchesEast || touchesWest) {
      final bool winTouchesLeft = win.x.abs() <= edgeTolerance;
      final bool winTouchesRight =
          (win.x + win.width - screenW).abs() <= edgeTolerance;

      if (touchesEast && winTouchesLeft) {
        final double seamX = win.x + win.width;

        final List<WindowState> leftGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.x.abs() <= edgeTolerance &&
                  (w.x + w.width - seamX).abs() <= seamTolerance,
            )
            .toList();

        final List<WindowState> rightGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.x + w.width - screenW).abs() <= edgeTolerance &&
                  (w.x - seamX).abs() <= seamTolerance,
            )
            .toList();

        if (leftGroup.isNotEmpty && rightGroup.isNotEmpty) {
          horizontalSeamHandled = true;
          double dx = delta.dx;

          for (final WindowState w in leftGroup) {
            if (w.width + dx < kMinWindowWidth) {
              dx = kMinWindowWidth - w.width;
            }
          }
          for (final WindowState w in rightGroup) {
            if (w.width - dx < kMinWindowWidth) {
              dx = w.width - kMinWindowWidth;
            }
          }

          for (final WindowState w in leftGroup) {
            windowMap[w.id] = w.copyWith(
              width: w.width + dx,
              isMaximized: false,
            );
          }
          for (final WindowState w in rightGroup) {
            windowMap[w.id] = w.copyWith(
              x: w.x + dx,
              width: w.width - dx,
              isMaximized: false,
            );
          }
        }
      } else if (touchesWest && winTouchesRight) {
        final double seamX = win.x;

        final List<WindowState> leftGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.x.abs() <= edgeTolerance &&
                  (w.x + w.width - seamX).abs() <= seamTolerance,
            )
            .toList();

        final List<WindowState> rightGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.x + w.width - screenW).abs() <= edgeTolerance &&
                  (w.x - seamX).abs() <= seamTolerance,
            )
            .toList();

        if (leftGroup.isNotEmpty && rightGroup.isNotEmpty) {
          horizontalSeamHandled = true;
          double dx = delta.dx;

          for (final WindowState w in leftGroup) {
            if (w.width + dx < kMinWindowWidth) {
              dx = kMinWindowWidth - w.width;
            }
          }
          for (final WindowState w in rightGroup) {
            if (w.width - dx < kMinWindowWidth) {
              dx = w.width - kMinWindowWidth;
            }
          }

          for (final WindowState w in leftGroup) {
            windowMap[w.id] = w.copyWith(
              width: w.width + dx,
              isMaximized: false,
            );
          }
          for (final WindowState w in rightGroup) {
            windowMap[w.id] = w.copyWith(
              x: w.x + dx,
              width: w.width - dx,
              isMaximized: false,
            );
          }
        }
      }
    }

    // 2. Вертикальный режим (общий горизонтальный шов)
    if (touchesSouth || touchesNorth) {
      final bool winTouchesTop = win.y.abs() <= edgeTolerance;
      final bool winTouchesBottom =
          (win.y + win.height - screenH).abs() <= edgeTolerance;

      if (touchesSouth && winTouchesTop) {
        final double seamY = win.y + win.height;

        final List<WindowState> topGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.y.abs() <= edgeTolerance &&
                  (w.y + w.height - seamY).abs() <= seamTolerance &&
                  _hasHorizontalOverlap(w, win),
            )
            .toList();

        final List<WindowState> bottomGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.y + w.height - screenH).abs() <= edgeTolerance &&
                  (w.y - seamY).abs() <= seamTolerance &&
                  _hasHorizontalOverlap(w, win),
            )
            .toList();

        if (topGroup.isNotEmpty && bottomGroup.isNotEmpty) {
          verticalSeamHandled = true;
          double dy = delta.dy;

          for (final WindowState w in topGroup) {
            if (w.height + dy < kMinWindowHeight) {
              dy = kMinWindowHeight - w.height;
            }
          }
          for (final WindowState w in bottomGroup) {
            if (w.height - dy < kMinWindowHeight) {
              dy = w.height - kMinWindowHeight;
            }
          }

          for (final WindowState w in topGroup) {
            windowMap[w.id] = w.copyWith(
              height: w.height + dy,
              isMaximized: false,
            );
          }
          for (final WindowState w in bottomGroup) {
            windowMap[w.id] = w.copyWith(
              y: w.y + dy,
              height: w.height - dy,
              isMaximized: false,
            );
          }
        }
      } else if (touchesNorth && winTouchesBottom) {
        final double seamY = win.y;

        final List<WindowState> topGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  w.y.abs() <= edgeTolerance &&
                  (w.y + w.height - seamY).abs() <= seamTolerance &&
                  _hasHorizontalOverlap(w, win),
            )
            .toList();

        final List<WindowState> bottomGroup = state.windows
            .where(
              (WindowState w) =>
                  !w.isMinimized &&
                  (w.y + w.height - screenH).abs() <= edgeTolerance &&
                  (w.y - seamY).abs() <= seamTolerance &&
                  _hasHorizontalOverlap(w, win),
            )
            .toList();

        if (topGroup.isNotEmpty && bottomGroup.isNotEmpty) {
          verticalSeamHandled = true;
          double dy = delta.dy;

          for (final WindowState w in topGroup) {
            if (w.height + dy < kMinWindowHeight) {
              dy = kMinWindowHeight - w.height;
            }
          }
          for (final WindowState w in bottomGroup) {
            if (w.height - dy < kMinWindowHeight) {
              dy = w.height - kMinWindowHeight;
            }
          }

          for (final WindowState w in topGroup) {
            windowMap[w.id] = w.copyWith(
              height: w.height + dy,
              isMaximized: false,
            );
          }
          for (final WindowState w in bottomGroup) {
            windowMap[w.id] = w.copyWith(
              y: w.y + dy,
              height: w.height - dy,
              isMaximized: false,
            );
          }
        }
      }
    }

    // 3. Одиночный свободный ресайз
    if (!horizontalSeamHandled || !verticalSeamHandled) {
      final WindowState currentWin = windowMap[id] ?? win;
      double x = currentWin.x;
      double y = currentWin.y;
      double w = currentWin.width;
      double h = currentWin.height;

      if (!horizontalSeamHandled) {
        if (touchesEast) {
          w = (w + delta.dx).clamp(kMinWindowWidth, kMaxWindowExtent);
        }
        if (touchesWest) {
          final double newW =
              (w - delta.dx).clamp(kMinWindowWidth, kMaxWindowExtent);
          x += w - newW;
          w = newW;
        }
      }

      if (!verticalSeamHandled) {
        if (touchesSouth) {
          h = (h + delta.dy).clamp(kMinWindowHeight, kMaxWindowExtent);
        }
        if (touchesNorth) {
          final double newH =
              (h - delta.dy).clamp(kMinWindowHeight, kMaxWindowExtent);
          y += h - newH;
          h = newH;
        }
      }

      windowMap[id] = currentWin.copyWith(
        x: x,
        y: y,
        width: w,
        height: h,
        isMaximized: false,
      );
    }

    final List<WindowState> updatedList =
        state.windows.map((WindowState w) => windowMap[w.id] ?? w).toList();

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(updatedList),
    );
  }

  /// Применяет раскладку быстрого тайлинга (Quick Tile) к окну [id].
  void tileWindow(String id, String mode) {
    final WindowState? win = _findWindow(id);
    if (win == null) {
      return;
    }

    final double availableWidth = state.screenSize.width;
    final double availableHeightV = state.availableHeight;

    Rect? restoreRect = win.restoreRect;
    if (restoreRect == null && !win.isMaximized) {
      restoreRect = Rect.fromLTWH(win.x, win.y, win.width, win.height);
    }

    double newX = win.x;
    double newY = win.y;
    double newW = win.width;
    double newH = win.height;
    bool newMaximized = false;

    switch (mode) {
      case 'left_half':
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV;
      case 'right_half':
        newX = availableWidth / 2.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV;
      case 'top_left':
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV / 2.0;
      case 'top_right':
        newX = availableWidth / 2.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV / 2.0;
      case 'bottom_left':
        newX = 0.0;
        newY = availableHeightV / 2.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV / 2.0;
      case 'bottom_right':
        newX = availableWidth / 2.0;
        newY = availableHeightV / 2.0;
        newW = availableWidth / 2.0;
        newH = availableHeightV / 2.0;
      case 'maximize':
        newMaximized = true;
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth;
        newH = availableHeightV;
      case 'restore':
        if (restoreRect != null) {
          newX = restoreRect.left;
          newY = restoreRect.top;
          newW = restoreRect.width;
          newH = restoreRect.height;
          restoreRect = null;
        }
      default:
        break;
    }

    final List<WindowState> updated = state.windows.map((WindowState w) {
      if (w.id == id) {
        return w.copyWith(
          x: newX,
          y: newY,
          width: newW,
          height: newH,
          isMinimized: false,
          isMaximized: newMaximized,
          restoreRect: () => restoreRect,
        );
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
    final double w = state.screenSize.width;
    final double h = state.availableHeight;
    SnapZone zone = SnapZone.none;
    Rect rect = Rect.zero;

    if (globalPos.dy <= kEdgeSnapTriggerZone) {
      zone = SnapZone.maximize;
      rect = Rect.fromLTWH(0.0, 0.0, w, h);
    } else if (globalPos.dx <= kEdgeSnapTriggerZone) {
      if (globalPos.dy <= h * 0.35) {
        zone = SnapZone.topLeft;
        rect = Rect.fromLTWH(0.0, 0.0, w / 2.0, h / 2.0);
      } else if (globalPos.dy >= h * 0.65) {
        zone = SnapZone.bottomLeft;
        rect = Rect.fromLTWH(0.0, h / 2.0, w / 2.0, h / 2.0);
      } else {
        zone = SnapZone.left;
        rect = Rect.fromLTWH(0.0, 0.0, w / 2.0, h);
      }
    } else if (globalPos.dx >= w - kEdgeSnapTriggerZone) {
      if (globalPos.dy <= h * 0.35) {
        zone = SnapZone.topRight;
        rect = Rect.fromLTWH(w / 2.0, 0.0, w / 2.0, h / 2.0);
      } else if (globalPos.dy >= h * 0.65) {
        zone = SnapZone.bottomRight;
        rect = Rect.fromLTWH(w / 2.0, h / 2.0, w / 2.0, h / 2.0);
      } else {
        zone = SnapZone.right;
        rect = Rect.fromLTWH(w / 2.0, 0.0, w / 2.0, h);
      }
    }

    state = state.copyWith(
      pendingSnapZone: zone,
      snapPreviewRect: () => zone == SnapZone.none ? null : rect,
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
    final double halfW = state.screenSize.width / 2.0;
    final double halfH = state.availableHeight / 2.0;

    final List<List<WorkspaceTab>> tabsMatrix = windowsTabs ??
        <List<WorkspaceTab>>[
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_1', title: 'Панель 1')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_2', title: 'Панель 2')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_3', title: 'Панель 3')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_4', title: 'Панель 4')],
        ];

    final String id1 = _nextId();
    final String id2 = _nextId();
    final String id3 = _nextId();
    final String id4 = _nextId();

    final List<WindowState> presetWindows = <WindowState>[
      WindowState(
        id: id1,
        tabs: tabsMatrix.isNotEmpty ? tabsMatrix[0] : const <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: id2,
        tabs: tabsMatrix.length > 1 ? tabsMatrix[1] : const <WorkspaceTab>[],
        x: halfW,
        y: 0.0,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: id3,
        tabs: tabsMatrix.length > 2 ? tabsMatrix[2] : const <WorkspaceTab>[],
        x: 0.0,
        y: halfH,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: id4,
        tabs: tabsMatrix.length > 3 ? tabsMatrix[3] : const <WorkspaceTab>[],
        x: halfW,
        y: halfH,
        width: halfW,
        height: halfH,
      ),
    ];

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(presetWindows),
      focusedWindowId: () => id1,
    );
  }

  /// Распределяет два окна по вертикальному сплиту (50% / 50%).
  void applyPresetSplit({List<List<WorkspaceTab>>? windowsTabs}) {
    final double availW = state.screenSize.width;
    final double availH = state.availableHeight;

    final List<List<WorkspaceTab>> tabsMatrix = windowsTabs ??
        <List<WorkspaceTab>>[
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_1', title: 'Панель 1')],
          <WorkspaceTab>[const WorkspaceTab(id: 'panel_2', title: 'Панель 2')],
        ];

    final String id1 = _nextId();
    final String id2 = _nextId();

    final List<WindowState> presetWindows = <WindowState>[
      WindowState(
        id: id1,
        tabs: tabsMatrix.isNotEmpty ? tabsMatrix[0] : const <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: availW * 0.5,
        height: availH,
      ),
      WindowState(
        id: id2,
        tabs: tabsMatrix.length > 1 ? tabsMatrix[1] : const <WorkspaceTab>[],
        x: availW * 0.5,
        y: 0.0,
        width: availW * 0.5,
        height: availH,
      ),
    ];

    state = state.copyWith(
      windows: List<WindowState>.unmodifiable(presetWindows),
      focusedWindowId: () => id1,
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
