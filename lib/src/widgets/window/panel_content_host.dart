import 'package:flutter/material.dart';
import '../../models/window_state.dart';
import '../../models/workspace_tab.dart';
import '../../theme/desktop_theme.dart';

/// Функция обратного вызова для отрисовки пользовательского содержимого вкладки окна.
typedef WorkspaceContentBuilder = Widget Function(
  BuildContext context,
  WindowState win,
  WorkspaceTab tab,
);

/// Диспетчер контента окна с поддержкой внешнего билдера или отображения базового интерфейса.
class PanelContentHost extends StatelessWidget {
  /// Состояние окна.
  final WindowState win;

  /// Метаданные текущей активной вкладки.
  final WorkspaceTab tab;

  /// Пользовательский билдер содержимого окна.
  final WorkspaceContentBuilder? contentBuilder;

  /// Создает экземпляр [PanelContentHost].
  const PanelContentHost({
    super.key,
    required this.win,
    required this.tab,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (contentBuilder != null) {
      return contentBuilder!(context, win, tab);
    }

    final Color accent = tab.accentColor ?? DesktopTheme.accentColor;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: DesktopTheme.spaceBackground,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (tab.icon != null)
              Container(
                width: 54.0,
                height: 54.0,
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  tab.icon,
                  size: 26.0,
                  color: accent,
                ),
              ),
            Text(
              tab.title,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
