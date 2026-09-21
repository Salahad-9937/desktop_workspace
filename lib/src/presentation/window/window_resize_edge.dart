import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';

/// Обратный вызов дельты смещения при изменении размеров окна.
typedef OnResizeDeltaCallback = void Function(
  ResizeDirection direction,
  double deltaX,
  double deltaY,
);

/// Восьмизонный сенсорный периметр изменения габаритов окна с бесконфликтными верхними зонами.
class WindowResizeEdge extends StatelessWidget {
  /// Функция обратного вызова при смещении ручки ресайза.
  final OnResizeDeltaCallback onResize;

  /// Функция обратного вызова при завершении жеста изменения размера.
  final VoidCallback? onResizeEnd;

  /// Толщина линейных сенсорных полос по бокам и снизу.
  final double edgeThickness;

  /// Уменьшенная толщина верхней сенсорной полосы для исключения конфликтов с кнопками заголовка.
  final double topEdgeThickness;

  /// Размер квадратных угловых секторов захвата.
  final double cornerSize;

  /// Создает экземпляр [WindowResizeEdge].
  const WindowResizeEdge({
    super.key,
    required this.onResize,
    this.onResizeEnd,
    this.edgeThickness = 10.0,
    this.topEdgeThickness = 3.0,
    this.cornerSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    // Резерв ширины вверху справа под системные кнопки заголовка (Pin, Tile, Min, Max, Close)
    const double windowControlsReserve = 170.0;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Северное ребро (N): тонкая кромка 3 px, полностью отведенная от блока правых кнопок
        Positioned(
          top: 0.0,
          left: cornerSize,
          right: cornerSize + windowControlsReserve,
          height: topEdgeThickness,
          child: _ResizeHandle(
            direction: ResizeDirection.north,
            cursor: SystemMouseCursors.resizeUpDown,
            onResize: onResize,
            onResizeEnd: onResizeEnd,
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
            onResizeEnd: onResizeEnd,
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
            onResizeEnd: onResizeEnd,
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
            onResizeEnd: onResizeEnd,
          ),
        ),
        // Северо-западный угол (NW): микро-сектор 4x4 px
        Positioned(
          top: 0.0,
          left: 0.0,
          width: 4.0,
          height: 4.0,
          child: _ResizeHandle(
            direction: ResizeDirection.northWest,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onResize: onResize,
            onResizeEnd: onResizeEnd,
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
            onResizeEnd: onResizeEnd,
          ),
        ),
        // Юго-восточный угол (SE)
        Positioned(
          bottom: 0.0,
          right: 0.0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            direction: ResizeDirection.southEast,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onResize: onResize,
            onResizeEnd: onResizeEnd,
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
  final VoidCallback? onResizeEnd;

  const _ResizeHandle({
    required this.direction,
    required this.cursor,
    required this.onResize,
    this.onResizeEnd,
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
        onPanEnd: (_) => onResizeEnd?.call(),
        onPanCancel: () => onResizeEnd?.call(),
      ),
    );
  }
}