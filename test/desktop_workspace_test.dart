import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowState & WorkspaceTab Models', () {
    test('WindowState инициализируется с корректными параметрами', () {
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
    });

    test('WorkspaceTab сериализуется и десериализуется через JSON', () {
      const WorkspaceTab original = WorkspaceTab(
        id: 'tab_json',
        title: 'Тест JSON',
        icon: Icons.layers_rounded,
        accentColor: Color(0xFF00E5FF),
        payload: <String, Object?>{'key': 'value', 'count': 42},
      );

      final Map<String, Object?> json = original.toJson();
      final WorkspaceTab restored = WorkspaceTab.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.icon?.codePoint, original.icon?.codePoint);
      expect(restored.accentColor?.toARGB32(), original.accentColor?.toARGB32());
      expect(restored.payload?['key'], 'value');
      expect(restored.payload?['count'], 42);
    });

    test('PanelDefinition преобразуется в WorkspaceTab', () {
      const PanelDefinition definition = PanelDefinition(
        id: 'panel_def',
        title: 'Панель определения',
        icon: Icons.tune_rounded,
        accentColor: Color(0xFFFFAB00),
      );

      final WorkspaceTab tab = definition.toTab(
        payload: <String, Object?>{'origin': 'definition'},
      );

      expect(tab.id, definition.id);
      expect(tab.title, definition.title);
      expect(tab.icon, definition.icon);
      expect(tab.accentColor, definition.accentColor);
      expect(tab.payload?['origin'], 'definition');
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

    test('TileCalculator корректно рассчитывает тайлинг левой половины', () {
      const WindowState win = WindowState(
        id: 'win_tile',
        tabs: <WorkspaceTab>[],
        x: 100.0,
        y: 100.0,
        width: 400.0,
        height: 300.0,
      );

      final WindowState tiled = TileCalculator.applyTile(
        win: win,
        mode: 'left_half',
        screenSize: const Size(1000.0, 800.0),
        availableHeight: 758.0,
      );

      expect(tiled.x, 0.0);
      expect(tiled.y, 0.0);
      expect(tiled.width, 500.0);
      expect(tiled.height, 758.0);
      expect(tiled.restoreRect, isNotNull);
    });
  });
}