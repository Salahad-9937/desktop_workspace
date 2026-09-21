import 'dart:math' as math;

import '../model/geometry_types.dart';
import '../model/shared_seam.dart';
import '../model/window_state.dart';

/// Вычислительный модуль обнаружения и объединения непрерывных общих швов и перекрестков.
class SeamDetector {
  const SeamDetector._();

  /// Находит все объединенные общие непрерывные швы, сшивая Т-образные стыки 1-к-N (включая окна с зазором).
  static List<SharedSeam> findSharedSeams({
    required List<WindowState> windows,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    final List<SharedSeam> rawCandidates = <SharedSeam>[];
    final List<WindowState> visible = windows
        .where((WindowState w) => !w.isMinimized)
        .toList(growable: false);

    for (int i = 0; i < visible.length; i++) {
      final WindowState a = visible[i];

      for (int j = 0; j < visible.length; j++) {
        if (i == j) {
          continue;
        }
        final WindowState b = visible[j];

        // 1. Поиск вертикальных пар
        if ((a.rect.right - b.rect.left).abs() <= seamEpsilon) {
          final double overlapStart = math.max(a.rect.top, b.rect.top);
          final double overlapEnd = math.min(a.rect.bottom, b.rect.bottom);
          final double overlap = overlapEnd - overlapStart;

          if (overlap >= minSeamOverlap) {
            final double avgPos = (a.rect.right + b.rect.left) / 2.0;
            rawCandidates.add(
              SharedSeam(
                isVertical: true,
                position: avgPos,
                start: overlapStart,
                end: overlapEnd,
                primaryWindowId: a.id,
                secondaryWindowId: b.id,
                participantWindowIds: <String>[a.id, b.id],
                direction: ResizeDirection.east,
              ),
            );
          }
        }

        // 2. Поиск горизонтальных пар
        if ((a.rect.bottom - b.rect.top).abs() <= seamEpsilon) {
          final double overlapStart = math.max(a.rect.left, b.rect.left);
          final double overlapEnd = math.min(a.rect.right, b.rect.right);
          final double overlap = overlapEnd - overlapStart;

          if (overlap >= minSeamOverlap) {
            final double avgPos = (a.rect.bottom + b.rect.top) / 2.0;
            rawCandidates.add(
              SharedSeam(
                isVertical: false,
                position: avgPos,
                start: overlapStart,
                end: overlapEnd,
                primaryWindowId: a.id,
                secondaryWindowId: b.id,
                participantWindowIds: <String>[a.id, b.id],
                direction: ResizeDirection.south,
              ),
            );
          }
        }
      }
    }

    return _mergeCollinearSeams(rawCandidates, seamEpsilon);
  }

  /// Находит точки четырехсторонних пересечений (4-Way Cross) между швами.
  static List<SeamIntersection> findIntersections({
    required List<SharedSeam> seams,
    required double seamEpsilon,
  }) {
    final List<SeamIntersection> intersections = <SeamIntersection>[];
    final List<SharedSeam> vertical =
        seams.where((SharedSeam s) => s.isVertical).toList();
    final List<SharedSeam> horizontal =
        seams.where((SharedSeam s) => !s.isVertical).toList();

    for (final SharedSeam v in vertical) {
      for (final SharedSeam h in horizontal) {
        final bool xMatches = v.position >= (h.start - seamEpsilon) &&
            v.position <= (h.end + seamEpsilon);
        final bool yMatches = h.position >= (v.start - seamEpsilon) &&
            h.position <= (v.end + seamEpsilon);

        if (xMatches && yMatches) {
          intersections.add(
            SeamIntersection(
              x: v.position,
              y: h.position,
              verticalSeam: v,
              horizontalSeam: h,
            ),
          );
        }
      }
    }

    return intersections;
  }

  /// Проверяет, граничит ли ребро окна с соседними окнами по непрерывному общему шву.
  static bool hasSharedSeam({
    required WindowState primaryWindow,
    required List<WindowState> allWindows,
    required ResizeDirection direction,
    required double seamEpsilon,
    required double minSeamOverlap,
  }) {
    if (primaryWindow.isMinimized || direction == ResizeDirection.none) {
      return false;
    }

    if (direction.affectsRight) {
      final double seamPosition = primaryWindow.rect.right;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.left - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isContinuous && overlapY >= minSeamOverlap;
      });
    }

    if (direction.affectsLeft) {
      final double seamPosition = primaryWindow.rect.left;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.right - seamPosition).abs() <= seamEpsilon;
        final double overlapY = math.max(
          0.0,
          math.min(primaryWindow.rect.bottom, w.rect.bottom) -
              math.max(primaryWindow.rect.top, w.rect.top),
        );
        return isContinuous && overlapY >= minSeamOverlap;
      });
    }

    if (direction.affectsBottom) {
      final double seamPosition = primaryWindow.rect.bottom;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.top - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isContinuous && overlapX >= minSeamOverlap;
      });
    }

    if (direction.affectsTop) {
      final double seamPosition = primaryWindow.rect.top;
      return allWindows.any((WindowState w) {
        if (w.id == primaryWindow.id || w.isMinimized) {
          return false;
        }
        final bool isContinuous =
            (w.rect.bottom - seamPosition).abs() <= seamEpsilon;
        final double overlapX = math.max(
          0.0,
          math.min(primaryWindow.rect.right, w.rect.right) -
              math.max(primaryWindow.rect.left, w.rect.left),
        );
        return isContinuous && overlapX >= minSeamOverlap;
      });
    }

    return false;
  }

  static List<SharedSeam> _mergeCollinearSeams(
    List<SharedSeam> rawSeams,
    double seamEpsilon,
  ) {
    if (rawSeams.isEmpty) {
      return const <SharedSeam>[];
    }

    final List<SharedSeam> merged = <SharedSeam>[];

    final List<SharedSeam> vertical =
        rawSeams.where((SharedSeam s) => s.isVertical).toList();
    final List<SharedSeam> horizontal =
        rawSeams.where((SharedSeam s) => !s.isVertical).toList();

    merged.addAll(_mergeSegments(vertical, seamEpsilon));
    merged.addAll(_mergeSegments(horizontal, seamEpsilon));

    return merged;
  }

  static List<SharedSeam> _mergeSegments(
    List<SharedSeam> segments,
    double seamEpsilon,
  ) {
    final List<SharedSeam> result = <SharedSeam>[];
    final List<SharedSeam> pool = List<SharedSeam>.of(segments);

    while (pool.isNotEmpty) {
      SharedSeam current = pool.removeAt(0);
      final Set<String> participants = current.participantWindowIds.toSet()
        ..add(current.primaryWindowId)
        ..add(current.secondaryWindowId);

      bool expanded = true;
      while (expanded) {
        expanded = false;
        for (int i = 0; i < pool.length; i++) {
          final SharedSeam other = pool[i];
          final bool isSameLine =
              (current.position - other.position).abs() <= seamEpsilon;

          if (isSameLine) {
            final bool touchesOrOverlaps =
                other.start <= (current.end + seamEpsilon) &&
                    other.end >= (current.start - seamEpsilon);

            // Сшиваем сегменты также при наличии общего смежного окна с одной из сторон
            final bool sharesCommonWindow =
                current.participantWindowIds.any(other.participantWindowIds.contains);

            if (touchesOrOverlaps || sharesCommonWindow) {
              pool.removeAt(i);
              participants.addAll(other.participantWindowIds);
              participants.add(other.primaryWindowId);
              participants.add(other.secondaryWindowId);

              current = SharedSeam(
                isVertical: current.isVertical,
                position: (current.position + other.position) / 2.0,
                start: math.min(current.start, other.start),
                end: math.max(current.end, other.end),
                primaryWindowId: current.primaryWindowId,
                secondaryWindowId: other.secondaryWindowId,
                participantWindowIds: participants.toList(growable: false),
                direction: current.direction,
              );
              expanded = true;
              break;
            }
          }
        }
      }
      result.add(current);
    }

    return result;
  }
}