import 'dart:ui';
import '../../state/models/geometry_types.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_tab.dart';

/// Результат расчета зоны прилипания при перемещении окна к краям экрана.
class SnapCalculationResult {
  /// Определенная зона прилипания.
  final SnapZone zone;

  /// Геометрический прямоугольник оверлея предпросмотра.
  final Rect? previewRect;

  /// Создает экземпляр [SnapCalculationResult].
  const SnapCalculationResult({
    required this.zone,
    required this.previewRect,
  });
}

/// Вычислительные алгоритмы тайлинга, краевых зон и генерации стандартных сеток.
abstract class TileCalculator {
  /// Вычисляет активную зону прилипания и прямоугольник оверлея по координатам курсора.
  static SnapCalculationResult calculateSnap({
    required Offset globalPos,
    required Size screenSize,
    required double availableHeight,
    required double edgeTriggerZone,
  }) {
    final double w = screenSize.width;
    final double h = availableHeight;
    SnapZone zone = SnapZone.none;
    Rect rect = Rect.zero;

    if (globalPos.dy <= edgeTriggerZone) {
      zone = SnapZone.maximize;
      rect = Rect.fromLTWH(0.0, 0.0, w, h);
    } else if (globalPos.dx <= edgeTriggerZone) {
      if (globalPos.dy <= h * 0.35) {
        zone = SnapZone.topLeft;
        rect = Rect.fromLTWH(0.0, 0.0, w / 2.0, h / 2.0);
      } else if (globalPos.dy >= h * 0.65) {
        zone = SnapZone.bottomLeft;
        rect = Rect.fromLTWH(0.0, h / 2.0, w / 2.0, h / 2.0);
      } else {
        zone = SnapZone.left;
        rect = Rect.fromLTWH(0.0, 0.0, w / 2.0, h);
      }
    } else if (globalPos.dx >= w - edgeTriggerZone) {
      if (globalPos.dy <= h * 0.35) {
        zone = SnapZone.topRight;
        rect = Rect.fromLTWH(w / 2.0, 0.0, w / 2.0, h / 2.0);
      } else if (globalPos.dy >= h * 0.65) {
        zone = SnapZone.bottomRight;
        rect = Rect.fromLTWH(w / 2.0, h / 2.0, w / 2.0, h / 2.0);
      } else {
        zone = SnapZone.right;
        rect = Rect.fromLTWH(w / 2.0, 0.0, w / 2.0, h);
      }
    }

    return SnapCalculationResult(
      zone: zone,
      previewRect: zone == SnapZone.none ? null : rect,
    );
  }

  /// Применяет раскладку быстрого тайлинга к окну.
  static WindowState applyTile({
    required WindowState win,
    required String mode,
    required Size screenSize,
    required double availableHeight,
  }) {
    final double availableWidth = screenSize.width;

    Rect? restoreRect = win.restoreRect;
    if (restoreRect == null && !win.isMaximized) {
      restoreRect = Rect.fromLTWH(win.x, win.y, win.width, win.height);
    }

    double newX = win.x;
    double newY = win.y;
    double newW = win.width;
    double newH = win.height;
    bool newMaximized = false;

    switch (mode) {
      case 'left_half':
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeight;
      case 'right_half':
        newX = availableWidth / 2.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeight;
      case 'top_left':
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeight / 2.0;
      case 'top_right':
        newX = availableWidth / 2.0;
        newY = 0.0;
        newW = availableWidth / 2.0;
        newH = availableHeight / 2.0;
      case 'bottom_left':
        newX = 0.0;
        newY = availableHeight / 2.0;
        newW = availableWidth / 2.0;
        newH = availableHeight / 2.0;
      case 'bottom_right':
        newX = availableWidth / 2.0;
        newY = availableHeight / 2.0;
        newW = availableWidth / 2.0;
        newH = availableHeight / 2.0;
      case 'maximize':
        newMaximized = true;
        newX = 0.0;
        newY = 0.0;
        newW = availableWidth;
        newH = availableHeight;
      case 'restore':
        if (restoreRect != null) {
          newX = restoreRect.left;
          newY = restoreRect.top;
          newW = restoreRect.width;
          newH = restoreRect.height;
          restoreRect = null;
        }
      default:
        break;
    }

    return win.copyWith(
      x: newX,
      y: newY,
      width: newW,
      height: newH,
      isMinimized: false,
      isMaximized: newMaximized,
      restoreRect: () => restoreRect,
    );
  }

  /// Генерирует раскладку 2x2.
  static List<WindowState> generate2x2({
    required Size screenSize,
    required double availableHeight,
    required List<List<WorkspaceTab>> tabsMatrix,
    required String Function() idGenerator,
  }) {
    final double halfW = screenSize.width / 2.0;
    final double halfH = availableHeight / 2.0;

    return <WindowState>[
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.isNotEmpty ? tabsMatrix[0] : const <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.length > 1 ? tabsMatrix[1] : const <WorkspaceTab>[],
        x: halfW,
        y: 0.0,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.length > 2 ? tabsMatrix[2] : const <WorkspaceTab>[],
        x: 0.0,
        y: halfH,
        width: halfW,
        height: halfH,
      ),
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.length > 3 ? tabsMatrix[3] : const <WorkspaceTab>[],
        x: halfW,
        y: halfH,
        width: halfW,
        height: halfH,
      ),
    ];
  }

  /// Генерирует вертикальный сплит 50/50.
  static List<WindowState> generateSplit({
    required Size screenSize,
    required double availableHeight,
    required List<List<WorkspaceTab>> tabsMatrix,
    required String Function() idGenerator,
  }) {
    final double availW = screenSize.width;

    return <WindowState>[
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.isNotEmpty ? tabsMatrix[0] : const <WorkspaceTab>[],
        x: 0.0,
        y: 0.0,
        width: availW * 0.5,
        height: availableHeight,
      ),
      WindowState(
        id: idGenerator(),
        tabs: tabsMatrix.length > 1 ? tabsMatrix[1] : const <WorkspaceTab>[],
        x: availW * 0.5,
        y: 0.0,
        width: availW * 0.5,
        height: availableHeight,
      ),
    ];
  }
}