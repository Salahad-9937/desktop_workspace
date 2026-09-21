import 'package:flutter/material.dart';

import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Всплывающая карточка быстрого предпросмотра содержимого окна над док-панелью.
class DockHoverPreview extends StatelessWidget {
  /// Состояние оконного контейнера.
  final WindowState window;

  /// Создает экземпляр [DockHoverPreview].
  const DockHoverPreview({
    super.key,
    required this.window,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final String activeTitle = window.activeTab?.title ?? 'Окно';

    return Material(
      elevation: 12.0,
      borderRadius: BorderRadius.circular(theme.windowRadius),
      color: theme.windowBackground,
      child: Container(
        width: 220.0,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.windowRadius),
          border: Border.all(
            color: theme.borderActive,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  window.activeTab?.icon ?? Icons.web_asset_rounded,
                  size: 16.0,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    activeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Container(
              height: 60.0,
              decoration: BoxDecoration(
                color: theme.titlebarInactive,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: theme.borderInactive, width: 0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.desktop_windows_outlined,
                  size: 28.0,
                  color: theme.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Вкладок: ${window.tabs.length} • Статус: ${window.isMinimized ? "Свернуто" : "На холсте"}',
              style: TextStyle(fontSize: 10.0, color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}