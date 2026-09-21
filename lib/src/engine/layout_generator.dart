import 'dart:math' as math;

import '../model/geometry_types.dart';
import '../model/window_state.dart';
import '../model/workspace_tab.dart';

/// Направление пропорционального разделения экрана.
enum SplitOrientation {
  /// Вертикальное разделение (левая и правая панели).
  horizontal,

  /// Горизонтальное разделение (верхняя и нижняя панели).
  vertical,
}

/// Модуль декларативной генерации стартовых макетов холста.
class LayoutGenerator {
  const LayoutGenerator._();

  /// Генерирует регулярную сетку окон 2x2 с сохранением индивидуальных точек отката.
  static List<WindowState> generateGrid2x2({
    required WorkspaceRect availableArea,
    required List<List<WorkspaceTab>> slotsTabs,
  }) {
    assert(
      slotsTabs.length == 4,
      'Для сетки 2x2 требуется передать ровно 4 набора вкладок',
    );

    final double halfW = availableArea.width / 2.0;
    final double halfH = availableArea.height / 2.0;
    final double x0 = availableArea.left;
    final double y0 = availableArea.top;
    final int now = DateTime.now().microsecondsSinceEpoch;

    final double defaultRestW = math.max(320.0, halfW * 0.85);
    final double defaultRestH = math.max(240.0, halfH * 0.85);

    return <WindowState>[
      WindowState(
        id: 'win_slot_top_left',
        x: x0,
        y: y0,
        width: halfW,
        height: halfH,
        tabs: slotsTabs[0],
        snapZone: SnapZone.topLeft,
        restoreRect: WorkspaceRect(
          x: x0 + 30.0,
          y: y0 + 30.0,
          width: defaultRestW,
          height: defaultRestH,
        ),
        createdAt: now,
      ),
      WindowState(
        id: 'win_slot_top_right',
        x: x0 + halfW,
        y: y0,
        width: halfW,
        height: halfH,
        tabs: slotsTabs[1],
        snapZone: SnapZone.topRight,
        restoreRect: WorkspaceRect(
          x: x0 + halfW - defaultRestW + 30.0,
          y: y0 + 30.0,
          width: defaultRestW,
          height: defaultRestH,
        ),
        createdAt: now + 1,
      ),
      WindowState(
        id: 'win_slot_bottom_left',
        x: x0,
        y: y0 + halfH,
        width: halfW,
        height: halfH,
        tabs: slotsTabs[2],
        snapZone: SnapZone.bottomLeft,
        restoreRect: WorkspaceRect(
          x: x0 + 30.0,
          y: y0 + halfH - defaultRestH + 30.0,
          width: defaultRestW,
          height: defaultRestH,
        ),
        createdAt: now + 2,
      ),
      WindowState(
        id: 'win_slot_bottom_right',
        x: x0 + halfW,
        y: y0 + halfH,
        width: halfW,
        height: halfH,
        tabs: slotsTabs[3],
        snapZone: SnapZone.bottomRight,
        restoreRect: WorkspaceRect(
          x: x0 + halfW - defaultRestW + 30.0,
          y: y0 + halfH - defaultRestH + 30.0,
          width: defaultRestW,
          height: defaultRestH,
        ),
        createdAt: now + 3,
      ),
    ];
  }

  /// Генерирует макет пропорционального сплита из двух оконных зон с точками отката.
  static List<WindowState> generateSplit({
    required WorkspaceRect availableArea,
    required List<WorkspaceTab> primaryTabs,
    required List<WorkspaceTab> secondaryTabs,
    SplitOrientation orientation = SplitOrientation.horizontal,
    double splitRatio = 0.5,
  }) {
    assert(
      splitRatio > 0.0 && splitRatio < 1.0,
      'splitRatio должен находиться в диапазоне (0.0, 1.0)',
    );

    final double x0 = availableArea.left;
    final double y0 = availableArea.top;
    final int now = DateTime.now().microsecondsSinceEpoch;

    if (orientation == SplitOrientation.horizontal) {
      final double primaryWidth = availableArea.width * splitRatio;
      final double secondaryWidth = availableArea.width - primaryWidth;

      final double primaryRestW = math.max(340.0, primaryWidth * 0.85);
      final double primaryRestH =
          math.max(260.0, availableArea.height * 0.7);

      final double secondaryRestW = math.max(340.0, secondaryWidth * 0.85);
      final double secondaryRestH =
          math.max(260.0, availableArea.height * 0.7);

      return <WindowState>[
        WindowState(
          id: 'win_split_primary',
          x: x0,
          y: y0,
          width: primaryWidth,
          height: availableArea.height,
          tabs: primaryTabs,
          snapZone: splitRatio == 0.5 ? SnapZone.leftHalf : SnapZone.none,
          restoreRect: WorkspaceRect(
            x: x0 + 40.0,
            y: y0 + 40.0,
            width: primaryRestW,
            height: primaryRestH,
          ),
          createdAt: now,
        ),
        WindowState(
          id: 'win_split_secondary',
          x: x0 + primaryWidth,
          y: y0,
          width: secondaryWidth,
          height: availableArea.height,
          tabs: secondaryTabs,
          snapZone: splitRatio == 0.5 ? SnapZone.rightHalf : SnapZone.none,
          restoreRect: WorkspaceRect(
            x: x0 + primaryWidth + 40.0,
            y: y0 + 60.0,
            width: secondaryRestW,
            height: secondaryRestH,
          ),
          createdAt: now + 1,
        ),
      ];
    } else {
      final double primaryHeight = availableArea.height * splitRatio;
      final double secondaryHeight = availableArea.height - primaryHeight;

      final double primaryRestW = math.max(360.0, availableArea.width * 0.75);
      final double primaryRestH = math.max(240.0, primaryHeight * 0.85);

      final double secondaryRestW = math.max(360.0, availableArea.width * 0.75);
      final double secondaryRestH = math.max(240.0, secondaryHeight * 0.85);

      return <WindowState>[
        WindowState(
          id: 'win_split_primary',
          x: x0,
          y: y0,
          width: availableArea.width,
          height: primaryHeight,
          tabs: primaryTabs,
          restoreRect: WorkspaceRect(
            x: x0 + 40.0,
            y: y0 + 40.0,
            width: primaryRestW,
            height: primaryRestH,
          ),
          createdAt: now,
        ),
        WindowState(
          id: 'win_split_secondary',
          x: x0,
          y: y0 + primaryHeight,
          width: availableArea.width,
          height: secondaryHeight,
          tabs: secondaryTabs,
          restoreRect: WorkspaceRect(
            x: x0 + 60.0,
            y: y0 + primaryHeight + 40.0,
            width: secondaryRestW,
            height: secondaryRestH,
          ),
          createdAt: now + 1,
        ),
      ];
    }
  }

  /// Генерирует одиночное окно, развернутое на весь холст с точкой отката.
  static List<WindowState> generateSolo({
    required WorkspaceRect availableArea,
    required List<WorkspaceTab> tabs,
  }) {
    final double restW = math.min(availableArea.width * 0.75, 640.0);
    final double restH = math.min(availableArea.height * 0.75, 480.0);

    return <WindowState>[
      WindowState(
        id: 'win_solo_fullscreen',
        x: availableArea.left,
        y: availableArea.top,
        width: availableArea.width,
        height: availableArea.height,
        tabs: tabs,
        isMaximized: true,
        snapZone: SnapZone.maximize,
        restoreRect: WorkspaceRect(
          x: availableArea.left + 40.0,
          y: availableArea.top + 40.0,
          width: restW,
          height: restH,
        ),
        createdAt: DateTime.now().microsecondsSinceEpoch,
      ),
    ];
  }
}