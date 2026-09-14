import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../registry/panel_registry.dart';
import '../../state/controllers/workspace_controller.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import 'window_content_host.dart';
import 'window_resize_edge.dart';
import 'window_title_bar.dart';

/// Виджет плавающего окна рабочего пространства с Z-индексом, фокусом и ручками масштабирования.
class WindowFrame extends ConsumerWidget {
  /// Состояние отображаемого окна.
  final WindowState win;

  /// Флаг нахождения окна в активном фокусе.
  final bool isFocused;

  /// Пользовательский делегат построения содержимого окна.
  final WorkspaceContentBuilder? contentBuilder;

  /// Доступные шаблоны вкладок для контекстных меню.
  final List<WorkspaceTab>? tabTemplates;

  /// Создает экземпляр [WindowFrame].
  const WindowFrame({
    super.key,
    required this.win,
    required this.isFocused,
    this.contentBuilder,
    this.tabTemplates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkspaceTab activeTab = win.activeTab ??
        const WorkspaceTab(
          id: 'default',
          title: 'Окно',
        );
    final Color accent = activeTab.accentColor ?? DesktopTheme.accentColor;
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    return Positioned(
      left: win.x,
      top: win.y,
      width: win.width,
      height: win.height,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: (_) => notifier.bringToFront(win.id),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1A),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isFocused
                  ? accent
                  : const Color(0xFF1E2836).withValues(alpha: 0.8),
              width: isFocused ? 1.5 : 1.0,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isFocused ? 0.6 : 0.3),
                blurRadius: isFocused ? 18.0 : 8.0,
                offset: const Offset(0.0, 4.0),
              ),
              if (win.isPinnedOnTop)
                BoxShadow(
                  color: const Color(0xFFFFAB00).withValues(alpha: 0.2),
                  blurRadius: 10.0,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.0),
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    WindowTitleBar(
                      win: win,
                      isFocused: isFocused,
                      tabTemplates: tabTemplates,
                    ),
                    Expanded(
                      child: WindowContentHost(
                        win: win,
                        tab: activeTab,
                        contentBuilder: contentBuilder,
                      ),
                    ),
                  ],
                ),
                if (!win.isMaximized)
                  WindowResizeEdge(
                    win: win,
                    accentColor: isFocused ? accent : const Color(0xFF78909C),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}