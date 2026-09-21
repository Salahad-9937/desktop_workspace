import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';
import '../../model/tab_drag_payload.dart';
import '../../model/view_definition.dart';
import '../../model/window_state.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';
import 'window_content_host.dart';
import 'window_resize_edge.dart';
import 'window_title_bar.dart';

/// Визуальный фрейм окна с изолированной областью перерисовки.
class WindowFrame extends StatelessWidget {
  /// Геометрическое состояние окна.
  final WindowState window;

  /// Активен ли фокус на данном окне.
  final bool isFocused;

  /// Реестр определений представлений каталога.
  final Map<String, ViewDefinition> registeredViews;

  /// Фабрика контента по умолчанию.
  final WorkspaceContentBuilder? fallbackBuilder;

  /// Передача фокуса окну.
  final VoidCallback onFocus;

  /// Перемещение окна.
  final void Function(double deltaX, double deltaY, Offset pointer) onMove;

  /// Завершение перемещения.
  final VoidCallback onMoveEnd;

  /// Ресайз окна.
  final void Function(ResizeDirection direction, double deltaX, double deltaY)
      onResize;

  /// Завершение изменения размера окна.
  final VoidCallback? onResizeEnd;

  /// Двойной клик по заголовку.
  final VoidCallback onToggleMaximize;

  /// Выбор вкладки.
  final void Function(int index) onSelectTab;

  /// Закрытие вкладки.
  final void Function(String tabId) onCloseTab;

  /// Дублирование вкладки.
  final void Function(String tabId) onDuplicateTab;

  /// Слияние или переупорядочивание вкладки с опциональным целевым слотом.
  final void Function(TabDragPayload payload, int? dropIndex) onTabDropped;

  /// Закрепление окна поверх всех.
  final VoidCallback onTogglePin;

  /// Меню тайлинга.
  final void Function(SnapZone zone) onTileSelect;

  /// Сворачивание.
  final VoidCallback onMinimize;

  /// Закрытие окна.
  final VoidCallback onCloseWindow;

  /// Точка расширения прикладных действий заголовка.
  final Widget? trailingActions;

  /// Создает экземпляр [WindowFrame].
  const WindowFrame({
    super.key,
    required this.window,
    required this.isFocused,
    required this.registeredViews,
    this.fallbackBuilder,
    required this.onFocus,
    required this.onMove,
    required this.onMoveEnd,
    required this.onResize,
    this.onResizeEnd,
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
    if (window.isMinimized) {
      return const SizedBox.shrink();
    }

    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Positioned(
      left: window.x,
      top: window.y,
      width: window.width,
      height: window.height,
      child: RepaintBoundary(
        child: GestureDetector(
          onTapDown: (_) => onFocus(),
          child: Container(
            decoration: BoxDecoration(
              color: theme.windowBackground,
              borderRadius: BorderRadius.circular(
                window.isMaximized ? 0.0 : theme.windowRadius,
              ),
              border: Border.all(
                color: isFocused ? theme.borderActive : theme.borderInactive,
                width: isFocused ? 1.5 : theme.borderWidth,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isFocused ? 0.35 : 0.15,
                  ),
                  blurRadius: isFocused
                      ? theme.activeShadowElevation
                      : theme.shadowElevation,
                  offset: const Offset(0.0, 4.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                window.isMaximized ? 0.0 : theme.windowRadius - 1.0,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      WindowTitleBar(
                        window: window,
                        isFocused: isFocused,
                        onMove: onMove,
                        onMoveEnd: onMoveEnd,
                        onToggleMaximize: onToggleMaximize,
                        onSelectTab: onSelectTab,
                        onCloseTab: onCloseTab,
                        onDuplicateTab: onDuplicateTab,
                        onTabDropped: onTabDropped,
                        onTogglePin: onTogglePin,
                        onTileSelect: onTileSelect,
                        onMinimize: onMinimize,
                        onCloseWindow: onCloseWindow,
                        trailingActions: trailingActions,
                      ),
                      Expanded(
                        child: WindowContentHost(
                          window: window,
                          registeredViews: registeredViews,
                          fallbackBuilder: fallbackBuilder,
                        ),
                      ),
                    ],
                  ),
                  if (!window.isMaximized)
                    WindowResizeEdge(
                      onResize: onResize,
                      onResizeEnd: onResizeEnd,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}