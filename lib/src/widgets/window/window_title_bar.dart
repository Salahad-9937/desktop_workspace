import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/workspace_controller.dart';
import '../../models/tab_drag_data.dart';
import '../../models/window_state.dart';
import '../../models/workspace_tab.dart';
import '../../theme/desktop_theme.dart';
import 'tab_chip.dart';

/// Заголовок плавающего окна с вкладками, зоной перетаскивания и кнопками управления.
class WindowTitleBar extends ConsumerWidget {
  /// Состояние окна.
  final WindowState win;

  /// Флаг нахождения в фокусе ввода.
  final bool isFocused;

  /// Доступные шаблоны вкладок для добавления новых модулей.
  final List<WorkspaceTab>? tabTemplates;

  /// Создает экземпляр [WindowTitleBar].
  const WindowTitleBar({
    super.key,
    required this.win,
    required this.isFocused,
    this.tabTemplates,
  });

  Future<void> _showAddTabMenu(BuildContext context, WidgetRef ref) async {
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    if (tabTemplates == null || tabTemplates!.isEmpty) {
      notifier.addTab(
        win.id,
        WorkspaceTab(
          id: 'tab_${win.tabs.length + 1}',
          title: 'Вкладка ${win.tabs.length + 1}',
        ),
      );
      return;
    }

    final WorkspaceTab? chosen = await showMenu<WorkspaceTab>(
      context: context,
      position: const RelativeRect.fromLTRB(200.0, 100.0, 200.0, 100.0),
      color: const Color(0xFF131D2E),
      items: tabTemplates!.map((WorkspaceTab template) {
        final Color accent = template.accentColor ?? DesktopTheme.accentColor;
        return PopupMenuItem<WorkspaceTab>(
          value: template,
          child: Row(
            children: <Widget>[
              if (template.icon != null) ...<Widget>[
                Icon(template.icon, size: 16.0, color: accent),
                const SizedBox(width: 8.0),
              ],
              Text(
                template.title,
                style: TextStyle(
                  fontSize: 12.0,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (chosen != null) {
      notifier.addTab(win.id, chosen);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);
    final WorkspaceTab? activeTab = win.activeTab;
    final Color accent = activeTab?.accentColor ?? DesktopTheme.accentColor;
    final IconData icon = activeTab?.icon ?? Icons.web_asset_rounded;

    return DragTarget<TabDragData>(
      onWillAcceptWithDetails: (DragTargetDetails<TabDragData> details) => true,
      onAcceptWithDetails: (DragTargetDetails<TabDragData> details) {
        notifier.mergeTab(
          details.data.windowId,
          details.data.tabIndex,
          win.id,
        );
      },
      builder: (
        BuildContext context,
        List<TabDragData?> candidates,
        List<dynamic> rejected,
      ) {
        final bool mergeHighlight = candidates.isNotEmpty;

        return Container(
          height: 36.0,
          decoration: BoxDecoration(
            color: mergeHighlight
                ? accent.withValues(alpha: 0.22)
                : (isFocused
                    ? const Color(0xFF121B2B)
                    : const Color(0xFF0C121D)),
            border: Border.all(
              color: mergeHighlight
                  ? accent
                  : (isFocused
                      ? accent.withValues(alpha: 0.3)
                      : const Color(0xFF1E2836)),
              width: mergeHighlight ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 6.0),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (DragUpdateDetails d) {
                  if (!win.isMaximized) {
                    notifier.moveWindow(win.id, d.delta);
                    notifier.updateSnapPreview(d.globalPosition);
                  }
                },
                onPanEnd: (DragEndDetails d) =>
                    notifier.commitSnapIfPending(win.id),
                onDoubleTap: () => notifier.tileWindow(
                  win.id,
                  win.isMaximized ? 'restore' : 'maximize',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    icon,
                    size: 15.0,
                    color: isFocused ? accent : const Color(0xFF78909C),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (DragUpdateDetails d) {
                          if (!win.isMaximized) {
                            notifier.moveWindow(win.id, d.delta);
                            notifier.updateSnapPreview(d.globalPosition);
                          }
                        },
                        onPanEnd: (DragEndDetails d) =>
                            notifier.commitSnapIfPending(win.id),
                        onDoubleTap: () => notifier.tileWindow(
                          win.id,
                          win.isMaximized ? 'restore' : 'maximize',
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                for (int i = 0; i < win.tabs.length; i++)
                                  TabChip(
                                    win: win,
                                    index: i,
                                    isFocused: isFocused,
                                    tabTemplates: tabTemplates,
                                  ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.add_rounded, size: 14.0),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24.0,
                                    minHeight: 24.0,
                                  ),
                                  tooltip: 'Добавить вкладку',
                                  onPressed: () => unawaited(
                                    _showAddTabMenu(context, ref),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  win.isPinnedOnTop
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 14.0,
                  color: win.isPinnedOnTop
                      ? const Color(0xFFFFAB00)
                      : const Color(0xFF78909C),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26.0),
                tooltip: win.isPinnedOnTop
                    ? 'Открепить окно'
                    : 'Закрепить поверх всех',
                onPressed: () => notifier.togglePin(win.id),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.grid_view_rounded,
                  size: 14.0,
                  color: Color(0xFF78909C),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26.0),
                tooltip: 'Прикрепить к области экрана (Quick Tile)',
                color: const Color(0xFF131D2E),
                itemBuilder: (BuildContext ctx) =>
                    const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'left_half',
                    child: Text(
                      'Левая половина',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'right_half',
                    child: Text(
                      'Правая половина',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'top_left',
                    child: Text(
                      'Верхняя левая четверть',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'top_right',
                    child: Text(
                      'Верхняя правая четверть',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'bottom_left',
                    child: Text(
                      'Нижняя левая четверть',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'bottom_right',
                    child: Text(
                      'Нижняя правая четверть',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'restore',
                    child: Text(
                      'Вернуть исходный размер',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                ],
                onSelected: (String mode) => notifier.tileWindow(win.id, mode),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_rounded,
                  size: 14.0,
                  color: Color(0xFF78909C),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26.0),
                tooltip: 'Свернуть в панель задач',
                onPressed: () => notifier.toggleMinimize(win.id),
              ),
              IconButton(
                icon: Icon(
                  win.isMaximized
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  size: 14.0,
                  color: const Color(0xFF78909C),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26.0),
                tooltip: win.isMaximized ? 'Восстановить' : 'На весь экран',
                onPressed: () => notifier.tileWindow(
                  win.id,
                  win.isMaximized ? 'restore' : 'maximize',
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14.0,
                  color: Color(0xFFFF5252),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26.0),
                tooltip: 'Закрыть окно',
                onPressed: () => notifier.closeWindow(win.id),
              ),
              const SizedBox(width: 4.0),
            ],
          ),
        );
      },
    );
  }
}
