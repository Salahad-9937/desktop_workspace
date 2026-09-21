import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';
import '../../model/tab_drag_payload.dart';
import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';
import 'tab_chip.dart';

/// Интерактивная полоса заголовка оконного фрейма на всю ширину окна.
class WindowTitleBar extends StatelessWidget {
  /// Состояние оконного контейнера.
  final WindowState window;

  /// Активен ли контейнер в фокусе.
  final bool isFocused;

  /// Обратный вызов перемещения окна при драге заголовка.
  final void Function(double deltaX, double deltaY, Offset pointer) onMove;

  /// Завершение перемещения окна.
  final VoidCallback onMoveEnd;

  /// Переключение развертывания по двойному клику.
  final VoidCallback onToggleMaximize;

  /// Выбор активной вкладки.
  final void Function(int index) onSelectTab;

  /// Закрытие вкладки.
  final void Function(String tabId) onCloseTab;

  /// Дублирование вкладки.
  final void Function(String tabId) onDuplicateTab;

  /// Прием перетаскиваемой вкладки с целевой позицией слота вставки.
  final void Function(TabDragPayload payload, int? dropIndex) onTabDropped;

  /// Переключение постоянного закрепления (Always on Top).
  final VoidCallback onTogglePin;

  /// Выбор зоны тайлинга через контекстное меню.
  final void Function(SnapZone zone) onTileSelect;

  /// Сворачивание окна.
  final VoidCallback onMinimize;

  /// Закрытие всего окна.
  final VoidCallback onCloseWindow;

  /// Точка расширения прикладных действий хоста.
  final Widget? trailingActions;

  /// Создает экземпляр [WindowTitleBar].
  const WindowTitleBar({
    super.key,
    required this.window,
    required this.isFocused,
    required this.onMove,
    required this.onMoveEnd,
    required this.onToggleMaximize,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onDuplicateTab,
    required this.onTabDropped,
    required this.onTogglePin,
    required this.onTileSelect,
    required this.onMinimize,
    required this.onCloseWindow,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Container(
      width: double.infinity,
      height: theme.titlebarHeight,
      decoration: BoxDecoration(
        color: isFocused ? theme.titlebarActive : theme.titlebarInactive,
        border: Border(
          bottom: BorderSide(
            color: isFocused ? theme.borderActive : theme.borderInactive,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Лента чипов вкладок с поддержкой Reordering и Drop индикации
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < window.tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 3.0),
                    child: TabChip(
                      key: ValueKey<String>(window.tabs[i].id),
                      tab: window.tabs[i],
                      isActive: i == window.activeTabIndex,
                      windowId: window.id,
                      tabIndex: i,
                      isSingleTab: window.tabs.length == 1,
                      onSelect: () => onSelectTab(i),
                      onClose: () => onCloseTab(window.tabs[i].id),
                      onDuplicate: () => onDuplicateTab(window.tabs[i].id),
                      onTabDrop: onTabDropped,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4.0),
          // Свободная область перемещения окна с поддержкой сброса таба в конец стека
          Expanded(
            child: DragTarget<TabDragPayload>(
              onWillAcceptWithDetails:
                  (DragTargetDetails<TabDragPayload> details) {
                if (details.data.sourceWindowId == window.id) {
                  return details.data.sourceTabIndex != window.tabs.length - 1;
                }
                return true;
              },
              onAcceptWithDetails: (DragTargetDetails<TabDragPayload> details) {
                onTabDropped(details.data, window.tabs.length);
              },
              builder: (
                BuildContext context,
                List<TabDragPayload?> candidateData,
                List<dynamic> rejectedData,
              ) {
                final bool isHovered = candidateData.isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: isHovered
                        ? theme.previewOverlay.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: isHovered
                        ? Border(
                            left: BorderSide(
                              color: theme.accentColor,
                              width: 2.0,
                            ),
                          )
                        : null,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: onToggleMaximize,
                    onPanUpdate: (DragUpdateDetails details) {
                      onMove(
                        details.delta.dx,
                        details.delta.dy,
                        details.globalPosition,
                      );
                    },
                    onPanEnd: (_) => onMoveEnd(),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
          // Слот прикладных действий хоста
          if (trailingActions != null) trailingActions!,
          // Блок системных кнопок окна
          _HeaderIconButton(
            icon: Icons.push_pin_rounded,
            tooltip: window.isPinnedOnTop
                ? 'Открепить поверх всех'
                : 'Закрепить поверх всех',
            iconColor:
                window.isPinnedOnTop ? theme.statusPinned : theme.textMuted,
            onPressed: onTogglePin,
          ),
          _TileMenuButton(
            onTileSelect: onTileSelect,
            iconColor: theme.textMuted,
          ),
          _HeaderIconButton(
            icon: Icons.horizontal_rule_rounded,
            tooltip: 'Свернуть',
            iconColor: theme.textMuted,
            onPressed: onMinimize,
          ),
          _HeaderIconButton(
            icon: window.isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            tooltip: window.isMaximized ? 'Восстановить' : 'Развернуть',
            iconColor: theme.textMuted,
            onPressed: onToggleMaximize,
          ),
          _HeaderIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Закрыть',
            iconColor: theme.textMuted,
            hoverColor: theme.actionCloseHover,
            onPressed: onCloseWindow,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final Color? hoverColor;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.iconColor,
    this.hoverColor,
    required this.onPressed,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          child: SizedBox(
            width: 32.0,
            height: 32.0,
            child: Icon(
              widget.icon,
              size: 14.0,
              color: _isHovered && widget.hoverColor != null
                  ? widget.hoverColor
                  : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TileMenuButton extends StatelessWidget {
  final void Function(SnapZone zone) onTileSelect;
  final Color iconColor;

  const _TileMenuButton({
    required this.onTileSelect,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SnapZone>(
      tooltip: 'Меню тайлинга',
      icon: Icon(Icons.grid_view_rounded, size: 14.0, color: iconColor),
      padding: EdgeInsets.zero,
      onSelected: onTileSelect,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SnapZone>>[
        const PopupMenuItem<SnapZone>(
          value: SnapZone.maximize,
          child: Row(
            children: <Widget>[
              Icon(Icons.crop_square_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('На весь экран', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.leftHalf,
          child: Row(
            children: <Widget>[
              Icon(Icons.align_horizontal_left_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Левая половина', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.rightHalf,
          child: Row(
            children: <Widget>[
              Icon(Icons.align_horizontal_right_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Правая половина', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.none,
          child: Row(
            children: <Widget>[
              Icon(Icons.layers_clear_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Снять тайлинг', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
      ],
    );
  }
}