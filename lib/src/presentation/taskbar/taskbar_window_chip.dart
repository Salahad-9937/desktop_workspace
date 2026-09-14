import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/controllers/workspace_controller.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_state.dart';
import '../../state/models/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import 'hover_preview.dart';

/// Кнопка окна на панели задач с индикацией состояния и карточкой предпросмотра.
class TaskbarWindowChip extends ConsumerStatefulWidget {
  /// Состояние связанного окна.
  final WindowState win;

  /// Создает экземпляр [TaskbarWindowChip].
  const TaskbarWindowChip({
    super.key,
    required this.win,
  });

  @override
  ConsumerState<TaskbarWindowChip> createState() => _TaskbarWindowChipState();
}

class _TaskbarWindowChipState extends ConsumerState<TaskbarWindowChip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showPreview() {
    _removePreview();
    final WorkspaceTab tab = widget.win.activeTab ??
        const WorkspaceTab(id: 'default', title: 'Окно');

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        width: 200.0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0.0, -6.0),
          child: HoverPreview(
            win: widget.win,
            tab: tab,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WindowState win = widget.win;
    final WorkspaceState workspace = ref.watch(workspaceControllerProvider);
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    final bool isFocused =
        workspace.focusedWindowId == win.id && !win.isMinimized;
    final WorkspaceTab tab =
        win.activeTab ?? const WorkspaceTab(id: 'default', title: 'Окно');
    final Color accent = tab.accentColor ?? DesktopTheme.accentColor;
    final IconData icon = tab.icon ?? Icons.web_asset_rounded;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showPreview(),
        onExit: (_) => _removePreview(),
        child: InkWell(
          onTap: () {
            _removePreview();
            if (win.isMinimized) {
              notifier.toggleMinimize(win.id);
              notifier.bringToFront(win.id);
            } else if (workspace.focusedWindowId == win.id) {
              notifier.toggleMinimize(win.id);
            } else {
              notifier.bringToFront(win.id);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 6.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: isFocused
                  ? accent.withValues(alpha: 0.25)
                  : (win.isMinimized
                      ? const Color(0xFF0D121D)
                      : const Color(0xFF131A28)),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: isFocused ? accent : const Color(0xFF223046),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 13.0,
                  color: accent,
                ),
                const SizedBox(width: 5.0),
                Text(
                  win.tabs.length > 1
                      ? '${tab.title} (+${win.tabs.length - 1})'
                      : tab.title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                    color: win.isMinimized
                        ? const Color(0xFF78909C)
                        : Colors.white,
                  ),
                ),
                if (win.isPinnedOnTop) ...<Widget>[
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 10.0,
                    color: Color(0xFFFFAB00),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Псевдоним обратной совместимости для [TaskbarWindowChip].
typedef TaskbarItem = TaskbarWindowChip;