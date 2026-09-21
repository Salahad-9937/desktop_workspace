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