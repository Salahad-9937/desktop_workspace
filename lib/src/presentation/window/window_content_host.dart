import 'package:flutter/material.dart';
import '../../registry/panel_registry.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_tab.dart';
import '../../theme/workspace_theme.dart';

/// Диспетчер контента окна с сохранением состояния дерева виджетов вкладок (State Preservation).
class WindowContentHost extends StatelessWidget {
  /// Состояние окна.
  final WindowState win;

  /// Метаданные текущей активной вкладки.
  final WorkspaceTab tab;

  /// Пользовательский билдер содержимого окна.
  final WorkspaceContentBuilder? contentBuilder;

  /// Создает экземпляр [WindowContentHost].
  const WindowContentHost({
    super.key,
    required this.win,
    required this.tab,
    this.contentBuilder,
  });

  Widget _buildSingleTabContent(
    BuildContext context,
    WindowState window,
    WorkspaceTab currentTab,
  ) {
    if (contentBuilder != null) {
      return contentBuilder!(context, window, currentTab);
    }

    final WorkspaceContentBuilder? registryBuilder =
        PanelRegistry.instance.getBuilder(currentTab.id);
    if (registryBuilder != null) {
      return registryBuilder(context, window, currentTab);
    }

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final Color accent = currentTab.accentColor ?? theme.accentColor;

    return Container(
      key: ValueKey<String>('tab_content_${window.id}_${currentTab.id}'),
      width: double.infinity,
      height: double.infinity,
      color: theme.spaceBackground,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (currentTab.icon != null)
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
                  currentTab.icon,
                  size: 26.0,
                  color: accent,
                ),
              ),
            Text(
              currentTab.title,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: theme.panelBackground.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (win.tabs.isEmpty) {
      return const SizedBox.expand();
    }

    final int activeIndex = win.activeTabIndex.clamp(0, win.tabs.length - 1);

    return IndexedStack(
      index: activeIndex,
      children: List<Widget>.generate(win.tabs.length, (int index) {
        final WorkspaceTab itemTab = win.tabs[index];
        final bool shouldKeep = itemTab.keepAlive || index == activeIndex;

        if (!shouldKeep) {
          return const SizedBox.shrink();
        }

        return _buildSingleTabContent(context, win, itemTab);
      }),
    );
  }
}

/// Псевдоним обратной совместимости для [WindowContentHost].
typedef PanelContentHost = WindowContentHost;