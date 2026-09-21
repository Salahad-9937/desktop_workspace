import 'dart:math' as math;

import '../config/window_constraints.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';

/// Вычислительный модуль контроля границ и удержания окон внутри видимой зоны.
class BoundsClamper {
  const BoundsClamper._();

  /// Вычисляет полезную рабочую область холста за вычетом зарезервированной док-панели.
  static WorkspaceRect calculateAvailableArea({
    required double canvasWidth,
    required double canvasHeight,
    required double dockHeight,
  }) {
    final double safeWidth = math.max(0.0, canvasWidth);
    final double safeHeight = math.max(0.0, canvasHeight - dockHeight);
    return WorkspaceRect(
      x: 0.0,
      y: 0.0,
      width: safeWidth,
      height: safeHeight,
    );
  }

  /// Выполняет пространственный зажим координат окна с сохранением видимости заголовка.
  static (double x, double y) clampWindowPosition({
    required double targetX,
    required double targetY,
    required double windowWidth,
    required double windowHeight,
    required WorkspaceRect availableArea,
    required double headerHeight,
    required double minVisibleWidth,
  }) {
    final double maxX = math.max(
      0.0,
      availableArea.width - math.min(minVisibleWidth, windowWidth),
    );
    final double maxY = math.max(
      0.0,
      availableArea.height - headerHeight,
    );

    final double clampedX = targetX.clamp(0.0, maxX);
    final double clampedY = targetY.clamp(0.0, maxY);

    return (clampedX, clampedY);
  }

  /// Адаптирует геометрические параметры окна при изменении размеров родительского экрана.
  static WindowState adaptWindowOnResize({
    required WindowState window,
    required WorkspaceRect oldArea,
    required WorkspaceRect newArea,
    required WindowConstraints globalConstraints,
  }) {
    if (newArea.width <= 0.0 || newArea.height <= 0.0) {
      return window;
    }

    final WindowConstraints constraints =
        window.resolveEffectiveConstraints(globalConstraints);

    if (window.isMaximized || window.snapZone == SnapZone.maximize) {
      return window.copyWith(
        x: newArea.x,
        y: newArea.y,
        width: newArea.width,
        height: newArea.height,
      );
    }

    if (window.snapZone == SnapZone.leftHalf) {
      return window.copyWith(
        x: newArea.x,
        y: newArea.y,
        width: newArea.width / 2.0,
        height: newArea.height,
      );
    }

    if (window.snapZone == SnapZone.rightHalf) {
      return window.copyWith(
        x: newArea.x + (newArea.width / 2.0),
        y: newArea.y,
        width: newArea.width / 2.0,
        height: newArea.height,
      );
    }

    if (window.snapZone == SnapZone.topLeft) {
      return window.copyWith(
        x: newArea.x,
        y: newArea.y,
        width: newArea.width / 2.0,
        height: newArea.height / 2.0,
      );
    }

    if (window.snapZone == SnapZone.topRight) {
      return window.copyWith(
        x: newArea.x + (newArea.width / 2.0),
        y: newArea.y,
        width: newArea.width / 2.0,
        height: newArea.height / 2.0,
      );
    }

    if (window.snapZone == SnapZone.bottomLeft) {
      return window.copyWith(
        x: newArea.x,
        y: newArea.y + (newArea.height / 2.0),
        width: newArea.width / 2.0,
        height: newArea.height / 2.0,
      );
    }

    if (window.snapZone == SnapZone.bottomRight) {
      return window.copyWith(
        x: newArea.x + (newArea.width / 2.0),
        y: newArea.y + (newArea.height / 2.0),
        width: newArea.width / 2.0,
        height: newArea.height / 2.0,
      );
    }

    final double adaptedWidth = constraints.clampWidth(
      math.min(window.width, newArea.width),
    );
    final double adaptedHeight = constraints.clampHeight(
      math.min(window.height, newArea.height),
    );

    double adaptedX = window.x;
    double adaptedY = window.y;

    if (adaptedX + adaptedWidth > newArea.right) {
      adaptedX = math.max(0.0, newArea.right - adaptedWidth);
    }
    if (adaptedY + adaptedHeight > newArea.bottom) {
      adaptedY = math.max(0.0, newArea.bottom - adaptedHeight);
    }

    return window.copyWith(
      x: adaptedX,
      y: adaptedY,
      width: adaptedWidth,
      height: adaptedHeight,
    );
  }
}