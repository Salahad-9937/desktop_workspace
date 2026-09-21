import 'package:flutter/material.dart';

import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';
import 'dock_window_chip.dart';

/// Модульная панель быстрого доступа со стабильным неизменным порядком чипов.
class WorkspaceDock extends StatelessWidget {
  /// Список окон рабочего пространства.
  final List<WindowState> windows;

  /// Идентификатор сфокусированного окна.
  final String? focusedWindowId;

  /// Зафиксированный порядок следования идентификаторов окон на док-панели.
  final List<String> dockOrder;

  /// Обратный вызов клика по окну (активация / сворачивание).
  final void Function(String windowId) onWindowTap;

  /// Ведущий слот расширения (например, кнопка каталога).
  final Widget? leading;

  /// Ведомый слот расширения (например, системные индикаторы хоста).
  final Widget? trailing;

  /// Создает экземпляр [WorkspaceDock].
  const WorkspaceDock({
    super.key,
    required this.windows,
    required this.focusedWindowId,
    this.dockOrder = const <String>[],
    required this.onWindowTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    // Стабильная фильтрация и упорядочивание окон строго по dockOrder
    final Map<String, WindowState> windowMap = <String, WindowState>{
      for (final WindowState w in windows) w.id: w,
    };

    final List<WindowState> dockWindows = <WindowState>[];
    for (final String id in dockOrder) {
      final WindowState? win = windowMap[id];
      if (win != null) {
        dockWindows.add(win);
      }
    }

    // Если какое-то окно еще не попало в dockOrder, добавляем его в конец
    for (final WindowState w in windows) {
      if (!dockWindows.contains(w)) {
        dockWindows.add(w);
      }
    }

    return Container(
      height: theme.dockHeight,
      decoration: BoxDecoration(
        color: theme.dockBackground,
        border: Border(
          top: BorderSide(
            color: theme.borderInactive,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            VerticalDivider(
              width: 1.0,
              indent: 8.0,
              endIndent: 8.0,
              color: theme.borderInactive,
            ),
          ],
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: dockWindows.length,
              itemBuilder: (BuildContext context, int index) {
                final WindowState win = dockWindows[index];
                return DockWindowChip(
                  key: ValueKey<String>(win.id),
                  window: win,
                  isFocused: win.id == focusedWindowId && !win.isMinimized,
                  onTap: () => onWindowTap(win.id),
                );
              },
            ),
          ),
          if (trailing != null) ...<Widget>[
            VerticalDivider(
              width: 1.0,
              indent: 8.0,
              endIndent: 8.0,
              color: theme.borderInactive,
            ),
            trailing!,
          ],
        ],
      ),
    );
  }
}