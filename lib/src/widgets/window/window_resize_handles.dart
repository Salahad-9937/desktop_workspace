import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/workspace_controller.dart';
import '../../models/geometry_types.dart';
import '../../models/window_state.dart';

/// Интерактивные 8-направленные границы изменения геометрического размера окна.
class WindowResizeHandles extends ConsumerWidget {
  /// Состояние целевого окна.
  final WindowState win;

  /// Акцентный цвет модальности для отрисовки угловых засечек.
  final Color accentColor;

  /// Создает экземпляр [WindowResizeHandles].
  const WindowResizeHandles({
    super.key,
    required this.win,
    required this.accentColor,
  });

  Widget _buildHandle({
    required WidgetRef ref,
    required ResizeHandle dir,
    required double? left,
    required double? top,
    required double? right,
    required double? bottom,
    required double? width,
    required double? height,
    required MouseCursor cursor,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (DragUpdateDetails details) {
            ref.read(workspaceControllerProvider.notifier).resizeWindow(
                  win.id,
                  dir,
                  details.delta,
                );
          },
          child: dir == ResizeHandle.se
              ? CustomPaint(
                  painter: ResizeCornerPainter(color: accentColor),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double edgeThickness = 6.0;
    const double cornerExtent = 14.0;

    return Stack(
      children: <Widget>[
        // Северная грань (верх)
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.n,
          left: cornerExtent,
          top: 0.0,
          right: cornerExtent,
          bottom: null,
          width: null,
          height: edgeThickness,
          cursor: SystemMouseCursors.resizeUpDown,
        ),
        // Южная грань (низ)
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.s,
          left: cornerExtent,
          top: null,
          right: cornerExtent,
          bottom: 0.0,
          width: null,
          height: edgeThickness,
          cursor: SystemMouseCursors.resizeUpDown,
        ),
        // Западная грань (лево)
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.w,
          left: 0.0,
          top: cornerExtent,
          right: null,
          bottom: cornerExtent,
          width: edgeThickness,
          height: null,
          cursor: SystemMouseCursors.resizeLeftRight,
        ),
        // Восточная грань (право)
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.e,
          left: null,
          top: cornerExtent,
          right: 0.0,
          bottom: cornerExtent,
          width: edgeThickness,
          height: null,
          cursor: SystemMouseCursors.resizeLeftRight,
        ),
        // Северо-западный угол
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.nw,
          left: 0.0,
          top: 0.0,
          right: null,
          bottom: null,
          width: cornerExtent,
          height: cornerExtent,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
        ),
        // Северо-восточный угол
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.ne,
          left: null,
          top: 0.0,
          right: 0.0,
          bottom: null,
          width: cornerExtent,
          height: cornerExtent,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
        ),
        // Юго-западный угол
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.sw,
          left: 0.0,
          top: null,
          right: null,
          bottom: 0.0,
          width: cornerExtent,
          height: cornerExtent,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
        ),
        // Юго-восточный угол
        _buildHandle(
          ref: ref,
          dir: ResizeHandle.se,
          left: null,
          top: null,
          right: 0.0,
          bottom: 0.0,
          width: cornerExtent + 4.0,
          height: cornerExtent + 4.0,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
        ),
      ],
    );
  }
}

/// Отрисовщик диагональных линий захвата ресайза в юго-восточном углу окна.
class ResizeCornerPainter extends CustomPainter {
  /// Цвет штриховки.
  final Color color;

  /// Создает экземпляр [ResizeCornerPainter].
  const ResizeCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width, size.height - 8.0),
      Offset(size.width - 8.0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - 4.0),
      Offset(size.width - 4.0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ResizeCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
