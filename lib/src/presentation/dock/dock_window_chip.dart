import 'dart:async';
import 'package:flutter/material.dart';

import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';
import 'dock_hover_preview.dart';

/// Интерактивный элемент окна на панели быстрого доступа.
class DockWindowChip extends StatefulWidget {
  /// Состояние окна.
  final WindowState window;

  /// Находится ли окно в активном фокусе.
  final bool isFocused;

  /// Обратный вызов клика по элементу.
  final VoidCallback onTap;

  /// Создает экземпляр [DockWindowChip].
  const DockWindowChip({
    super.key,
    required this.window,
    required this.isFocused,
    required this.onTap,
  });

  @override
  State<DockWindowChip> createState() => _DockWindowChipState();
}

class _DockWindowChipState extends State<DockWindowChip> {
  Timer? _hoverTimer;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final Offset position = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: position.dx,
          bottom: (box.size.height) + 12.0,
          child: DockHoverPreview(window: widget.window),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final String title = widget.window.activeTab?.title ?? 'Окно';

    return MouseRegion(
      onEnter: (_) {
        _hoverTimer = Timer(const Duration(milliseconds: 250), _showOverlay);
      },
      onExit: (_) => _removeOverlay(),
      child: GestureDetector(
        onTap: () {
          _removeOverlay();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(maxWidth: 160.0, minWidth: 40.0),
          height: 34.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: widget.isFocused
                ? theme.titlebarActive
                : (widget.window.isMinimized
                    ? theme.titlebarInactive.withValues(alpha: 0.5)
                    : theme.titlebarInactive),
            borderRadius: BorderRadius.circular(theme.windowRadius / 1.5),
            border: Border.all(
              color: widget.isFocused
                  ? theme.borderActive
                  : (widget.window.isPinnedOnTop
                      ? theme.statusPinned
                      : theme.borderInactive),
              width: widget.isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.window.activeTab?.icon ?? Icons.web_asset_rounded,
                size: 14.0,
                color: widget.isFocused
                    ? theme.accentColor
                    : (widget.window.isMinimized
                        ? theme.textMuted.withValues(alpha: 0.5)
                        : theme.textMuted),
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight:
                        widget.isFocused ? FontWeight.w600 : FontWeight.w400,
                    color: widget.window.isMinimized
                        ? theme.textMuted
                        : theme.textPrimary,
                  ),
                ),
              ),
              if (widget.window.tabs.length > 1) ...<Widget>[
                const SizedBox(width: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 1.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '+${widget.window.tabs.length - 1}',
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: theme.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}