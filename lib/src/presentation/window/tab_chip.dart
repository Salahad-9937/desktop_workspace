import 'dart:async';
import 'package:flutter/material.dart';

import '../../model/tab_drag_payload.dart';
import '../../model/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Компактный интерактивный чип вкладки в заголовке окна с отображением пиктограммы.
class TabChip extends StatelessWidget {
  /// Метаданные вкладки.
  final WorkspaceTab tab;

  /// Активна ли вкладка в текущем окне.
  final bool isActive;

  /// Идентификатор несущего окна.
  final String windowId;

  /// Порядковый индекс вкладки в окне.
  final int tabIndex;

  /// Является ли вкладка единственной в окне.
  final bool isSingleTab;

  /// Обратный вызов выбора активной вкладки.
  final VoidCallback onSelect;

  /// Обратный вызов закрытия вкладки.
  final VoidCallback onClose;

  /// Обратный вызов дублирования вкладки.
  final VoidCallback onDuplicate;

  /// Создает экземпляр [TabChip].
  const TabChip({
    super.key,
    required this.tab,
    required this.isActive,
    required this.windowId,
    required this.tabIndex,
    required this.isSingleTab,
    required this.onSelect,
    required this.onClose,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final Color effectiveAccent = tab.accentColor ?? theme.accentColor;

    final TabDragPayload payload = TabDragPayload(
      tab: tab,
      sourceWindowId: windowId,
      sourceTabIndex: tabIndex,
      isSingleTab: isSingleTab,
    );

    final Widget chipBody = ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(theme.windowRadius / 1.5),
        topRight: Radius.circular(theme.windowRadius / 1.5),
      ),
      child: Container(
        width: 36.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: isActive
              ? theme.windowBackground
              : theme.titlebarInactive.withValues(alpha: 0.6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(theme.windowRadius / 1.5),
            topRight: Radius.circular(theme.windowRadius / 1.5),
          ),
          border: Border.all(
            color: isActive ? theme.borderActive : theme.borderInactive,
            width: 0.5,
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 2.0,
              color: isActive ? effectiveAccent : Colors.transparent,
            ),
            Expanded(
              child: Center(
                child: Icon(
                  tab.icon ?? Icons.web_asset_rounded,
                  size: 15.0,
                  color: isActive ? effectiveAccent : theme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Tooltip(
      message: tab.title,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onSelect,
        onSecondaryTapUp: (TapUpDetails details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: Draggable<TabDragPayload>(
          data: payload,
          feedback: Material(
            elevation: 6.0,
            borderRadius: BorderRadius.circular(theme.windowRadius),
            color: theme.windowBackground.withValues(alpha: 0.9),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    tab.icon ?? Icons.web_asset_rounded,
                    size: 14.0,
                    color: effectiveAccent,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: theme.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: chipBody,
          ),
          child: chipBody,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    unawaited(
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1.0,
          position.dy + 1.0,
        ),
        items: const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'duplicate',
            child: Row(
              children: <Widget>[
                Icon(Icons.copy_rounded, size: 14.0),
                SizedBox(width: 8.0),
                Text('Дублировать', style: TextStyle(fontSize: 12.0)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'close',
            child: Row(
              children: <Widget>[
                Icon(Icons.close_rounded, size: 14.0),
                SizedBox(width: 8.0),
                Text('Закрыть', style: TextStyle(fontSize: 12.0)),
              ],
            ),
          ),
        ],
      ).then((String? value) {
        if (value == 'duplicate') {
          onDuplicate();
        } else if (value == 'close') {
          onClose();
        }
      }),
    );
  }
}