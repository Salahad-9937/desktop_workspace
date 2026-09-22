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

    test('adaptWindowOnResize возвращает исходное окно при нулевом размере нового экрана', () {
      const WindowState window = WindowState(
        id: 'win_zero',
        x: 100.0,
        y: 100.0,
        width: 300.0,
        height: 200.0,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
      );

      final WindowState adapted = BoundsClamper.adaptWindowOnResize(
        window: window,
        oldArea: area,
        newArea: const WorkspaceRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0),
        globalConstraints: const WindowConstraints(),
      );

      expect(adapted, window);
    });

    test('adaptWindowOnResize адаптирует полноэкранные окна (maximize)', () {
      const WindowState window = WindowState(
        id: 'win_max',
        x: 0.0,
        y: 0.0,
        width: 1000.0,
        height: 800.0,
        isMaximized: true,
        snapZone: SnapZone.maximize,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
      );

      const WorkspaceRect newArea = WorkspaceRect(x: 0.0, y: 0.0, width: 800.0, height: 600.0);

      final WindowState adapted = BoundsClamper.adaptWindowOnResize(
        window: window,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );

      expect(adapted.width, 800.0);
      expect(adapted.height, 600.0);
      expect(adapted.x, 0.0);
      expect(adapted.y, 0.0);
    });

    test('adaptWindowOnResize адаптирует окна в половинных зонах (leftHalf, rightHalf)', () {
      const WindowState leftWin = WindowState(
        id: 'win_left',
        x: 0.0,
        y: 0.0,
        width: 500.0,
        height: 800.0,
        snapZone: SnapZone.leftHalf,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
      );

      const WindowState rightWin = WindowState(
        id: 'win_right',
        x: 500.0,
        y: 0.0,
        width: 500.0,
        height: 800.0,
        snapZone: SnapZone.rightHalf,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2')],
      );

      const WorkspaceRect newArea = WorkspaceRect(x: 0.0, y: 0.0, width: 800.0, height: 600.0);

      final WindowState adaptedLeft = BoundsClamper.adaptWindowOnResize(
        window: leftWin,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(adaptedLeft.width, 400.0);
      expect(adaptedLeft.height, 600.0);
      expect(adaptedLeft.x, 0.0);

      final WindowState adaptedRight = BoundsClamper.adaptWindowOnResize(
        window: rightWin,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(adaptedRight.width, 400.0);
      expect(adaptedRight.height, 600.0);
      expect(adaptedRight.x, 400.0);
    });

    test('adaptWindowOnResize адаптирует окна в четвертных зонах (topLeft, topRight, bottomLeft, bottomRight)', () {
      const WindowState tl = WindowState(
        id: 'tl',
        x: 0.0,
        y: 0.0,
        width: 500.0,
        height: 400.0,
        snapZone: SnapZone.topLeft,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '1', typeId: 'v', title: '1')],
      );
      const WindowState tr = WindowState(
        id: 'tr',
        x: 500.0,
        y: 0.0,
        width: 500.0,
        height: 400.0,
        snapZone: SnapZone.topRight,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '2', typeId: 'v', title: '2')],
      );
      const WindowState bl = WindowState(
        id: 'bl',
        x: 0.0,
        y: 400.0,
        width: 500.0,
        height: 400.0,
        snapZone: SnapZone.bottomLeft,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '3', typeId: 'v', title: '3')],
      );
      const WindowState br = WindowState(
        id: 'br',
        x: 500.0,
        y: 400.0,
        width: 500.0,
        height: 400.0,
        snapZone: SnapZone.bottomRight,
        tabs: <WorkspaceTab>[WorkspaceTab(id: '4', typeId: 'v', title: '4')],
      );

      const WorkspaceRect newArea = WorkspaceRect(x: 0.0, y: 0.0, width: 800.0, height: 600.0);

      final WindowState resTL = BoundsClamper.adaptWindowOnResize(
        window: tl,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(resTL.width, 400.0);
      expect(resTL.height, 300.0);
      expect(resTL.x, 0.0);
      expect(resTL.y, 0.0);

      final WindowState resTR = BoundsClamper.adaptWindowOnResize(
        window: tr,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(resTR.width, 400.0);
      expect(resTR.height, 300.0);
      expect(resTR.x, 400.0);
      expect(resTR.y, 0.0);

      final WindowState resBL = BoundsClamper.adaptWindowOnResize(
        window: bl,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(resBL.width, 400.0);
      expect(resBL.height, 300.0);
      expect(resBL.x, 0.0);
      expect(resBL.y, 300.0);

      final WindowState resBR = BoundsClamper.adaptWindowOnResize(
        window: br,
        oldArea: area,
        newArea: newArea,
        globalConstraints: const WindowConstraints(),
      );
      expect(resBR.width, 400.0);
      expect(resBR.height, 300.0);
      expect(resBR.x, 400.0);
      expect(resBR.y, 300.0);
    });

    test('adaptWindowOnResize адаптирует плавающее окно при уменьшении холста', () {
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