import 'package:flutter/material.dart';

import '../../engine/seam_resizer.dart';
import '../../model/geometry_types.dart';
import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Интерактивный оверлей единых общих швов и четырехсторонних перекрестков между окнами.
class SharedSeamOverlay extends StatefulWidget {
  /// Список всех окон рабочего пространства.
  final List<WindowState> windows;

  /// Идентификатор сфокусированного окна на холсте.
  final String? focusedWindowId;

  /// Допустимый зазор для объединения окон в общий шов.
  final double seamEpsilon;

  /// Минимальная длина взаимного перекрытия для общего шва.
  final double minSeamOverlap;

  /// Обратный вызов деформации шва.
  final void Function(
    String windowId,
    ResizeDirection direction,
    double deltaX,
    double deltaY,
  ) onResizeSeam;

  /// Завершение операции масштабирования шва.
  final VoidCallback onResizeEnd;

  /// Создает экземпляр [SharedSeamOverlay].
  const SharedSeamOverlay({
    super.key,
    required this.windows,
    this.focusedWindowId,
    this.seamEpsilon = 6.0,
    this.minSeamOverlap = 24.0,
    required this.onResizeSeam,
    required this.onResizeEnd,
  });

  @override
  State<SharedSeamOverlay> createState() => _SharedSeamOverlayState();
}

class _SharedSeamOverlayState extends State<SharedSeamOverlay> {
  MouseCursor? _activeDragCursor;

  void _onDragStart(MouseCursor cursor) {
    setState(() => _activeDragCursor = cursor);
  }

  void _onDragEnd() {
    setState(() => _activeDragCursor = null);
    widget.onResizeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final List<SharedSeam> seams = SeamResizer.findSharedSeams(
      windows: widget.windows,
      seamEpsilon: widget.seamEpsilon,
      minSeamOverlap: widget.minSeamOverlap,
    );

    if (seams.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<SeamIntersection> intersections = SeamDetector.findIntersections(
      seams: seams,
      seamEpsilon: widget.seamEpsilon,
    );

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Слой линий швов со стабильными идентификаторами
        for (final SharedSeam seam in seams)
          _SharedSeamLine(
            key: ValueKey<String>(
              'seam_${seam.isVertical ? "v" : "h"}_${seam.participantWindowIds.join("_")}',
            ),
            seam: seam,
            dividerColor: theme.seamDivider,
            idleColor: _resolveIdleColor(seam, theme),
            onResize: widget.onResizeSeam,
            onDragStart: _onDragStart,
            onDragEnd: _onDragEnd,
          ),
        // Слой центральных перекрестков (4-Way Cross)
        for (final SeamIntersection cross in intersections)
          _SeamIntersectionCross(
            key: ValueKey<String>(
              'cross_${cross.verticalSeam.participantWindowIds.join("_")}__${cross.horizontalSeam.participantWindowIds.join("_")}',
            ),
            cross: cross,
            accentColor: theme.seamDivider,
            onResizeSeam: widget.onResizeSeam,
            onDragStart: _onDragStart,
            onDragEnd: _onDragEnd,
          ),
        // Неблокирующий трекер курсора на весь холст во время активного жеста
        if (_activeDragCursor != null)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) => _onDragEnd(),
              onPointerCancel: (_) => _onDragEnd(),
              child: MouseRegion(
                cursor: _activeDragCursor!,
                opaque: false,
              ),
            ),
          ),
      ],
    );
  }

  Color _resolveIdleColor(SharedSeam seam, WorkspaceThemeData theme) {
    if (widget.focusedWindowId == null) {
      return theme.borderInactive;
    }
    final bool hasFocus =
        seam.participantWindowIds.contains(widget.focusedWindowId) ||
            seam.primaryWindowId == widget.focusedWindowId ||
            seam.secondaryWindowId == widget.focusedWindowId;

    return hasFocus
        ? theme.borderActive.withValues(alpha: 0.85)
        : theme.borderInactive;
  }
}

class _SharedSeamLine extends StatefulWidget {
  final SharedSeam seam;
  final Color dividerColor;
  final Color idleColor;
  final void Function(
    String windowId,
    ResizeDirection direction,
    double deltaX,
    double deltaY,
  ) onResize;
  final void Function(MouseCursor cursor) onDragStart;
  final VoidCallback onDragEnd;

  const _SharedSeamLine({
    super.key,
    required this.seam,
    required this.dividerColor,
    required this.idleColor,
    required this.onResize,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<_SharedSeamLine> createState() => _SharedSeamLineState();
}

class _SharedSeamLineState extends State<_SharedSeamLine> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // В активном драге область захвата расширяется до 24 px для исключения срыва курсора
    final double hitThickness = _isDragging ? 24.0 : 6.0;
    final bool isActive = _isHovered || _isDragging;

    final double left;
    final double top;
    final double width;
    final double height;

    if (widget.seam.isVertical) {
      left = widget.seam.position - (hitThickness / 2.0);
      top = widget.seam.start;
      width = hitThickness;
      height = widget.seam.end - widget.seam.start;
    } else {
      left = widget.seam.start;
      top = widget.seam.position - (hitThickness / 2.0);
      width = widget.seam.end - widget.seam.start;
      height = hitThickness;
    }

    final MouseCursor cursor = widget.seam.isVertical
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            setState(() => _isDragging = true);
            widget.onDragStart(cursor);
          },
          onPanUpdate: (DragUpdateDetails details) {
            widget.onResize(
              widget.seam.primaryWindowId,
              widget.seam.direction,
              details.delta.dx,
              details.delta.dy,
            );
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            widget.onDragEnd();
          },
          onPanCancel: () {
            setState(() => _isDragging = false);
            widget.onDragEnd();
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.seam.isVertical ? (isActive ? 3.0 : 1.0) : width,
              height:
                  widget.seam.isVertical ? height : (isActive ? 3.0 : 1.0),
              decoration: BoxDecoration(
                color: isActive ? widget.dividerColor : widget.idleColor,
                boxShadow: isActive
                    ? <BoxShadow>[
                        BoxShadow(
                          color: widget.dividerColor.withValues(alpha: 0.7),
                          blurRadius: 4.0,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeamIntersectionCross extends StatefulWidget {
  final SeamIntersection cross;
  final Color accentColor;
  final void Function(
    String windowId,
    ResizeDirection direction,
    double deltaX,
    double deltaY,
  ) onResizeSeam;
  final void Function(MouseCursor cursor) onDragStart;
  final VoidCallback onDragEnd;

  const _SeamIntersectionCross({
    super.key,
    required this.cross,
    required this.accentColor,
    required this.onResizeSeam,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<_SeamIntersectionCross> createState() => _SeamIntersectionCrossState();
}

class _SeamIntersectionCrossState extends State<_SeamIntersectionCross> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final double crossHitSize = _isDragging ? 28.0 : 14.0;
    final bool isActive = _isHovered || _isDragging;

    return Positioned(
      left: widget.cross.x - (crossHitSize / 2.0),
      top: widget.cross.y - (crossHitSize / 2.0),
      width: crossHitSize,
      height: crossHitSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.allScroll,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            setState(() => _isDragging = true);
            widget.onDragStart(SystemMouseCursors.allScroll);
          },
          onPanUpdate: (DragUpdateDetails details) {
            widget.onResizeSeam(
              widget.cross.horizontalSeam.primaryWindowId,
              widget.cross.horizontalSeam.direction,
              0.0,
              details.delta.dy,
            );
            widget.onResizeSeam(
              widget.cross.verticalSeam.primaryWindowId,
              widget.cross.verticalSeam.direction,
              details.delta.dx,
              0.0,
            );
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            widget.onDragEnd();
          },
          onPanCancel: () {
            setState(() => _isDragging = false);
            widget.onDragEnd();
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: isActive ? 10.0 : 6.0,
              height: isActive ? 10.0 : 6.0,
              decoration: BoxDecoration(
                color: widget.accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.0,
                ),
                boxShadow: isActive
                    ? <BoxShadow>[
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.8),
                          blurRadius: 6.0,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}