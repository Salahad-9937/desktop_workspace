import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';

/// Обратный вызов дельты смещения при изменении размеров окна.
typedef OnResizeDeltaCallback = void Function(
  ResizeDirection direction,
  double deltaX,
  double deltaY,
);

/// Восьмизонный сенсорный периметр изменения габаритов оконного контейнера.
class WindowResizeEdge extends StatelessWidget {
  /// Функция обратного вызова при смещении ручки ресайза.
  final OnResizeDeltaCallback onResize;

  /// Толщина линейных сенсорных полос по периметру.
  final double edgeThickness;

  /// Размер квадратных угловых секторов захвата.
  final double cornerSize;

  /// Создает экземпляр [WindowResizeEdge].
  const WindowResizeEdge({
    super.key,
    required this.onResize,
    this.edgeThickness = 6.0,
    this.cornerSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Северное ребро (N)
        Positioned(
          top: 0.0,
          left: cornerSize,
          right: cornerSize,
          height: edgeThickness,
          child: _ResizeHandle(
            direction: ResizeDirection.north,
            cursor: SystemMouseCursors.resizeUpDown,
            onResize: onResize,
          ),
        ),
        // Южное ребро (S)
        Positioned(
          bottom: 0.0,
          left: cornerSize,
          right: cornerSize,
          height: edgeThickness,
          child: _ResizeHandle(
            direction: ResizeDirection.south,
            cursor: SystemMouseCursors.resizeUpDown,
            onResize: onResize,
          ),
        ),
        // Западное ребро (W)
        Positioned(
          top: cornerSize,
          bottom: cornerSize,
          left: 0.0,
          width: edgeThickness,
          child: _ResizeHandle(
            direction: ResizeDirection.west,
            cursor: SystemMouseCursors.resizeLeftRight,
            onResize: onResize,
          ),
        ),
        // Восточное ребро (E)
        Positioned(
          top: cornerSize,
          bottom: cornerSize,
          right: 0.0,
          width: edgeThickness,
          child: _ResizeHandle(
            direction: ResizeDirection.east,
            cursor: SystemMouseCursors.resizeLeftRight,
            onResize: onResize,
          ),
        ),
        // Северо-западный угол (NW)
        Positioned(
          top: 0.0,
          left: 0.0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            direction: ResizeDirection.northWest,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onResize: onResize,
          ),
        ),
        // Северо-восточный угол (NE)
        Positioned(
          top: 0.0,
          right: 0.0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            direction: ResizeDirection.northEast,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            onResize: onResize,
          ),
        ),
        // Юго-западный угол (SW)
        Positioned(
          bottom: 0.0,
          left: 0.0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            direction: ResizeDirection.southWest,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            onResize: onResize,
          ),
        ),
        // Юго-восточный угол (SE) с засечкой
        Positioned(
          bottom: 0.0,
          right: 0.0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            direction: ResizeDirection.southEast,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onResize: onResize,
          ),
        ),
      ],
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final ResizeDirection direction;
  final MouseCursor cursor;
  final OnResizeDeltaCallback onResize;

  const _ResizeHandle({
    required this.direction,
    required this.cursor,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (DragUpdateDetails details) {
          onResize(direction, details.delta.dx, details.delta.dy);
        },
      ),
    );
  }
}