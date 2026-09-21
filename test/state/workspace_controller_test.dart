import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:desktop_workspace/src/model/tab_drag_payload.dart';
import 'package:desktop_workspace/src/model/view_definition.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:desktop_workspace/src/state/persistence/session_storage.dart';
import 'package:desktop_workspace/src/state/workspace_controller.dart';
import 'package:desktop_workspace/src/state/workspace_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Инициализация дефолтного состояния контроллера', () {
      final WorkspaceState state = container.read(workspaceControllerProvider);
      expect(state.windows, isEmpty);
      expect(state.focusedWindowId, isNull);
      expect(state.isSoloMode, isFalse);
    });

    test('applyPresetSplit создает сплит-раскладку из двух окон', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      expect(state.windows.length, 2);
      expect(state.focusedWindowId, 'win_split_primary');
      expect(state.windows[0].width, 500.0);
      expect(state.windows[1].width, 500.0);
    });

    test('Стабильный порядок dockOrder не меняется при смене фокуса', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      WorkspaceState state = container.read(workspaceControllerProvider);
      expect(
        state.dockOrder,
        <String>['win_split_primary', 'win_split_secondary'],
      );

      // Меняем фокус на второе окно
      controller.focusWindow('win_split_secondary');

      state = container.read(workspaceControllerProvider);
      // Порядок рендеринга Z-Index изменился
      expect(state.windows.last.id, 'win_split_secondary');
      // Но порядок чипов в доке остался абсолютно стабильным!
      expect(
        state.dockOrder,
        <String>['win_split_primary', 'win_split_secondary'],
      );
    });

    test('openView создает новое окно на холсте без удаления существующих', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSolo(<WorkspaceTab>[
        const WorkspaceTab(id: 'init_1', typeId: 'type_init', title: 'Init'),
      ]);

      expect(container.read(workspaceControllerProvider).windows.length, 1);

      controller.openView(
        definition: ViewDefinition(
          typeId: 'type_new',
          title: 'Новая панель',
          builder: (_, __, ___) => const SizedBox(),
        ),
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      expect(state.windows.length, 2);
      expect(state.focusedWindowId, startsWith('win_type_new_'));
      expect(state.dockOrder.length, 2);
    });

    test('Приоритет ярусов: Always-on-Top окно всегда выше обычных', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      controller.togglePinWindow('win_split_primary');

      WorkspaceState state = container.read(workspaceControllerProvider);
      expect(state.windows.last.id, 'win_split_primary');

      controller.focusWindow('win_split_secondary');

      state = container.read(workspaceControllerProvider);
      expect(state.windows.last.id, 'win_split_primary');
    });

    test(
        'tileWindow и untileWindow корректно сохраняют и восстанавливают геометрию',
        () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      controller.tileWindow('win_split_primary', SnapZone.maximize);

      WorkspaceState state = container.read(workspaceControllerProvider);
      final WindowState maximized = state.windows
          .firstWhere((WindowState w) => w.id == 'win_split_primary');

      expect(maximized.snapZone, SnapZone.maximize);
      expect(maximized.isMaximized, isTrue);
      expect(maximized.restoreRect, isNotNull);
      expect(maximized.width, state.availableArea.width);

      controller.untileWindow('win_split_primary');

      state = container.read(workspaceControllerProvider);
      final WindowState untiled = state.windows
          .firstWhere((WindowState w) => w.id == 'win_split_primary');

      expect(untiled.snapZone, SnapZone.none);
      expect(untiled.isMaximized, isFalse);
      expect(untiled.width, 500.0);
    });

    test('resizeWindow выполняет изменение размеров вдоль активного вектора',
        () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      controller.resizeWindow(
        windowId: 'win_split_primary',
        direction: ResizeDirection.east,
        deltaX: 40.0,
        deltaY: 0.0,
        enableSeamResizing: true,
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      final WindowState primary = state.windows
          .firstWhere((WindowState w) => w.id == 'win_split_primary');
      final WindowState secondary = state.windows
          .firstWhere((WindowState w) => w.id == 'win_split_secondary');

      expect(primary.width, 540.0);
      expect(secondary.width, 460.0);
      expect(secondary.x, 540.0);
    });

    test('moveWindow активирует оверлей предпросмотра при входе в краевую зону',
        () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      controller.moveWindow(
        windowId: 'win_split_primary',
        deltaX: 0.0,
        deltaY: -200.0,
        pointerX: 500.0,
        pointerY: 10.0,
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      expect(state.pendingSnapZone, SnapZone.maximize);
      expect(state.snapPreviewRect, isNotNull);
      expect(state.snapPreviewRect!.width, state.availableArea.width);
    });

    test('Каскадное закрытие окна при закрытии последней вкладки', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2'),
          ],
        ],
      );

      controller.closeTab(windowId: 'win_split_primary', tabId: 't1');

      final WorkspaceState state = container.read(workspaceControllerProvider);
      expect(
        state.windows.any((WindowState w) => w.id == 'win_split_primary'),
        isFalse,
      );
      expect(state.windows.length, 1);
    });

    test('Локальное переупорядочивание вкладок внутри одного окна', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSolo(<WorkspaceTab>[
        const WorkspaceTab(id: 'tab_a', typeId: 'type_a', title: 'Таб A'),
        const WorkspaceTab(id: 'tab_b', typeId: 'type_b', title: 'Таб B'),
        const WorkspaceTab(id: 'tab_c', typeId: 'type_c', title: 'Таб C'),
      ]);

      const String windowId = 'win_solo_fullscreen';

      // Переносим Таб A (индекс 0) в слот после Таба B (слот 2)
      controller.dropTabOnWindow(
        payload: const TabDragPayload(
          tab: WorkspaceTab(id: 'tab_a', typeId: 'type_a', title: 'Таб A'),
          sourceWindowId: windowId,
          sourceTabIndex: 0,
          isSingleTab: false,
        ),
        targetWindowId: windowId,
        insertIndex: 2,
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      final WindowState win =
          state.windows.firstWhere((WindowState w) => w.id == windowId);

      expect(win.tabs.map((WorkspaceTab t) => t.id).toList(), <String>[
        'tab_b',
        'tab_a',
        'tab_c',
      ]);
    });

    test('Межоконное поглощение вкладки с точным insertIndex', () {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(
              id: 'tab_target_1',
              typeId: 'type_1',
              title: 'Цель 1',
            ),
            const WorkspaceTab(
              id: 'tab_target_2',
              typeId: 'type_2',
              title: 'Цель 2',
            ),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(
              id: 'tab_source_1',
              typeId: 'type_src',
              title: 'Источник',
            ),
          ],
        ],
      );

      // Переносим вкладку 'tab_source_1' в окно 'win_split_primary' в индекс 1 (между 'tab_target_1' и 'tab_target_2')
      controller.dropTabOnWindow(
        payload: const TabDragPayload(
          tab: WorkspaceTab(
            id: 'tab_source_1',
            typeId: 'type_src',
            title: 'Источник',
          ),
          sourceWindowId: 'win_split_secondary',
          sourceTabIndex: 0,
          isSingleTab: true,
        ),
        targetWindowId: 'win_split_primary',
        insertIndex: 1,
      );

      final WorkspaceState state = container.read(workspaceControllerProvider);
      final WindowState targetWin = state.windows
          .firstWhere((WindowState w) => w.id == 'win_split_primary');

      expect(targetWin.tabs.length, 3);
      expect(targetWin.tabs[1].id, 'tab_source_1');
      expect(targetWin.activeTabIndex, 1);
      // Окно-источник опустело и каскадно закрылось
      expect(
        state.windows.any((WindowState w) => w.id == 'win_split_secondary'),
        isFalse,
      );
    });

    test('Дебаунсированное автосохранение снимка в SessionStorage', () async {
      final WorkspaceController controller =
          container.read(workspaceControllerProvider.notifier);
      final InMemorySessionStorage storage = InMemorySessionStorage();

      controller.attachSessionStorage(
        storage,
        debounceDuration: const Duration(milliseconds: 50),
      );
      controller.updateViewportSize(1000.0, 800.0);

      controller.applyPresetSolo(<WorkspaceTab>[
        const WorkspaceTab(id: 'solo_1', typeId: 'v1', title: 'Solo'),
      ]);

      expect(await storage.loadSnapshot(), isNull);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final snapshot = await storage.loadSnapshot();
      expect(snapshot, isNotNull);
      expect(snapshot!.windows.length, 1);
      expect(snapshot.windows.first.id, 'win_solo_fullscreen');
    });
  });
}