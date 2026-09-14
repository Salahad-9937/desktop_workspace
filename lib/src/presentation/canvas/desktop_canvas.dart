import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../registry/panel_registry.dart';
import '../../state/controllers/workspace_controller.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_state.dart';
import '../../state/models/workspace_tab.dart';
import '../taskbar/desktop_taskbar.dart';
import '../window/window_frame.dart';
import 'desktop_background.dart';
import 'snap_dock_guides.dart';
import 'snap_preview_box.dart';

/// Корневой полноэкранный холст многооконного рабочего пространства:
/// управляет геометрией окон, горячими клавишами и зонами прилипания.
class DesktopCanvas extends ConsumerStatefulWidget {
  /// Пользовательский делегат построения содержимого вкладок окон.
  final WorkspaceContentBuilder? contentBuilder;

  /// Доступные шаблоны модулей/вкладок для создания окон и контекстных меню.
  final List<WorkspaceTab>? tabTemplates;

  /// Пользовательский фоновый виджет (по умолчанию — координатная сетка [DesktopBackground]).
  final Widget? background;

  /// Пользовательский виджет панели запуска на панели задач.
  final Widget? taskbarLeading;

  /// Пользовательский виджет системного трея для панели задач.
  final Widget? taskbarTrailing;

  /// Флаг включения глобальных горячих клавиш рабочего стола (Alt+Tab, Ctrl+W, Super+Стрелки).
  final bool enableShortcuts;

  /// Создает экземпляр [DesktopCanvas].
  const DesktopCanvas({
    super.key,
    this.contentBuilder,
    this.tabTemplates,
    this.background,
    this.taskbarLeading,
    this.taskbarTrailing,
    this.enableShortcuts = true,
  });

  @override
  ConsumerState<DesktopCanvas> createState() => _DesktopCanvasState();
}

class _DesktopCanvasState extends ConsumerState<DesktopCanvas> {
  final FocusNode _shortcutsFocusNode = FocusNode();

  @override
  void dispose() {
    _shortcutsFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enableShortcuts || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final bool meta = HardwareKeyboard.instance.isMetaPressed;
    final bool alt = HardwareKeyboard.instance.isAltPressed;
    final bool ctrl = HardwareKeyboard.instance.isControlPressed;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final LogicalKeyboardKey key = event.logicalKey;
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    if (meta && key == LogicalKeyboardKey.arrowLeft) {
      notifier.handleMetaLeft();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.arrowRight) {
      notifier.handleMetaRight();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.arrowUp) {
      notifier.handleMetaUp();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.arrowDown) {
      notifier.handleMetaDown();
      return KeyEventResult.handled;
    }
    if (alt && key == LogicalKeyboardKey.tab) {
      notifier.cycleFocus(reverse: shift);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyW) {
      notifier.closeFocusedTab();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceState workspace = ref.watch(workspaceControllerProvider);
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size currentSize = constraints.biggest;
        if (workspace.screenSize != currentSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              notifier.setScreenSize(currentSize);
            }
          });
        }

        final List<WindowState> normalWindows = workspace.windows
            .where((WindowState w) => !w.isPinnedOnTop && !w.isMinimized)
            .toList();
        final List<WindowState> pinnedWindows = workspace.windows
            .where((WindowState w) => w.isPinnedOnTop && !w.isMinimized)
            .toList();

        final List<WindowState> renderList = <WindowState>[
          ...normalWindows,
          ...pinnedWindows,
        ];

        return Focus(
          focusNode: _shortcutsFocusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Scaffold(
            body: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: widget.background ?? const DesktopBackground(),
                ),
                Positioned(
                  left: 0.0,
                  top: 0.0,
                  right: 0.0,
                  bottom: workspace.config.taskbarHeight,
                  child: SnapDockGuides(
                    pendingSnapZone: workspace.pendingSnapZone,
                  ),
                ),
                for (final WindowState win in renderList)
                  WindowFrame(
                    key: ValueKey<String>(win.id),
                    win: win,
                    isFocused: workspace.focusedWindowId == win.id,
                    contentBuilder: widget.contentBuilder,
                    tabTemplates: widget.tabTemplates,
                  ),
                if (workspace.snapPreviewRect != null)
                  SnapPreviewBox(
                    rect: workspace.snapPreviewRect!,
                  ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  height: workspace.config.taskbarHeight,
                  child: DesktopTaskbar(
                    leading: widget.taskbarLeading,
                    trailing: widget.taskbarTrailing,
                    tabTemplates: widget.tabTemplates,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}