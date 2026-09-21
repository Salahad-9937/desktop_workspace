import 'package:flutter/material.dart';

import '../../engine/seam_resizer.dart';
import '../../model/geometry_types.dart';
import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Интерактивный оверлей единых общих швов между состыкованными окнами.
class SharedSeamOverlay extends StatelessWidget {
  /// Список всех окон рабочего пространства.
  final List<WindowState> windows;

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
    this.seamEpsilon = 6.0,
    this.minSeamOverlap = 24.0,
    required this.onResizeSeam,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final List<SharedSeam> seams = SeamResizer.findSharedSeams(
      windows: windows,
      seamEpsilon: seamEpsilon,
      minSeamOverlap: minSeamOverlap,
    );

    if (seams.isEmpty) {
      return const SizedBox.shrink();
    }

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final SharedSeam seam in seams)
          _SharedSeamLine(
            key: ValueKey<String>(
              'seam_${seam.isVertical ? "v" : "h"}_${seam.primaryWindowId}_${seam.secondaryWindowId}',
            ),
            seam: seam,
            dividerColor: theme.seamDivider,
            idleColor: theme.borderInactive,
            onResize: onResizeSeam,
            onResizeEnd: onResizeEnd,
          ),
      ],
    );
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
  final VoidCallback onResizeEnd;

  const _SharedSeamLine({
    super.key,
    required this.seam,
    required this.dividerColor,
    required this.idleColor,
    required this.onResize,
    required this.onResizeEnd,
  });

  @override
  State<_SharedSeamLine> createState() => _SharedSeamLineState();
}

class _SharedSeamLineState extends State<_SharedSeamLine> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Узкая сенсорная полоса (6 px) для сохранения легкого доступа к ручкам одиночного окна
    const double hitThickness = 6.0;
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
          onPanStart: (_) => setState(() => _isDragging = true),
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
            widget.onResizeEnd();
          },
          onPanCancel: () {
            setState(() => _isDragging = false);
            widget.onResizeEnd();
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