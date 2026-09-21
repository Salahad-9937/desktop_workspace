import 'dart:math' as math;

import '../config/window_constraints.dart';
import '../model/geometry_types.dart';
import '../model/shared_seam.dart';
import '../model/window_state.dart';
import 'seam_detector.dart';

export '../model/shared_seam.dart';
export 'seam_detector.dart';

/// Модуль синхронного масштабирования группы состыкованных окон по общему шву.
class SeamResizer {
  const SeamResizer._();

  /// Делегирует обнаружение общих швов модулю [SeamDetector].
  static List<SharedSeam> findSharedSeams({
    required List<WindowState> windows,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    return SeamDetector.findSharedSeams(
      windows: windows,
      seamEpsilon: seamEpsilon,
      minSeamOverlap: minSeamOverlap,
    );
  }

  /// Делегирует проверку наличия общего шва модулю [SeamDetector].
  static bool hasSharedSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    return SeamDetector.hasSharedSeam(
      primaryWindow: primaryWindow,
      allWindows: allWindows,
      direction: direction,
      seamEpsilon: seamEpsilon,
      minSeamOverlap: minSeamOverlap,
    );
  }

  /// Выполняет синхронную деформацию всех состыкованных окон вдоль непрерывного ребра.
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

    // 1. Горизонтальная составляющая: масштабирование вертикального шва
    if (direction.affectsLeft || direction.affectsRight) {
      final double seamPos = direction.affectsRight
          ? primaryWindow.rect.right
          : primaryWindow.rect.left;

      _applyContinuousVerticalSeam(
        primaryWindow: primaryWindow,
        seamPosition: seamPos,
        allWindows: allWindows,
        deltaX: deltaX,
        seamEpsilon: seamEpsilon,
        minSeamOverlap: minSeamOverlap,
        globalConstraints: globalConstraints,
        updatedMap: updatedWindows,
      );
    }

    // 2. Вертикальная составляющая: масштабирование горизонтального шва
    if (direction.affectsTop || direction.affectsBottom) {
      final WindowState currentPrimary =
          updatedWindows[primaryWindow.id] ?? primaryWindow;
      final double seamPos = direction.affectsBottom
          ? currentPrimary.rect.bottom
          : currentPrimary.rect.top;

      final List<WindowState> currentAll = allWindows
          .map((WindowState w) => updatedWindows[w.id] ?? w)
          .toList(growable: false);

      _applyContinuousHorizontalSeam(
        primaryWindow: currentPrimary,
        seamPosition: seamPos,
        allWindows: currentAll,
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

  static void _applyContinuousVerticalSeam({
    required WindowState primaryWindow,
    required double seamPosition,
    required List<WindowState> allWindows,
    required double deltaX,
    required double seamEpsilon,
    required double minSeamOverlap,
    required WindowConstraints globalConstraints,
    required Map<String, WindowState> updatedMap,
  }) {
    // Окна слева от шва
    final List<WindowState> leftWindows = allWindows.where((WindowState w) {
      if (w.isMinimized) {
        return false;
      }
      return (w.rect.right - seamPosition).abs() <= seamEpsilon;
    }).toList();

    // Окна справа от шва
    final List<WindowState> rightWindows = allWindows.where((WindowState w) {
      if (w.isMinimized) {
        return false;
      }
      return (w.rect.left - seamPosition).abs() <= seamEpsilon;
    }).toList();

    // Обработка свободного края при отсутствии смежных окон с противоположной стороны
    if (rightWindows.isEmpty) {
      final WindowConstraints primaryConstraints =
          primaryWindow.resolveEffectiveConstraints(globalConstraints);
      final double newWidth =
          primaryConstraints.clampWidth(primaryWindow.width + deltaX);
      updatedMap[primaryWindow.id] = (updatedMap[primaryWindow.id] ?? primaryWindow).copyWith(
        width: newWidth,
      );
      return;
    }

    if (leftWindows.isEmpty) {
      final WindowConstraints primaryConstraints =
          primaryWindow.resolveEffectiveConstraints(globalConstraints);
      final double targetW = primaryWindow.width - deltaX;
      final double clampedW = primaryConstraints.clampWidth(targetW);
      final double appliedDelta = primaryWindow.width - clampedW;
      updatedMap[primaryWindow.id] = (updatedMap[primaryWindow.id] ?? primaryWindow).copyWith(
        x: primaryWindow.x + appliedDelta,
        width: clampedW,
      );
      return;
    }

    double maxAllowedPositive = double.infinity;
    double maxAllowedNegative = double.infinity;

    for (final WindowState left in leftWindows) {
      final WindowConstraints c =
          left.resolveEffectiveConstraints(globalConstraints);
      maxAllowedPositive = math.min(maxAllowedPositive, c.maxWidth - left.width);
      maxAllowedNegative = math.min(maxAllowedNegative, left.width - c.minWidth);
    }

    for (final WindowState right in rightWindows) {
      final WindowConstraints c =
          right.resolveEffectiveConstraints(globalConstraints);
      maxAllowedPositive = math.min(maxAllowedPositive, right.width - c.minWidth);
      maxAllowedNegative = math.min(maxAllowedNegative, c.maxWidth - right.width);
    }

    final double effectiveDelta =
        deltaX.clamp(-maxAllowedNegative, maxAllowedPositive);

    for (final WindowState left in leftWindows) {
      updatedMap[left.id] = left.copyWith(
        width: left.width + effectiveDelta,
      );
    }

    for (final WindowState right in rightWindows) {
      updatedMap[right.id] = right.copyWith(
        x: right.x + effectiveDelta,
        width: right.width - effectiveDelta,
      );
    }
  }

  static void _applyContinuousHorizontalSeam({
    required WindowState primaryWindow,
    required double seamPosition,
    required List<WindowState> allWindows,
    required double deltaY,
    required double seamEpsilon,
    required double minSeamOverlap,
    required WindowConstraints globalConstraints,
    required Map<String, WindowState> updatedMap,
  }) {
    // Окна сверху от шва
    final List<WindowState> topWindows = allWindows.where((WindowState w) {
      if (w.isMinimized) {
        return false;
      }
      return (w.rect.bottom - seamPosition).abs() <= seamEpsilon;
    }).toList();

    // Окна снизу от шва
    final List<WindowState> bottomWindows = allWindows.where((WindowState w) {
      if (w.isMinimized) {
        return false;
      }
      return (w.rect.top - seamPosition).abs() <= seamEpsilon;
    }).toList();

    // Обработка свободного края при отсутствии смежных окон снизу/сверху
    if (bottomWindows.isEmpty) {
      final WindowConstraints primaryConstraints =
          primaryWindow.resolveEffectiveConstraints(globalConstraints);
      final double newHeight =
          primaryConstraints.clampHeight(primaryWindow.height + deltaY);
      updatedMap[primaryWindow.id] = (updatedMap[primaryWindow.id] ?? primaryWindow).copyWith(
        height: newHeight,
      );
      return;
    }

    if (topWindows.isEmpty) {
      final WindowConstraints primaryConstraints =
          primaryWindow.resolveEffectiveConstraints(globalConstraints);
      final double targetH = primaryWindow.height - deltaY;
      final double clampedH = primaryConstraints.clampHeight(targetH);
      final double appliedDelta = primaryWindow.height - clampedH;
      updatedMap[primaryWindow.id] = (updatedMap[primaryWindow.id] ?? primaryWindow).copyWith(
        y: primaryWindow.y + appliedDelta,
        height: clampedH,
      );
      return;
    }

    double maxAllowedPositive = double.infinity;
    double maxAllowedNegative = double.infinity;

    for (final WindowState top in topWindows) {
      final WindowConstraints c =
          top.resolveEffectiveConstraints(globalConstraints);
      maxAllowedPositive = math.min(maxAllowedPositive, c.maxHeight - top.height);
      maxAllowedNegative = math.min(maxAllowedNegative, top.height - c.minHeight);
    }

    for (final WindowState bottom in bottomWindows) {
      final WindowConstraints c =
          bottom.resolveEffectiveConstraints(globalConstraints);
      maxAllowedPositive =
          math.min(maxAllowedPositive, bottom.height - c.minHeight);
      maxAllowedNegative =
          math.min(maxAllowedNegative, c.maxHeight - bottom.height);
    }

    final double effectiveDelta =
        deltaY.clamp(-maxAllowedNegative, maxAllowedPositive);

    for (final WindowState top in topWindows) {
      updatedMap[top.id] = top.copyWith(
        height: top.height + effectiveDelta,
      );
    }

    for (final WindowState bottom in bottomWindows) {
      updatedMap[bottom.id] = bottom.copyWith(
        y: bottom.y + effectiveDelta,
        height: bottom.height - effectiveDelta,
      );
    }
  }
}