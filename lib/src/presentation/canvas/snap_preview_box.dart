import 'package:flutter/material.dart';

/// Анимированный оверлей предварительного просмотра геометрии прилипания окна (Snap Preview).
class SnapPreviewBox extends StatelessWidget {
  /// Целевые геометрические границы предварительного просмотра.
  final Rect rect;

  /// Создает экземпляр [SnapPreviewBox].
  const SnapPreviewBox({
    super.key,
    required this.rect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
            border: Border.all(
              color: const Color(0xFF00E5FF),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}

/// Псевдоним обратной совместимости для [SnapPreviewBox].
typedef SnapPreviewOverlay = SnapPreviewBox;