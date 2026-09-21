import '../model/geometry_types.dart';

/// Модуль определения краевых зон тайлинга и расчета прямоугольников предпросмотра.
class SnapZoneDetector {
  const SnapZoneDetector._();

  /// Определяет целевую зону тайлинга по положению курсора и физическим границам окна.
  static SnapZone detectZone({
    required double pointerX,
    required double pointerY,
    required WorkspaceRect availableArea,
    required double edgeThreshold,
    WorkspaceRect? windowRect,
  }) {
    final double relX = pointerX - availableArea.left;
    final double relY = pointerY - availableArea.top;
    final double w = availableArea.width;
    final double h = availableArea.height;

    // Триггер по курсору либо по касанию верхней границы окна к краю холста
    final bool isTopEdge = (relY <= edgeThreshold &&
            relX > edgeThreshold &&
            relX < (w - edgeThreshold)) ||
        (windowRect != null &&
            (windowRect.top - availableArea.top).abs() <= 8.0 &&
            relX > edgeThreshold &&
            relX < (w - edgeThreshold));

    if (isTopEdge) {
      return SnapZone.maximize;
    }

    // Триггер по левому краю (курсор у края либо левая граница окна прижата к краю холста)
    final bool isLeftEdge = (relX <= edgeThreshold) ||
        (windowRect != null &&
            (windowRect.left - availableArea.left).abs() <= 12.0);

    if (isLeftEdge) {
      final double effectiveY = windowRect != null
          ? (pointerY.clamp(windowRect.top, windowRect.bottom) -
              availableArea.top)
          : relY;

      if (effectiveY <= h * 0.35) {
        return SnapZone.topLeft;
      }
      if (effectiveY >= h * 0.65) {
        return SnapZone.bottomLeft;
      }
      return SnapZone.leftHalf;
    }

    // Триггер по правому краю (курсор у края либо правая граница окна прижата к краю холста)
    final bool isRightEdge = (relX >= (w - edgeThreshold)) ||
        (windowRect != null &&
            (availableArea.right - windowRect.right).abs() <= 12.0);

    if (isRightEdge) {
      final double effectiveY = windowRect != null
          ? (pointerY.clamp(windowRect.top, windowRect.bottom) -
              availableArea.top)
          : relY;

      if (effectiveY <= h * 0.35) {
        return SnapZone.topRight;
      }
      if (effectiveY >= h * 0.65) {
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