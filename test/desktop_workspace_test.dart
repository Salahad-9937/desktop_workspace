import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowState & WorkspaceTab Models', () {
    test('WindowState инициализируется с корректными параметрами по умолчанию', () {
      const WindowState window = WindowState(
        id: 'win_test',
        tabs: <WorkspaceTab>[
          WorkspaceTab(id: 'test_tab', title: 'Тестовая вкладка'),
        ],
        x: 100.0,
        y: 100.0,
        width: 500.0,
        height: 400.0,
      );

      expect(window.id, 'win_test');
      expect(window.activeTab?.id, 'test_tab');
      expect(window.activeTab?.title, 'Тестовая вкладка');
      expect(window.x, 100.0);
      expect(window.y, 100.0);
      expect(window.width, 500.0);
      expect(window.height, 400.0);
      expect(window.isMaximized, isFalse);
      expect(window.isMinimized, isFalse);
      expect(window.isPinnedOnTop, isFalse);
      expect(window.isClosable, isTrue);
      expect(window.isMaximizable, isTrue);
      expect(window.isMinimizable, isTrue);
      expect(window.canTile, isTrue);
    });

    test('WindowState рассчитывает действующие ограничения effectiveConstraints', () {
      const WindowConstraints fallback = WindowConstraints(
        minWidth: 300.0,
        minHeight: 200.0,
      );
      const WindowConstraints customLimits = WindowConstraints(
        minWidth: 450.0,
        minHeight: 350.0,
      );

      const WindowState defaultWindow = WindowState(
        id: 'default',
        tabs: <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: 500.0,
        height: 400.0,
      );
      expect(
        defaultWindow.effectiveConstraints(fallback).minWidth,
        fallback.minWidth,
      );

      const WindowState windowWithConstraints = WindowState(
        id: 'constrained',
        constraints: customLimits,
        tabs: <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: 500.0,
        height: 400.0,
      );
      expect(
        windowWithConstraints.effectiveConstraints(fallback).minWidth,
        customLimits.minWidth,
      );
    });

    test('WindowState сериализуется и десериализуется через JSON', () {
      const WindowState original = WindowState(
        id: 'win_json',
        tabs: <WorkspaceTab>[
          WorkspaceTab(id: 'tab_1', title: 'Таб 1', keepAlive: true),
        ],
        x: 120.0,
        y: 140.0,
        width: 600.0,
        height: 450.0,
        isPinnedOnTop: true,
        isMinimized: false,
        isMaximized: false,
        isClosable: true,
        canTile: true,
        restoreRect: Rect.fromLTWH(100.0, 100.0, 500.0, 400.0),
        constraints: WindowConstraints(minWidth: 350.0, minHeight: 250.0),
      );

      final Map<String, Object?> json = original.toJson();
      final WindowState restored = WindowState.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.isPinnedOnTop, isTrue);
      expect(restored.restoreRect?.left, 100.0);
      expect(restored.constraints?.minWidth, 350.0);
      expect(restored.tabs.first.keepAlive, isTrue);
    });

    test('WorkspaceTab сериализуется и десериализуется с сохранением keepAlive', () {
      const WorkspaceTab original = WorkspaceTab(
        id: 'tab_json',
        title: 'Тест JSON',
        icon: Icons.layers_rounded,
        accentColor: Color(0xFF00E5FF),
        keepAlive: true,
        constraints: WindowConstraints(minWidth: 400.0, minHeight: 300.0),
        payload: <String, Object?>{'key': 'value', 'count': 42},
      );

      final Map<String, Object?> json = original.toJson();
      final WorkspaceTab restored = WorkspaceTab.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.keepAlive, isTrue);
      expect(restored.constraints?.minWidth, 400.0);
      expect(restored.icon?.codePoint, original.icon?.codePoint);
      expect(
        restored.accentColor?.toARGB32(),
        original.accentColor?.toARGB32(),
      );
      expect(restored.payload?['key'], 'value');
      expect(restored.payload?['count'], 42);
    });
  });

  group('PanelRegistry', () {
    setUp(() {
      PanelRegistry.instance.clear();
    });

    test('PanelRegistry регистрирует определения и преобразует в WorkspaceTab', () {
      const PanelDefinition def = PanelDefinition(
        id: 'panel_test',
        title: 'Тестовая панель',
        icon: Icons.tune_rounded,
        accentColor: Color(0xFFFFAB00),
        keepAlive: true,
        constraints: WindowConstraints(minWidth: 450.0, minHeight: 350.0),
      );

      PanelRegistry.instance.register(def);

      expect(PanelRegistry.instance.get('panel_test'), isNotNull);
      expect(PanelRegistry.instance.get('panel_test')?.title, 'Тестовая панель');

      final List<WorkspaceTab> tabs = PanelRegistry.instance.toTabs();
      expect(tabs.length, 1);
      expect(tabs.first.id, 'panel_test');
      expect(tabs.first.keepAlive, isTrue);
      expect(tabs.first.constraints?.minWidth, 450.0);
    });

    test('PanelRegistry возвращает зарегистрированный builder контента', () {
      Widget sampleBuilder(BuildContext context, WindowState win, WorkspaceTab tab) {
        return const Text('Контент панели');
      }

      final PanelDefinition def = PanelDefinition(
        id: 'panel_with_builder',
        title: 'Панель с билдером',
        builder: sampleBuilder,
      );

      PanelRegistry.instance.register(def);

      final WorkspaceContentBuilder? builder =
          PanelRegistry.instance.getBuilder('panel_with_builder');
      expect(builder, isNotNull);
    });
  });

  group('Engine Layer Math & Geometry', () {
    test('CollisionDetector корректно выявляет горизонтальное перекрытие', () {
      const WindowState a = WindowState(
        id: 'a',
        tabs: <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: 200.0,
        height: 200.0,
      );

      const WindowState overlappingB = WindowState(
        id: 'b',
        tabs: <WorkspaceTab>[],
        x: 100.0,
        y: 0.0,
        width: 200.0,
        height: 200.0,
      );

      const WindowState nonOverlappingC = WindowState(
        id: 'c',
        tabs: <WorkspaceTab>[],
        x: 250.0,
        y: 0.0,
        width: 200.0,
        height: 200.0,
      );

      expect(CollisionDetector.hasHorizontalOverlap(a, overlappingB), isTrue);
      expect(CollisionDetector.hasHorizontalOverlap(a, nonOverlappingC), isFalse);
    });

    test('MagnetSnapper притягивает координаты к левому и верхнему краю', () {
      const WindowState win = WindowState(
        id: 'target',
        tabs: <WorkspaceTab>[],
        x: 4.0,
        y: 6.0,
        width: 300.0,
        height: 200.0,
      );

      final Offset snapped = MagnetSnapper.snap(
        win: win,
        targetX: 5.0,
        targetY: 8.0,
        allWindows: const <WindowState>[],
        screenSize: const Size(1920.0, 1080.0),
        availableHeight: 1038.0,
        magnetThreshold: 10.0,
      );

      expect(snapped.dx, 0.0);
      expect(snapped.dy, 0.0);
    });

    test('MagnetSnapper игнорирует свернутые окна при прилипании к соседям', () {
      const WindowState win = WindowState(
        id: 'target',
        tabs: <WorkspaceTab>[],
        x: 100.0,
        y: 100.0,
        width: 200.0,
        height: 200.0,
      );

      const WindowState minimizedNeighbor = WindowState(
        id: 'minimized',
        tabs: <WorkspaceTab>[],
        x: 305.0,
        y: 100.0,
        width: 200.0,
        height: 200.0,
        isMinimized: true,
      );

      final Offset snapped = MagnetSnapper.snap(
        win: win,
        targetX: 102.0,
        targetY: 100.0,
        allWindows: <WindowState>[minimizedNeighbor],
        screenSize: const Size(1920.0, 1080.0),
        availableHeight: 1038.0,
        magnetThreshold: 10.0,
      );

      expect(snapped.dx, 102.0);
    });

    test('TileCalculator корректно рассчитывает тайлинг и превью зон', () {
      final SnapCalculationResult snap = TileCalculator.calculateSnap(
        globalPos: const Offset(10.0, 400.0),
        screenSize: const Size(1000.0, 800.0),
        availableHeight: 758.0,
        edgeTriggerZone: 52.0,
      );

      expect(snap.zone, SnapZone.left);
      expect(snap.previewRect?.width, 500.0);
      expect(snap.previewRect?.height, 758.0);
    });

    test('TileCalculator корректно формирует сетку 2x2', () {
      int idGen = 0;
      final List<WindowState> grid = TileCalculator.generate2x2(
        screenSize: const Size(1000.0, 800.0),
        availableHeight: 758.0,
        tabsMatrix: const <List<WorkspaceTab>>[],
        idGenerator: () => 'win_${++idGen}',
      );

      expect(grid.length, 4);
      expect(grid[0].x, 0.0);
      expect(grid[0].y, 0.0);
      expect(grid[1].x, 500.0);
      expect(grid[1].y, 0.0);
      expect(grid[2].x, 0.0);
      expect(grid[2].y, 379.0);
      expect(grid[3].x, 500.0);
      expect(grid[3].y, 379.0);
    });

    test('SeamResizer синхронно изменяет размер смежных окон и учитывает minWidth', () {
      const WindowConstraints constraints = WindowConstraints(
        minWidth: 200.0,
        minHeight: 150.0,
      );

      final List<WindowState> windows = <WindowState>[
        const WindowState(
          id: 'left_win',
          tabs: <WorkspaceTab>[],
          x: 0.0,
          y: 0.0,
          width: 500.0,
          height: 800.0,
        ),
        const WindowState(
          id: 'right_win',
          tabs: <WorkspaceTab>[],
          x: 500.0,
          y: 0.0,
          width: 500.0,
          height: 800.0,
        ),
      ];

      final List<WindowState> resized = SeamResizer.resize(
        targetId: 'left_win',
        handle: ResizeHandle.e,
        delta: const Offset(50.0, 0.0),
        windows: windows,
        screenSize: const Size(1000.0, 842.0),
        availableHeight: 800.0,
        defaultConstraints: constraints,
      );

      final WindowState left = resized.firstWhere((WindowState w) => w.id == 'left_win');
      final WindowState right = resized.firstWhere((WindowState w) => w.id == 'right_win');

      expect(left.width, 550.0);
      expect(right.x, 550.0);
      expect(right.width, 450.0);
    });
  });

  group('Theme & Localization Contracts', () {
    test('WorkspaceThemeData поддерживает темную и светлую темы с lerp', () {
      const WorkspaceThemeData dark = WorkspaceThemeData.dark();
      const WorkspaceThemeData light = WorkspaceThemeData.light();

      expect(dark.spaceBackground, const Color(0xFF0A0D14));
      expect(light.spaceBackground, const Color(0xFFF0F4F8));

      final WorkspaceThemeData mid =
          dark.lerp(light, 0.5) as WorkspaceThemeData;
      expect(mid.windowBorderRadius, 8.0);
    });

    test('WorkspaceStrings предоставляет корректные дефолтные локализации', () {
      const WorkspaceStrings ru = DefaultWorkspaceStrings();
      const WorkspaceStrings en = EnglishWorkspaceStrings();

      expect(ru.menu, 'МЕНЮ');
      expect(en.menu, 'MENU');
      expect(ru.tabCopySuffix('Таб'), 'Таб (Копия)');
      expect(en.tabCopySuffix('Tab'), 'Tab (Copy)');
    });
  });

  group('Widget Tests - WindowContentHost & State Preservation', () {
    testWidgets(
      'WindowContentHost сохраняет состояние дочернего виджета при переключении активной вкладки',
      (WidgetTester tester) async {
        const WindowState win = WindowState(
          id: 'test_win',
          activeTabIndex: 0,
          x: 0.0,
          y: 0.0,
          width: 400.0,
          height: 300.0,
          tabs: <WorkspaceTab>[
            WorkspaceTab(id: 'tab_0', title: 'Таб 0', keepAlive: true),
            WorkspaceTab(id: 'tab_1', title: 'Таб 1', keepAlive: true),
          ],
        );

        Widget buildTestHost(WindowState currentWin, int activeIdx) {
          return MaterialApp(
            home: Scaffold(
              body: WindowContentHost(
                win: currentWin,
                tab: currentWin.tabs[activeIdx],
                contentBuilder: (BuildContext ctx, WindowState w, WorkspaceTab t) {
                  if (t.id == 'tab_0') {
                    return const TextField(key: ValueKey<String>('input_field_0'));
                  }
                  return const Text('Содержимое Таб 1');
                },
              ),
            ),
          );
        }

        // 1. Отображаем первую вкладку и вводим текст
        await tester.pumpWidget(buildTestHost(win, 0));
        await tester.enterText(
          find.byKey(const ValueKey<String>('input_field_0')),
          'Текст для проверки сохранения',
        );
        expect(find.text('Текст для проверки сохранения'), findsOneWidget);

        // 2. Переключаемся на вторую вкладку
        final WindowState switchedWin = win.copyWith(activeTabIndex: 1);
        await tester.pumpWidget(buildTestHost(switchedWin, 1));
        await tester.pumpAndSettle();
        expect(find.text('Содержимое Таб 1'), findsOneWidget);

        // 3. Возвращаемся на первую вкладку
        final WindowState restoredWin = win.copyWith(activeTabIndex: 0);
        await tester.pumpWidget(buildTestHost(restoredWin, 0));
        await tester.pumpAndSettle();

        // 4. Текст должен сохраниться в поле благодаря IndexedStack
        expect(find.text('Текст для проверки сохранения'), findsOneWidget);
      },
    );
  });
}