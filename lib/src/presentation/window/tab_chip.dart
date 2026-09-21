import 'dart:async';
import 'package:flutter/material.dart';

import '../../model/tab_drag_payload.dart';
import '../../model/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';
import 'tab_close_button.dart';
import 'tab_drop_indicator.dart';

/// Интерактивный гибридный чип вкладки с заголовком, кнопкой закрытия и поддержкой сортировки.
class TabChip extends StatefulWidget {
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

  /// Обратный вызов сброса перетаскиваемой вкладки в позицию целевого слота.
  final void Function(TabDragPayload payload, int targetIndex)? onTabDrop;

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
    this.onTabDrop,
  });

  @override
  State<TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<TabChip> {
  bool _isHovered = false;
  bool _isDropHovered = false;
  bool _dropOnLeft = true;
  TabDragPayload? _activePayload;

  bool _isValidDrop(TabDragPayload payload) {
    if (payload.sourceWindowId == widget.windowId) {
      if (payload.sourceTabIndex == widget.tabIndex) {
        return false;
      }
      if (_dropOnLeft && payload.sourceTabIndex == widget.tabIndex - 1) {
        return false;
      }
      if (!_dropOnLeft && payload.sourceTabIndex == widget.tabIndex + 1) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final Color effectiveAccent = widget.tab.accentColor ?? theme.accentColor;

    final TabDragPayload payload = TabDragPayload(
      tab: widget.tab,
      sourceWindowId: widget.windowId,
      sourceTabIndex: widget.tabIndex,
      isSingleTab: widget.isSingleTab,
    );

    final bool isExpanded = widget.isActive || _isHovered;

    final Widget chipBody = ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(theme.windowRadius / 1.5),
        topRight: Radius.circular(theme.windowRadius / 1.5),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minWidth: widget.isActive ? 48.0 : (_isHovered ? 48.0 : 36.0),
          maxWidth: isExpanded ? 140.0 : 36.0,
        ),
        height: 28.0,
        decoration: BoxDecoration(
          color: widget.isActive
              ? theme.windowBackground
              : (_isHovered
                  ? theme.titlebarActive.withValues(alpha: 0.7)
                  : theme.titlebarInactive.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(theme.windowRadius / 1.5),
            topRight: Radius.circular(theme.windowRadius / 1.5),
          ),
          border: Border.all(
            color: widget.isActive
                ? theme.borderActive
                : (_isHovered
                    ? theme.borderActive.withValues(alpha: 0.5)
                    : theme.borderInactive),
            width: 0.5,
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 2.0,
              color: widget.isActive ? effectiveAccent : Colors.transparent,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  height: 25.0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 6.0 : 10.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        widget.tab.icon ?? Icons.web_asset_rounded,
                        size: 14.0,
                        color: widget.isActive
                            ? effectiveAccent
                            : (_isHovered
                                ? theme.textPrimary
                                : theme.textMuted),
                      ),
                      if (isExpanded) ...<Widget>[
                        const SizedBox(width: 5.0),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80.0),
                          child: Text(
                            widget.tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: widget.isActive
                                  ? theme.textPrimary
                                  : theme.textMuted,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        TabCloseButton(
                          onClose: widget.onClose,
                          normalColor: theme.textMuted,
                          hoverColor: theme.actionCloseHover,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final bool showLeftIndicator = _isDropHovered &&
        _activePayload != null &&
        _isValidDrop(_activePayload!) &&
        _dropOnLeft;

    final bool showRightIndicator = _isDropHovered &&
        _activePayload != null &&
        _isValidDrop(_activePayload!) &&
        !_dropOnLeft;

    return DragTarget<TabDragPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<TabDragPayload> details) {
        return true;
      },
      onMove: (DragTargetDetails<TabDragPayload> details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final Offset localPos = box.globalToLocal(details.offset);
          final bool isLeft = localPos.dx < (box.size.width / 2.0);
          if (_dropOnLeft != isLeft ||
              !_isDropHovered ||
              _activePayload != details.data) {
            setState(() {
              _isDropHovered = true;
              _dropOnLeft = isLeft;
              _activePayload = details.data;
            });
          }
        }
      },
      onLeave: (_) {
        if (_isDropHovered) {
          setState(() {
            _isDropHovered = false;
            _activePayload = null;
          });
        }
      },
      onAcceptWithDetails: (DragTargetDetails<TabDragPayload> details) {
        final int targetSlot =
            _dropOnLeft ? widget.tabIndex : widget.tabIndex + 1;
        setState(() {
          _isDropHovered = false;
          _activePayload = null;
        });
        widget.onTabDrop?.call(details.data, targetSlot);
      },
      builder: (
        BuildContext context,
        List<TabDragPayload?> candidateData,
        List<dynamic> rejectedData,
      ) {
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Tooltip(
              message: widget.tab.title,
              waitDuration: const Duration(milliseconds: 400),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: widget.onSelect,
                  onSecondaryTapUp: (TapUpDetails details) {
                    _showContextMenu(context, details.globalPosition);
                  },
                  child: Draggable<TabDragPayload>(
                    data: payload,
                    feedback: Material(
                      elevation: 8.0,
                      borderRadius:
                          BorderRadius.circular(theme.windowRadius / 1.5),
                      color: theme.windowBackground.withValues(alpha: 0.95),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(theme.windowRadius / 1.5),
                          border:
                              Border.all(color: effectiveAccent, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              widget.tab.icon ?? Icons.web_asset_rounded,
                              size: 14.0,
                              color: effectiveAccent,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              widget.tab.title,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.25,
                      child: chipBody,
                    ),
                    child: chipBody,
                  ),
                ),
              ),
            ),
            if (showLeftIndicator)
              TabDropIndicator(isLeft: true, color: theme.accentColor),
            if (showRightIndicator)
              TabDropIndicator(isLeft: false, color: theme.accentColor),
          ],
        );
      },
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
          widget.onDuplicate();
        } else if (value == 'close') {
          widget.onClose();
        }
      }),
    );
  }
}