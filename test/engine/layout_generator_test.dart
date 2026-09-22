import 'package:desktop_workspace/src/engine/layout_generator.dart';
import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutGenerator Tests', () {
    const WorkspaceRect area = WorkspaceRect(
      x: 0.0,
      y: 0.0,
      width: 1200.0,
      height: 800.0,
    );

    test('generateGrid2x2 создает 4 равных квадранта', () {
      final List<WindowState> grid = LayoutGenerator.generateGrid2x2(
        availableArea: area,
        slotsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[const WorkspaceTab(id: 't1', typeId: 'v', title: '1')],
          <WorkspaceTab>[const WorkspaceTab(id: 't2', typeId: 'v', title: '2')],
          <WorkspaceTab>[const WorkspaceTab(id: 't3', typeId: 'v', title: '3')],
          <WorkspaceTab>[const WorkspaceTab(id: 't4', typeId: 'v', title: '4')],
        ],
      );

      expect(grid.length, 4);
      expect(grid[0].width, 600.0);
      expect(grid[0].height, 400.0);
      expect(grid[3].x, 600.0);
      expect(grid[3].y, 400.0);
      expect(grid[0].restoreRect, isNotNull);
    });

    test('generateSplit создает пропорциональное деление 60/40 (горизонтальное)', () {
      final List<WindowState> split = LayoutGenerator.generateSplit(
        availableArea: area,
        primaryTabs: <WorkspaceTab>[
          const WorkspaceTab(id: 'p1', typeId: 'v', title: 'P'),
        ],
        secondaryTabs: <WorkspaceTab>[
          const WorkspaceTab(id: 's1', typeId: 'v', title: 'S'),
        ],
        orientation: SplitOrientation.horizontal,
        splitRatio: 0.6,
      );

      expect(split.length, 2);
      expect(split[0].width, 720.0);
      expect(split[1].width, 480.0);
      expect(split[1].x, 720.0);
      expect(split[0].restoreRect, isNotNull);
      expect(split[1].restoreRect, isNotNull);
    });

    test('generateSplit создает вертикальное разделение (SplitOrientation.vertical)', () {
      final List<WindowState> split = LayoutGenerator.generateSplit(
        availableArea: area,
        primaryTabs: <WorkspaceTab>[
          const WorkspaceTab(id: 'top_1', typeId: 'v', title: 'Top'),
        ],
        secondaryTabs: <WorkspaceTab>[
          const WorkspaceTab(id: 'bottom_1', typeId: 'v', title: 'Bottom'),
        ],
        orientation: SplitOrientation.vertical,
        splitRatio: 0.5,
      );

      expect(split.length, 2);
      expect(split[0].width, 1200.0);
      expect(split[0].height, 400.0);
      expect(split[1].width, 1200.0);
      expect(split[1].height, 400.0);
      expect(split[1].y, 400.0);
      expect(split[0].restoreRect, isNotNull);
      expect(split[1].restoreRect, isNotNull);
    });

    test('generateSolo создает полноэкранное окно с точкой отката', () {
      final List<WindowState> solo = LayoutGenerator.generateSolo(
        availableArea: area,
        tabs: <WorkspaceTab>[
          const WorkspaceTab(id: 's1', typeId: 'v', title: 'Solo'),
        ],
      );

      expect(solo.length, 1);
      expect(solo.first.width, 1200.0);
      expect(solo.first.height, 800.0);
      expect(solo.first.isMaximized, isTrue);
      expect(solo.first.snapZone, SnapZone.maximize);
      expect(solo.first.restoreRect, isNotNull);
    });
  });
}