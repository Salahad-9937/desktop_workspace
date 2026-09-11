import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/workspace_controller.dart';
import '../../models/tab_drag_data.dart';
import '../../models/window_state.dart';
import '../../models/workspace_tab.dart';
import '../../theme/desktop_theme.dart';

/// Интерактивный виджет вкладки окна с поддержкой Drag-and-Drop, отрыва и контекстного меню.
class TabChip extends ConsumerWidget {
  /// Состояние окна-владельца вкладки.
  final WindowState win;

  /// Индекс вкладки внутри окна.
  final int index;

  /// Флаг нахождения окна в активном фокусе ввода.
  final bool isFocused;

  /// Доступные шаблоны вкладок для смены модальности.
  final List<WorkspaceTab>? tabTemplates;

  /// Создает экземпляр [TabChip].
  const TabChip({
    super.key,
    required this.win,
    required this.index,
    required this.isFocused,
    this.tabTemplates,
  });

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPos,
  ) async {
    final List<PopupMenuEntry<String>> menuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'close',
        child: Text('Закрыть', style: TextStyle(fontSize: 12.0)),
      ),
      const PopupMenuItem<String>(
        value: 'duplicate',
        child: Text('Дублировать', style: TextStyle(fontSize: 12.0)),
      ),
      const PopupMenuItem<String>(
        value: 'detach',
        child: Text(
          'Открепить в отдельное окно',
          style: TextStyle(fontSize: 12.0),
        ),
      ),
    ];

    if (tabTemplates != null && tabTemplates!.isNotEmpty) {
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'change',
          child: Text('Сменить модуль…', style: TextStyle(fontSize: 12.0)),
        ),
      );
    }

    final String? action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      color: const Color(0xFF131D2E),
      items: menuItems,
    );

    if (!context.mounted || action == null) {
      return;
    }

    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    switch (action) {
      case 'close':
        notifier.closeTab(win.id, index);
      case 'duplicate':
        notifier.duplicateTab(win.id, index);
      case 'detach':
        notifier.detachTab(win.id, index, globalPos);
      case 'change':
        await _showChangeTabMenu(context, ref, globalPos);
    }
  }

  Future<void> _showChangeTabMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPos,
  ) async {
    if (tabTemplates == null || tabTemplates!.isEmpty) {
      return;
    }

    final WorkspaceTab? chosen = await showMenu<WorkspaceTab>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      color: const Color(0xFF131D2E),
      items: tabTemplates!.map((WorkspaceTab template) {
        return PopupMenuItem<WorkspaceTab>(
          value: template,
          child: Row(
            children: <Widget>[
              if (template.icon != null) ...<Widget>[
                Icon(
                  template.icon,
                  size: 14.0,
                  color: template.accentColor ?? DesktopTheme.accentColor,
                ),
                const SizedBox(width: 8.0),
              ],
              Text(
                template.title,
                style: TextStyle(
                  fontSize: 12.0,
                  color: template.accentColor ?? Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (chosen != null) {
      ref.read(workspaceControllerProvider.notifier).updateTab(
            win.id,
            index,
            chosen,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isActive = win.activeTabIndex == index;
    final WorkspaceTab tab = win.tabs[index];
    final Color accent = tab.accentColor ?? DesktopTheme.accentColor;
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    final TabDragData dragData = TabDragData(
      windowId: win.id,
      tabIndex: index,
      tab: tab,
    );

    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      margin: const EdgeInsets.only(right: 4.0),
      decoration: BoxDecoration(
        color: isActive
            ? (isFocused ? const Color(0xFF192438) : const Color(0xFF141D2C))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
        border:
            isActive ? Border.all(color: accent.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (tab.icon != null) ...<Widget>[
            Icon(
              tab.icon,
              size: 12.0,
              color: isActive ? accent : const Color(0xFF78909C),
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            tab.title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : const Color(0xFF78909C),
            ),
          ),
          if (win.tabs.length > 1) ...<Widget>[
            const SizedBox(width: 4.0),
            InkWell(
              onTap: () => notifier.closeTab(win.id, index),
              child: const Icon(
                Icons.close_rounded,
                size: 12.0,
                color: Color(0xFF78909C),
              ),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: () => notifier.selectTab(win.id, index),
      onSecondaryTapUp: (TapUpDetails details) => unawaited(
        _showContextMenu(context, ref, details.globalPosition),
      ),
      child: Draggable<TabDragData>(
        data: dragData,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFF141D2C),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: accent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (tab.icon != null) ...<Widget>[
                    Icon(tab.icon, size: 14.0, color: accent),
                    const SizedBox(width: 6.0),
                  ],
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: chip),
        onDraggableCanceled: (Velocity velocity, Offset offset) =>
            notifier.detachTab(win.id, index, offset),
        child: chip,
      ),
    );
  }
}
