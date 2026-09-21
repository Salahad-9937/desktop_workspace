import 'package:desktop_workspace/src/config/window_constraints.dart';
import 'package:desktop_workspace/src/engine/seam_resizer.dart';
import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeamResizer Tests', () {
    const WindowConstraints constraints = WindowConstraints(
      minWidth: 200.0,
      minHeight: 150.0,
    );

    const WindowState winA = WindowState(
      id: 'win_a',
      x: 0.0,
      y: 0.0,
      width: 400.0,
      height: 600.0,
      tabs: <WorkspaceTab>[WorkspaceTab(id: 'ta', typeId: 'v', title: 'A')],
    );

    const WindowState winB = WindowState(
      id: 'win_b',
      x: 400.0,
      y: 0.0,
      width: 400.0,
      height: 600.0,
      tabs: <WorkspaceTab>[WorkspaceTab(id: 'tb', typeId: 'v', title: 'B')],
    );

    test('Поиск и дедупликация общих швов findSharedSeams', () {
      final List<SharedSeam> seams = SeamResizer.findSharedSeams(
        windows: <WindowState>[winA, winB],
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      expect(seams.length, 1);
      expect(seams.first.isVertical, isTrue);
      expect(seams.first.position, 400.0);
      expect(seams.first.start, 0.0);
      expect(seams.first.end, 600.0);
      expect(seams.first.primaryWindowId, 'win_a');
      expect(seams.first.direction, ResizeDirection.east);
    });

    test('Слияние Т-образного стыка (1 большое окно к 2 малым окнам)', () {
      const WindowState winLeft = WindowState(
        id: 'win_left',
        x: 0.0,
        y: 0.0,
        width: 400.0,
        height: 800.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'tl', typeId: 'v', title: 'L')],
      );

      const WindowState winTopRight = WindowState(
        id: 'win_top_right',
        x: 400.0,
        y: 0.0,
        width: 400.0,
        height: 300.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'ttr', typeId: 'v', title: 'TR')],
      );

      const WindowState winBottomRight = WindowState(
        id: 'win_bottom_right',
        x: 400.0,
        y: 300.0,
        width: 400.0,
        height: 500.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 'tbr', typeId: 'v', title: 'BR')],
      );

      final List<SharedSeam> seams = SeamResizer.findSharedSeams(
        windows: <WindowState>[winLeft, winTopRight, winBottomRight],
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      final List<SharedSeam> vertical =
          seams.where((SharedSeam s) => s.isVertical).toList();
      expect(vertical.length, 1);
      expect(vertical.first.position, 400.0);
      expect(vertical.first.start, 0.0);
      expect(vertical.first.end, 800.0);
      expect(vertical.first.participantWindowIds.contains('win_left'), isTrue);
      expect(vertical.first.participantWindowIds.contains('win_top_right'), isTrue);
      expect(vertical.first.participantWindowIds.contains('win_bottom_right'), isTrue);

      final List<WindowState> resized = SeamResizer.resizeSeam(
        primaryWindow: winLeft,
        allWindows: <WindowState>[winLeft, winTopRight, winBottomRight],
        direction: ResizeDirection.east,
        deltaX: -50.0,
        deltaY: 0.0,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
        globalConstraints: constraints,
      );

      final WindowState resLeft =
          resized.firstWhere((WindowState w) => w.id == 'win_left');
      final WindowState resTR =
          resized.firstWhere((WindowState w) => w.id == 'win_top_right');
      final WindowState resBR =
          resized.firstWhere((WindowState w) => w.id == 'win_bottom_right');

      expect(resLeft.width, 350.0);
      expect(resTR.x, 350.0);
      expect(resTR.width, 450.0);
      expect(resBR.x, 350.0);
      expect(resBR.width, 450.0);
    });

    test('Обнаружение 4-Way Cross перекрестка в сетке 2x2', () {
      const WindowState tl = WindowState(
        id: 'tl',
        x: 0.0,
        y: 0.0,
        width: 400.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '1', typeId: 'v', title: '1')],
      );
      const WindowState tr = WindowState(
        id: 'tr',
        x: 400.0,
        y: 0.0,
        width: 400.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '2', typeId: 'v', title: '2')],
      );
      const WindowState bl = WindowState(
        id: 'bl',
        x: 0.0,
        y: 400.0,
        width: 400.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '3', typeId: 'v', title: '3')],
      );
      const WindowState br = WindowState(
        id: 'br',
        x: 400.0,
        y: 400.0,
        width: 400.0,
        height: 400.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '4', typeId: 'v', title: '4')],
      );

      final List<SharedSeam> seams = SeamResizer.findSharedSeams(
        windows: <WindowState>[tl, tr, bl, br],
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      final List<SeamIntersection> crosses = SeamDetector.findIntersections(
        seams: seams,
        seamEpsilon: 6.0,
      );

      expect(crosses.length, 1);
      expect(crosses.first.x, 400.0);
      expect(crosses.first.y, 400.0);
    });

    test('Детекция общего шва hasSharedSeam между соприкасающимися окнами', () {
      final bool hasSeamEast = SeamResizer.hasSharedSeam(
        primaryWindow: winA,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.east,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      final bool hasSeamWest = SeamResizer.hasSharedSeam(
        primaryWindow: winB,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.west,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      final bool hasSeamSouth = SeamResizer.hasSharedSeam(
        primaryWindow: winA,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.south,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
      );

      expect(hasSeamEast, isTrue);
      expect(hasSeamWest, isTrue);
      expect(hasSeamSouth, isFalse);
    });

    test('Синхронное пропорциональное изменение вертикального шва', () {
      final List<WindowState> result = SeamResizer.resizeSeam(
        primaryWindow: winA,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.east,
        deltaX: 50.0,
        deltaY: 0.0,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
        globalConstraints: constraints,
      );

      final WindowState updatedA =
          result.firstWhere((WindowState w) => w.id == 'win_a');
      final WindowState updatedB =
          result.firstWhere((WindowState w) => w.id == 'win_b');

      expect(updatedA.width, 450.0);
      expect(updatedB.x, 450.0);
      expect(updatedB.width, 350.0);
      expect(updatedA.width + updatedB.width, 800.0);
    });

    test('Синхронное изменение по диагонали (southEast)', () {
      final List<WindowState> result = SeamResizer.resizeSeam(
        primaryWindow: winA,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.southEast,
        deltaX: 30.0,
        deltaY: 40.0,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
        globalConstraints: constraints,
      );

      final WindowState updatedA =
          result.firstWhere((WindowState w) => w.id == 'win_a');
      final WindowState updatedB =
          result.firstWhere((WindowState w) => w.id == 'win_b');

      expect(updatedA.width, 430.0);
      expect(updatedA.height, 640.0);
      expect(updatedB.x, 430.0);
      expect(updatedB.width, 370.0);
    });

    test('Блокировка смещения шва при достижении minWidth ведомого окна', () {
      final List<WindowState> result = SeamResizer.resizeSeam(
        primaryWindow: winA,
        allWindows: <WindowState>[winA, winB],
        direction: ResizeDirection.east,
        deltaX: 300.0,
        deltaY: 0.0,
        seamEpsilon: 6.0,
        minSeamOverlap: 24.0,
        globalConstraints: constraints,
      );

      final WindowState updatedA =
          result.firstWhere((WindowState w) => w.id == 'win_a');
      final WindowState updatedB =
          result.firstWhere((WindowState w) => w.id == 'win_b');

      expect(updatedA.width, 600.0);
      expect(updatedB.x, 600.0);
      expect(updatedB.width, 200.0);
    });
  });
}