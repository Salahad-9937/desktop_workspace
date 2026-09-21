import 'package:desktop_workspace/src/config/window_constraints.dart';
import 'package:desktop_workspace/src/engine/bounds_clamper.dart';
import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:desktop_workspace/src/model/window_state.dart';
import 'package:desktop_workspace/src/model/workspace_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoundsClamper Tests', () {
    const WorkspaceRect area = WorkspaceRect(
      x: 0.0,
      y: 0.0,
      width: 1000.0,
      height: 800.0,
    );

    test('calculateAvailableArea вычитает высоту док-панели', () {
      final WorkspaceRect available = BoundsClamper.calculateAvailableArea(
        canvasWidth: 1200.0,
        canvasHeight: 900.0,
        dockHeight: 50.0,
      );
      expect(available.width, 1200.0);
      expect(available.height, 850.0);
      expect(available.left, 0.0);
      expect(available.top, 0.0);
    });

    test('clampWindowPosition удерживает заголовок внутри экрана', () {
      final (double, double) clamped = BoundsClamper.clampWindowPosition(
        targetX: -50.0,
        targetY: -20.0,
        windowWidth: 300.0,
        windowHeight: 200.0,
        availableArea: area,
        headerHeight: 36.0,
        minVisibleWidth: 48.0,
      );
      expect(clamped.$1, 0.0);
      expect(clamped.$2, 0.0);

      final (double, double) farClamped = BoundsClamper.clampWindowPosition(
        targetX: 1100.0,
        targetY: 900.0,
        windowWidth: 300.0,
        windowHeight: 200.0,
        availableArea: area,
        headerHeight: 36.0,
        minVisibleWidth: 48.0,
      );
      expect(farClamped.$1, 952.0); // 1000 - 48
      expect(farClamped.$2, 764.0); // 800 - 36
    });

    test('adaptWindowOnResize адаптирует плавающее окно при уменьшении холста',
        () {
      const WindowState window = WindowState(
        id: 'win_1',
        x: 800.0,
        y: 600.0,
        width: 300.0,
        height: 250.0,
        tabs: <WorkspaceTab>[
          WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1'),
        ],
      );

      const WorkspaceRect newArea = WorkspaceRect(
        x: 0.0,
        y: 0.0,
        width: 700.0,
        height: 500.0,
      );

      final WindowState adapted = BoundsClamper.adaptWindowOnResize(
        window: window,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(
          minWidth: 200.0,
          minHeight: 150.0,
        ),
      );

      expect(adapted.rect.right <= newArea.right, isTrue);
      expect(adapted.rect.bottom <= newArea.bottom, isTrue);
      expect(adapted.width, 300.0);
      expect(adapted.x, 400.0); // 700 - 300
      expect(adapted.y, 250.0); // 500 - 250
    });
  });
}