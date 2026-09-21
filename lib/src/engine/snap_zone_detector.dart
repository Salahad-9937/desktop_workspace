import '../model/geometry_types.dart';

/// Модуль определения краевых зон тайлинга и расчета прямоугольников предпросмотра.
class SnapZoneDetector {
  const SnapZoneDetector._();

  /// Определяет целевую зону тайлинга строго по положению курсора у границ холста.
  static SnapZone detectZone({
    required double pointerX,
    required double pointerY,
    required WorkspaceRect availableArea,
    required double edgeThreshold,
  }) {
    final double relX = pointerX - availableArea.left;
    final double relY = pointerY - availableArea.top;
    final double w = availableArea.width;
    final double h = availableArea.height;

    // 1. Полноэкранный режим (верхний край экрана между угловыми зонами)
    if (relY <= edgeThreshold &&
        relX > edgeThreshold &&
        relX < (w - edgeThreshold)) {
      return SnapZone.maximize;
    }

    // 2. Левый край экрана (четверти и вертикальная половина)
    if (relX <= edgeThreshold) {
      if (relY <= h * 0.35) {
        return SnapZone.topLeft;
      }
      if (relY >= h * 0.65) {
        return SnapZone.bottomLeft;
      }
      return SnapZone.leftHalf;
    }

    // 3. Правый край экрана (четверти и вертикальная половина)
    if (relX >= (w - edgeThreshold)) {
      if (relY <= h * 0.35) {
        return SnapZone.topRight;
      }
      if (relY >= h * 0.65) {
        return SnapZone.bottomRight;
      }
      return SnapZone.rightHalf;
    }

    return SnapZone.none;
  }

  /// Вычисляет геометрический прямоугольник оверлея для заданной зоны [zone].
  static WorkspaceRect? calculatePreviewRect({
    required SnapZone zone,
    required WorkspaceRect availableArea,
  }) {
    final double left = availableArea.left;
    final double top = availableArea.top;
    final double w = availableArea.width;
    final double h = availableArea.height;
    final double halfW = w / 2.0;
    final double halfH = h / 2.0;

    return switch (zone) {
      SnapZone.none => null,
      SnapZone.maximize => availableArea,
      SnapZone.leftHalf => WorkspaceRect(
          x: left,
          y: top,
          width: halfW,
          height: h,
        ),
      SnapZone.rightHalf => WorkspaceRect(
          x: left + halfW,
          y: top,
          width: halfW,
          height: h,
        ),
      SnapZone.topLeft => WorkspaceRect(
          x: left,
          y: top,
          width: halfW,
          height: halfH,
        ),
      SnapZone.topRight => WorkspaceRect(
          x: left + halfW,
          y: top,
          width: halfW,
          height: halfH,
        ),
      SnapZone.bottomLeft => WorkspaceRect(
          x: left,
          y: top + halfH,
          width: halfW,
          height: halfH,
        ),
      SnapZone.bottomRight => WorkspaceRect(
          x: left + halfW,
          y: top + halfH,
          width: halfW,
          height: halfH,
        ),
    };
  }
}