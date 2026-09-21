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

  /// Генерирует регулярную сетку окон 2x2 с детерминированными временными метками.
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

    return <WindowState>[
      WindowState(
        id: 'win_slot_top_left',
        x: x0,
        y: y0,
        width: halfW,
        height: halfH,
        tabs: slotsTabs[0],
        snapZone: SnapZone.topLeft,
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
        createdAt: now + 3,
      ),
    ];
  }

  /// Генерирует макет пропорционального сплита из двух оконных зон.
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

      return <WindowState>[
        WindowState(
          id: 'win_split_primary',
          x: x0,
          y: y0,
          width: primaryWidth,
          height: availableArea.height,
          tabs: primaryTabs,
          snapZone: splitRatio == 0.5 ? SnapZone.leftHalf : SnapZone.none,
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
          createdAt: now + 1,
        ),
      ];
    } else {
      final double primaryHeight = availableArea.height * splitRatio;
      final double secondaryHeight = availableArea.height - primaryHeight;

      return <WindowState>[
        WindowState(
          id: 'win_split_primary',
          x: x0,
          y: y0,
          width: availableArea.width,
          height: primaryHeight,
          tabs: primaryTabs,
          createdAt: now,
        ),
        WindowState(
          id: 'win_split_secondary',
          x: x0,
          y: y0 + primaryHeight,
          width: availableArea.width,
          height: secondaryHeight,
          tabs: secondaryTabs,
          createdAt: now + 1,
        ),
      ];
    }
  }

  /// Генерирует одиночное окно, развернутое на весь холст.
  static List<WindowState> generateSolo({
    required WorkspaceRect availableArea,
    required List<WorkspaceTab> tabs,
  }) {
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
        createdAt: DateTime.now().microsecondsSinceEpoch,
      ),
    ];
  }
}