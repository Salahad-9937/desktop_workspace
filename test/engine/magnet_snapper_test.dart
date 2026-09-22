import 'package:desktop_workspace/src/engine/magnet_snapper.dart';
import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagnetSnapper Tests', () {
    const WorkspaceRect area = WorkspaceRect(
      x: 0.0,
      y: 0.0,
      width: 1000.0,
      height: 800.0,
    );

    test('Притягивание к левой и верхней границе холста', () {
      final (double x, double y) snapped = MagnetSnapper.snapPosition(
        targetX: 5.0,
        targetY: 8.0,
        width: 200.0,
        height: 150.0,
        availableArea: area,
        otherWindows: <WindowState>[],
        magnetThreshold: 10.0,
        minOverlap: 20.0,
      );
      expect(snapped.$1, 0.0);
      expect(snapped.$2, 0.0);
    });

    test('Притягивание к правой и нижней границе холста', () {
      final (double x, double y) snapped = MagnetSnapper.snapPosition(
        targetX: 795.0, // 1000 - 200 - 5
        targetY: 644.0, // 800 - 150 - 6
        width: 200.0,
        height: 150.0,
        availableArea: area,
        otherWindows: <WindowState>[],
        magnetThreshold: 10.0,
        minOverlap: 20.0,
      );
      expect(snapped.$1, 800.0);
      expect(snapped.$2, 650.0);
    });

    test('Притягивание ребра к соседнему окну (стык в стык)', () {
      const WindowState passiveWindow = WindowState(
        id: 'passive_1',
        x: 100.0,
        y: 100.0,
        width: 200.0,
        height: 300.0,
        tabs: <WorkspaceTab>[
          WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
        ],
      );

      final (double x, double y) snapped = MagnetSnapper.snapPosition(
        targetX: 304.0, // 100 + 200 + 4 (зазор 4px к правому ребру)
        targetY: 150.0,
        width: 150.0,
        height: 150.0,
        availableArea: area,
        otherWindows: <WindowState>[passiveWindow],
        magnetThreshold: 10.0,
        minOverlap: 20.0,
      );

      expect(snapped.$1, 300.0); // примагнитилось к right = 300.0
      expect(snapped.$2, 150.0);
    });

    test('snapPosition: вертикальное притягивание к верхней и нижней грани соседа', () {
      const WindowState neighbor = WindowState(
        id: 'win_neighbor',
        x: 100.0,
        y: 100.0,
        width: 300.0,
        height: 200.0, // bottom = 300.0
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'n', typeId: 'v', title: 'N')],
      );

      // Стыковка сверху к соседу: targetY + height = 295.0 (зазор 5px до neighbor.top = 100) -> примагничивание targetY к 100 - 100 = 0
      final (double, double) snapTop = MagnetSnapper.snapPosition(
        targetX: 150.0,
        targetY: 305.0, // зазор 5px от neighbor.bottom = 300.0
        width: 150.0,
        height: 100.0,
        availableArea: area,
        otherWindows: <WindowState>[neighbor],
        magnetThreshold: 10.0,
        minOverlap: 20.0,
      );
      expect(snapTop.$2, 300.0);
    });

    test('snapResizeEdge: примагничивание правого ребра к левой грани соседа', () {
      const WindowState neighbor = WindowState(
        id: 'win_neighbor',
        x: 500.0,
        y: 100.0,
        width: 300.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'n', typeId: 'v', title: 'N')],
      );

      const WorkspaceRect current = WorkspaceRect(
        x: 100.0,
        y: 100.0,
        width: 395.0, // правое ребро на 495.0 (зазор 5px до соседа 500.0)
        height: 400.0,
      );

      final double snapped = MagnetSnapper.snapResizeEdge(
        rawEdge: 495.0,
        direction: ResizeDirection.east,
        currentRect: current,
        availableArea: area,
        otherWindows: <WindowState>[neighbor],
        magnetThreshold: 10.0,
        minOverlap: 24.0,
      );

      expect(snapped, 500.0);
    });

    test('snapResizeEdge: вертикальное притягивание ребер к границам экрана и соседним окнам', () {
      const WindowState neighbor = WindowState(
        id: 'win_neighbor_y',
        x: 100.0,
        y: 400.0,
        width: 300.0,
        height: 300.0, // bottom = 700.0
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'n', typeId: 'v', title: 'N')],
      );

      const WorkspaceRect current = WorkspaceRect(
        x: 100.0,
        y: 100.0,
        width: 300.0,
        height: 295.0, // южное ребро на 395.0 (зазор 5px до соседа top = 400.0)
      );

      // Притягивание южного ребра к верхней грани соседа
      final double snapSouth = MagnetSnapper.snapResizeEdge(
        rawEdge: 395.0,
        direction: ResizeDirection.south,
        currentRect: current,
        availableArea: area,
        otherWindows: <WindowState>[neighbor],
        magnetThreshold: 10.0,
        minOverlap: 24.0,
      );
      expect(snapSouth, 400.0);

      // Притягивание южного ребра к нижнему краю доступной области холста (800.0)
      final double snapBottomEdge = MagnetSnapper.snapResizeEdge(
        rawEdge: 795.0,
        direction: ResizeDirection.south,
        currentRect: current,
        availableArea: area,
        otherWindows: <WindowState>[],
        magnetThreshold: 10.0,
        minOverlap: 24.0,
      );
      expect(snapBottomEdge, 800.0);

      // Притягивание северного ребра к верхнему краю экрана (0.0)
      final double snapTopEdge = MagnetSnapper.snapResizeEdge(
        rawEdge: 6.0,
        direction: ResizeDirection.north,
        currentRect: current,
        availableArea: area,
        otherWindows: <WindowState>[],
        magnetThreshold: 10.0,
        minOverlap: 24.0,
      );
      expect(snapTopEdge, 0.0);
    });

    test('snapResizeEdge: свободный проход за пределы порога магнита', () {
      const WindowState neighbor = WindowState(
        id: 'win_neighbor',
        x: 500.0,
        y: 100.0,
        width: 300.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'n', typeId: 'v', title: 'N')],
      );

      const WorkspaceRect current = WorkspaceRect(
        x: 100.0,
        y: 100.0,
        width: 415.0, // правое ребро на 515.0 (превысило порог 10px на 5px)
        height: 400.0,
      );

      final double notSnapped = MagnetSnapper.snapResizeEdge(
        rawEdge: 515.0,
        direction: ResizeDirection.east,
        currentRect: current,
        availableArea: area,
        otherWindows: <WindowState>[neighbor],
        magnetThreshold: 10.0,
        minOverlap: 24.0,
      );

      expect(notSnapped, 515.0);
    });
  });
}