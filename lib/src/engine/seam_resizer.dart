import 'dart:math' as math;

import '../config/window_constraints.dart';
import '../model/geometry_types.dart';
import '../model/window_state.dart';

/// Модуль синхронного масштабирования группы состыкованных окон по общему шву.
class SeamResizer {
  const SeamResizer._();

  /// Выполняет синхронную деформацию состыкованных окон вдоль активного вектора (включая диагонали).
  static List<WindowState> resizeSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double deltaX,
    required double deltaY,
    required double seamEpsilon,
    required double minSeamOverlap,
    required WindowConstraints globalConstraints,
  }) {
    if (direction == ResizeDirection.none) {
      return allWindows;
    }

    final Map<String, WindowState> updatedWindows = <String, WindowState>{
      for (final WindowState w in allWindows) w.id: w,
    };

    // 1. Горизонтальная составляющая (Запад / Восток / Диагонали)
    if (direction.affectsLeft || direction.affectsRight) {
      final ResizeDirection hDirection = direction.affectsRight
          ? ResizeDirection.east
          : ResizeDirection.west;

      _applyHorizontalSeam(
        primaryWindow: primaryWindow,
        allWindows: allWindows,
        direction: hDirection,
        deltaX: deltaX,
        seamEpsilon: seamEpsilon,
        minSeamOverlap: minSeamOverlap,
        globalConstraints: globalConstraints,
        updatedMap: updatedWindows,
      );
    }

    // 2. Вертикальная составляющая (Север / Юг / Диагонали)
    if (direction.affectsTop || direction.affectsBottom) {
      final ResizeDirection vDirection = direction.affectsBottom
          ? ResizeDirection.south
          : ResizeDirection.north;

      final WindowState currentPrimary =
          updatedWindows[primaryWindow.id] ?? primaryWindow;
      final List<WindowState> currentAll = allWindows
          .map((WindowState w) => updatedWindows[w.id] ?? w)
          .toList(growable: false);

      _applyVerticalSeam(
        primaryWindow: currentPrimary,
        allWindows: currentAll,
        direction: vDirection,
        deltaY: deltaY,
        seamEpsilon: seamEpsilon,
        minSeamOverlap: minSeamOverlap,
        globalConstraints: globalConstraints,
        updatedMap: updatedWindows,
      );
    }

    return allWindows
        .map((WindowState w) => updatedWindows[w.id] ?? w)
        .toList(growable: false);
  }

  static void _applyHorizontalSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double deltaX,
    required double seamEpsilon,
    required double minSeamOverlap,
    required WindowConstraints globalConstraints,
    required Map<String, WindowState> updatedMap,
  }) {
    final WindowConstraints primaryConstraints =
        primaryWindow.resolveEffectiveConstraints(globalConstraints);

    if (direction == ResizeDirection.east) {
      final double seamPosition = primaryWindow.rect.right;
      final List<WindowState> rightNeighbors = allWindows.where((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isSeamContinuous =
            (w.rect.left - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isSeamContinuous && overlapY >= minSeamOverlap;
      }).toList();

      if (rightNeighbors.isEmpty) {
        final double newWidth =
            primaryConstraints.clampWidth(primaryWindow.width + deltaX);
        updatedMap[primaryWindow.id] =
            primaryWindow.copyWith(width: newWidth);
        return;
      }

      double maxAllowedPositive = primaryConstraints.maxWidth - primaryWindow.width;
      double maxAllowedNegative = primaryWindow.width - primaryConstraints.minWidth;

      for (final WindowState neighbor in rightNeighbors) {
        final WindowConstraints nConstraints =
            neighbor.resolveEffectiveConstraints(globalConstraints);
        final double neighborShrink = neighbor.width - nConstraints.minWidth;
        final double neighborGrow = nConstraints.maxWidth - neighbor.width;

        maxAllowedPositive = math.min(maxAllowedPositive, neighborShrink);
        maxAllowedNegative = math.min(maxAllowedNegative, neighborGrow);
      }

      final double effectiveDelta =
          deltaX.clamp(-maxAllowedNegative, maxAllowedPositive);

      updatedMap[primaryWindow.id] = primaryWindow.copyWith(
        width: primaryWindow.width + effectiveDelta,
      );

      for (final WindowState neighbor in rightNeighbors) {
        updatedMap[neighbor.id] = neighbor.copyWith(
          x: neighbor.x + effectiveDelta,
          width: neighbor.width - effectiveDelta,
        );
      }
    } else if (direction == ResizeDirection.west) {
      final double seamPosition = primaryWindow.rect.left;
      final List<WindowState> leftNeighbors = allWindows.where((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isSeamContinuous =
            (w.rect.right - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isSeamContinuous && overlapY >= minSeamOverlap;
      }).toList();

      if (leftNeighbors.isEmpty) {
        final double targetWidth = primaryWindow.width - deltaX;
        final double clampedWidth = primaryConstraints.clampWidth(targetWidth);
        final double appliedDelta = primaryWindow.width - clampedWidth;
        updatedMap[primaryWindow.id] = primaryWindow.copyWith(
          x: primaryWindow.x + appliedDelta,
          width: clampedWidth,
        );
        return;
      }

      double maxAllowedPrimaryShrink =
          primaryWindow.width - primaryConstraints.minWidth;
      double maxAllowedPrimaryGrow =
          primaryConstraints.maxWidth - primaryWindow.width;

      for (final WindowState neighbor in leftNeighbors) {
        final WindowConstraints nConstraints =
            neighbor.resolveEffectiveConstraints(globalConstraints);
        final double neighborGrow = nConstraints.maxWidth - neighbor.width;
        final double neighborShrink = neighbor.width - nConstraints.minWidth;

        maxAllowedPrimaryShrink = math.min(maxAllowedPrimaryShrink, neighborGrow);
        maxAllowedPrimaryGrow = math.min(maxAllowedPrimaryGrow, neighborShrink);
      }

      final double effectiveDelta =
          deltaX.clamp(-maxAllowedPrimaryGrow, maxAllowedPrimaryShrink);

      updatedMap[primaryWindow.id] = primaryWindow.copyWith(
        x: primaryWindow.x + effectiveDelta,
        width: primaryWindow.width - effectiveDelta,
      );

      for (final WindowState neighbor in leftNeighbors) {
        updatedMap[neighbor.id] = neighbor.copyWith(
          width: neighbor.width + effectiveDelta,
        );
      }
    }
  }

  static void _applyVerticalSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double deltaY,
    required double seamEpsilon,
    required double minSeamOverlap,
    required WindowConstraints globalConstraints,
    required Map<String, WindowState> updatedMap,
  }) {
    final WindowConstraints primaryConstraints =
        primaryWindow.resolveEffectiveConstraints(globalConstraints);

    if (direction == ResizeDirection.south) {
      final double seamPosition = primaryWindow.rect.bottom;
      final List<WindowState> bottomNeighbors = allWindows.where((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isSeamContinuous =
            (w.rect.top - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isSeamContinuous && overlapX >= minSeamOverlap;
      }).toList();

      if (bottomNeighbors.isEmpty) {
        final double newHeight =
            primaryConstraints.clampHeight(primaryWindow.height + deltaY);
        updatedMap[primaryWindow.id] =
            primaryWindow.copyWith(height: newHeight);
        return;
      }

      double maxAllowedPositive = primaryConstraints.maxHeight - primaryWindow.height;
      double maxAllowedNegative = primaryWindow.height - primaryConstraints.minHeight;

      for (final WindowState neighbor in bottomNeighbors) {
        final WindowConstraints nConstraints =
            neighbor.resolveEffectiveConstraints(globalConstraints);
        final double neighborShrink = neighbor.height - nConstraints.minHeight;
        final double neighborGrow = nConstraints.maxHeight - neighbor.height;

        maxAllowedPositive = math.min(maxAllowedPositive, neighborShrink);
        maxAllowedNegative = math.min(maxAllowedNegative, neighborGrow);
      }

      final double effectiveDelta =
          deltaY.clamp(-maxAllowedNegative, maxAllowedPositive);

      updatedMap[primaryWindow.id] = primaryWindow.copyWith(
        height: primaryWindow.height + effectiveDelta,
      );

      for (final WindowState neighbor in bottomNeighbors) {
        updatedMap[neighbor.id] = neighbor.copyWith(
          y: neighbor.y + effectiveDelta,
          height: neighbor.height - effectiveDelta,
        );
      }
    } else if (direction == ResizeDirection.north) {
      final double seamPosition = primaryWindow.rect.top;
      final List<WindowState> topNeighbors = allWindows.where((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isSeamContinuous =
            (w.rect.bottom - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isSeamContinuous && overlapX >= minSeamOverlap;
      }).toList();

      if (topNeighbors.isEmpty) {
        final double targetHeight = primaryWindow.height - deltaY;
        final double clampedHeight = primaryConstraints.clampHeight(targetHeight);
        final double appliedDelta = primaryWindow.height - clampedHeight;
        updatedMap[primaryWindow.id] = primaryWindow.copyWith(
          y: primaryWindow.y + appliedDelta,
          height: clampedHeight,
        );
        return;
      }

      double maxAllowedPrimaryShrink =
          primaryWindow.height - primaryConstraints.minHeight;
      double maxAllowedPrimaryGrow =
          primaryConstraints.maxHeight - primaryWindow.height;

      for (final WindowState neighbor in topNeighbors) {
        final WindowConstraints nConstraints =
            neighbor.resolveEffectiveConstraints(globalConstraints);
        final double neighborGrow = nConstraints.maxHeight - neighbor.height;
        final double neighborShrink = neighbor.height - nConstraints.minHeight;

        maxAllowedPrimaryShrink = math.min(maxAllowedPrimaryShrink, neighborGrow);
        maxAllowedPrimaryGrow = math.min(maxAllowedPrimaryGrow, neighborShrink);
      }

      final double effectiveDelta =
          deltaY.clamp(-maxAllowedPrimaryGrow, maxAllowedPrimaryShrink);

      updatedMap[primaryWindow.id] = primaryWindow.copyWith(
        y: primaryWindow.y + effectiveDelta,
        height: primaryWindow.height - effectiveDelta,
      );

      for (final WindowState neighbor in topNeighbors) {
        updatedMap[neighbor.id] = neighbor.copyWith(
          height: neighbor.height + effectiveDelta,
        );
      }
    }
  }
}