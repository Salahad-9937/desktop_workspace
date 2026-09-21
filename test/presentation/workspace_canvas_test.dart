import 'dart:async';
import 'package:desktop_workspace/src/model/view_definition.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:desktop_workspace/src/presentation/canvas/canvas_background.dart';
import 'package:desktop_workspace/src/presentation/canvas/workspace_canvas.dart';
import 'package:desktop_workspace/src/presentation/catalog/view_catalog_palette.dart';
import 'package:desktop_workspace/src/presentation/dock/dock_window_chip.dart';
import 'package:desktop_workspace/src/presentation/dock/workspace_dock.dart';
import 'package:desktop_workspace/src/presentation/window/window_frame.dart';
import 'package:desktop_workspace/src/state/workspace_controller.dart';
import 'package:desktop_workspace/src/theme/workspace_theme.dart';
import 'package:desktop_workspace/src/theme/workspace_theme_data.dart';
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

    testWidgets('Сворачивание и восстановление окна через док-панель',
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

      expect(find.byType(WindowFrame), findsOneWidget);

      final Finder chipFinder = find.byType(DockWindowChip);
      expect(chipFinder, findsOneWidget);

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

      // Переключаем вкладку на вторую
      controller.selectTab(
        'win_solo_fullscreen',
        1,
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Экран заглушки'), findsOneWidget);

      // Возвращаем вкладку со счетчиком
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

      expect(find.text('Каталог представлений'), findsOneWidget);
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