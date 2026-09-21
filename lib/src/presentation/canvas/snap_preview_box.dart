import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Высокодинамичный полупрозрачный оверлей контура предпросмотра будущей стыковки.
class SnapPreviewBox extends StatelessWidget {
  /// Геометрический целевой прямоугольник оверлея.
  final WorkspaceRect? targetRect;

  /// Создает экземпляр [SnapPreviewBox].
  const SnapPreviewBox({
    super.key,
    required this.targetRect,
  });

  @override
  Widget build(BuildContext context) {
    if (targetRect == null) {
      return const SizedBox.shrink();
    }

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Positioned(
      left: targetRect!.x,
      top: targetRect!.y,
      width: targetRect!.width,
      height: targetRect!.height,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: theme.previewOverlay,
            borderRadius: BorderRadius.circular(theme.windowRadius),
            border: Border.all(
              color: theme.borderActive,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}