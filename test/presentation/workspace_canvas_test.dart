import 'dart:async';
import 'package:desktop_workspace/src/model/view_definition.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:desktop_workspace/src/presentation/canvas/canvas_background.dart';
import 'package:desktop_workspace/src/presentation/canvas/shared_seam_overlay.dart';
import 'package:desktop_workspace/src/presentation/canvas/snap_preview_box.dart';
import 'package:desktop_workspace/src/presentation/canvas/workspace_canvas.dart';
import 'package:desktop_workspace/src/presentation/catalog/view_catalog_palette.dart';
import 'package:desktop_workspace/src/presentation/dock/dock_hover_preview.dart';
import 'package:desktop_workspace/src/presentation/dock/dock_window_chip.dart';
import 'package:desktop_workspace/src/presentation/dock/workspace_dock.dart';
import 'package:desktop_workspace/src/presentation/window/tab_chip.dart';
import 'package:desktop_workspace/src/presentation/window/tab_drop_indicator.dart';
import 'package:desktop_workspace/src/presentation/window/window_frame.dart';
import 'package:desktop_workspace/src/state/workspace_controller.dart';
import 'package:desktop_workspace/src/state/workspace_state.dart';
import 'package:desktop_workspace/src/theme/workspace_theme.dart';
import 'package:desktop_workspace/src/theme/workspace_theme_data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workspace Presentation Tests (Stage 5)', () {
    testWidgets('Рендеринг холста, оконных фреймов и док-панели',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(
                    views: <ViewDefinition>[],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[
            const WorkspaceTab(
              id: 'tab_test_1',
              typeId: 'type_test_1',
              title: 'Тест 1',
            ),
          ],
          <WorkspaceTab>[
            const WorkspaceTab(
              id: 'tab_test_2',
              typeId: 'type_test_2',
              title: 'Тест 2',
            ),
          ],
        ],
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(CanvasBackground), findsOneWidget);
      expect(find.byType(WorkspaceDock), findsOneWidget);
      expect(find.byType(WindowFrame), findsNWidgets(2));
      expect(find.byType(DockWindowChip), findsNWidgets(2));
    });

    testWidgets('TabDropIndicator отрисовывает маркер слева и справа',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                TabDropIndicator(isLeft: true, color: Colors.cyan),
                TabDropIndicator(isLeft: false, color: Colors.cyan),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TabDropIndicator), findsNWidgets(2));
    });

    testWidgets('Сетка 2x2 и масштабирование через 4-Way Cross перекресток',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(views: <ViewDefinition>[]);
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1000.0, 800.0);
      controller.applyPresetGrid(<List<WorkspaceTab>>[
        <WorkspaceTab>[const WorkspaceTab(id: 't1', typeId: 'v1', title: '1')],
        <WorkspaceTab>[const WorkspaceTab(id: 't2', typeId: 'v2', title: '2')],
        <WorkspaceTab>[const WorkspaceTab(id: 't3', typeId: 'v3', title: '3')],
        <WorkspaceTab>[const WorkspaceTab(id: 't4', typeId: 'v4', title: '4')],
      ]);

      await tester.pump();
      await tester.pump();

      // Проверяем наличие оверлея швов и 4 окон
      expect(find.byType(SharedSeamOverlay), findsOneWidget);
      expect(find.byType(WindowFrame), findsNWidgets(4));

      // Перекресток находится в центре (x: 500.0, y: 376.0 с учетом дока 48px: (800 - 48)/2 = 376.0)
      const Offset centerCross = Offset(500.0, 376.0);
      final TestGesture drag =
          await tester.startGesture(centerCross, kind: PointerDeviceKind.mouse);
      await drag.moveBy(const Offset(30.0, 20.0));
      await tester.pump();
      await drag.up();
      await tester.pump();

      final WorkspaceState state = capturedRef.read(workspaceControllerProvider);
      final WindowState tl =
          state.windows.firstWhere((WindowState w) => w.id == 'win_slot_top_left');
      expect(tl.width, 530.0);
      expect(tl.height, 396.0);
    });

    testWidgets(
        'Отображение заголовка на активном чипе и закрытие по кнопке-крестику',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(
                    views: <ViewDefinition>[],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSolo(
        <WorkspaceTab>[
          const WorkspaceTab(
            id: 'tab_active_test',
            typeId: 'type_test',
            title: 'Интерактивная панель',
          ),
          const WorkspaceTab(
            id: 'tab_inactive_test',
            typeId: 'type_test_2',
            title: 'Второй экран',
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      final Finder activeTabTitleFinder = find.descendant(
        of: find.byType(TabChip).first,
        matching: find.text('Интерактивная панель'),
      );
      expect(activeTabTitleFinder, findsOneWidget);

      final Finder closeBtnFinder = find.descendant(
        of: find.byType(TabChip).first,
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeBtnFinder, findsOneWidget);

      await tester.tap(closeBtnFinder);
      await tester.pump();
      await tester.pump();

      final WindowState win =
          capturedRef.read(workspaceControllerProvider).windows.first;
      expect(win.tabs.length, 1);
      expect(win.tabs.first.id, 'tab_inactive_test');
    });

    testWidgets('Контекстное меню вкладки по правому клику (дублирование)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(
                    views: <ViewDefinition>[],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSolo(
        <WorkspaceTab>[
          const WorkspaceTab(
            id: 'tab_menu_test',
            typeId: 'type_test',
            title: 'Исходная вкладка',
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      // Правый клик мыши по чипу вкладки для открытия контекстного меню
      final Finder chipFinder = find.byType(TabChip).first;
      await tester.tap(chipFinder, buttons: kSecondaryMouseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Дублировать'), findsOneWidget);
      expect(find.text('Закрыть'), findsOneWidget);

      await tester.tap(find.text('Дублировать'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final WindowState win =
          capturedRef.read(workspaceControllerProvider).windows.first;
      expect(win.tabs.length, 2);
      expect(win.tabs[1].title, contains('Исходная вкладка (Копия)'));
    });

    testWidgets('Сворачивание, восстановление и Hover Preview в док-панели',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(
                    views: <ViewDefinition>[],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSolo(
        <WorkspaceTab>[
          const WorkspaceTab(
            id: 'tab_solo',
            typeId: 'type_solo',
            title: 'Панель Соло',
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      final Finder chipFinder = find.byType(DockWindowChip);
      expect(chipFinder, findsOneWidget);

      final TestGesture hoverGesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(hoverGesture.removePointer);

      await hoverGesture.addPointer(location: tester.getCenter(chipFinder));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DockHoverPreview), findsOneWidget);

      await hoverGesture.moveTo(const Offset(10.0, 10.0));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      await tester.tap(chipFinder);
      await tester.pump();
      await tester.pump();

      expect(
        capturedRef
            .read(workspaceControllerProvider)
            .windows
            .first
            .isMinimized,
        isTrue,
      );

      await tester.tap(chipFinder);
      await tester.pump();
      await tester.pump();

      expect(
        capturedRef
            .read(workspaceControllerProvider)
            .windows
            .first
            .isMinimized,
        isFalse,
      );
    });

    testWidgets('Отрисовка контура предпросмотра SnapPreviewBox',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return const WorkspaceCanvas(views: <ViewDefinition>[]);
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSolo(
        <WorkspaceTab>[const WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
      );

      controller.moveWindow(
        windowId: 'win_solo_fullscreen',
        deltaX: 0.0,
        deltaY: -300.0,
        pointerX: 640.0,
        pointerY: 10.0,
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(SnapPreviewBox), findsOneWidget);
      expect(capturedRef.read(workspaceControllerProvider).snapPreviewRect, isNotNull);
    });

    testWidgets(
        'Сохранение состояния ввода при переключении табов (keepAlive: true)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280.0, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      final List<ViewDefinition> views = <ViewDefinition>[
        ViewDefinition(
          typeId: 'counter_view',
          title: 'Счетчик',
          builder: (BuildContext context, _, __) => const _StatefulCounter(),
        ),
        ViewDefinition(
          typeId: 'dummy_view',
          title: 'Второй экран',
          builder: (BuildContext context, _, __) =>
              const Text('Экран заглушки'),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: WorkspaceTheme(
            data: const WorkspaceThemeData.dark(),
            child: MaterialApp(
              home: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  capturedRef = ref;
                  return WorkspaceCanvas(views: views);
                },
              ),
            ),
          ),
        ),
      );

      final WorkspaceController controller =
          capturedRef.read(workspaceControllerProvider.notifier);
      controller.updateViewportSize(1280.0, 800.0);
      controller.applyPresetSolo(
        <WorkspaceTab>[
          const WorkspaceTab(
            id: 'tab_c',
            typeId: 'counter_view',
            title: 'Счетчик',
            keepAlive: true,
          ),
          const WorkspaceTab(
            id: 'tab_d',
            typeId: 'dummy_view',
            title: 'Заглушка',
            keepAlive: true,
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Значение: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Значение: 1'), findsOneWidget);

      controller.selectTab(
        'win_solo_fullscreen',
        1,
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Экран заглушки'), findsOneWidget);

      controller.selectTab(
        'win_solo_fullscreen',
        0,
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Значение: 1'), findsOneWidget);
    });

    testWidgets('Отображение модального диалога ViewCatalogPalette',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        WorkspaceTheme(
          data: const WorkspaceThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      unawaited(
                        ViewCatalogPalette.show(
                          context: context,
                          definitions: <ViewDefinition>[
                            ViewDefinition(
                              typeId: 'palette_item',
                              title: 'Тестовый компонент',
                              builder: (_, __, ___) => const SizedBox(),
                            ),
                          ],
                          currentWindows: const <WindowState>[],
                          onSelectDefinition: (_, __) {},
                        ),
                      );
                    },
                    child: const Text('Открыть каталог'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Открыть каталог'));
      await tester.pumpAndSettle();

      expect(find.text('Панели и компоненты'), findsOneWidget);
      expect(find.text('Тестовый компонент'), findsOneWidget);
    });
  });
}

class _StatefulCounter extends StatefulWidget {
  const _StatefulCounter();

  @override
  State<_StatefulCounter> createState() => _StatefulCounterState();
}

class _StatefulCounterState extends State<_StatefulCounter> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('Значение: $_counter'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => setState(() => _counter++),
        ),
      ],
    );
  }
}