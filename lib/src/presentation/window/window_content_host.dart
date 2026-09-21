import 'package:flutter/material.dart';

import '../../model/view_definition.dart';
import '../../model/window_state.dart';
import '../../model/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Многослойный контейнер удержания экземпляров представлений без сброса состояния.
class WindowContentHost extends StatelessWidget {
  /// Состояние несущего окна.
  final WindowState window;

  /// Зарегистрированные определения панелей каталога.
  final Map<String, ViewDefinition> registeredViews;

  /// Прямая фабрика сборки контента (при отсутствии в реестре).
  final WorkspaceContentBuilder? fallbackBuilder;

  /// Создает экземпляр [WindowContentHost].
  const WindowContentHost({
    super.key,
    required this.window,
    required this.registeredViews,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (window.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (int i = 0; i < window.tabs.length; i++)
          _buildTabLayer(context, i, window.tabs[i]),
      ],
    );
  }

  Widget _buildTabLayer(BuildContext context, int index, WorkspaceTab tab) {
    final bool isSelected = index == window.activeTabIndex;

    if (!tab.keepAlive && !isSelected) {
      return const SizedBox.shrink();
    }

    Widget content;
    final ViewDefinition? definition = registeredViews[tab.typeId];

    if (definition != null) {
      content = definition.builder(context, window, tab);
    } else if (fallbackBuilder != null) {
      content = fallbackBuilder!(context, window, tab);
    } else {
      content = _DefaultPlaceholder(tab: tab);
    }

    return Offstage(
      offstage: !isSelected,
      child: TickerMode(
        enabled: isSelected,
        child: IgnorePointer(
          ignoring: !isSelected,
          child: content,
        ),
      ),
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  final WorkspaceTab tab;

  const _DefaultPlaceholder({required this.tab});

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            tab.icon ?? Icons.dashboard_customize_rounded,
            size: 40.0,
            color: theme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8.0),
          Text(
            tab.title,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Тип компонента: ${tab.typeId}',
            style: TextStyle(
              fontSize: 11.0,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}