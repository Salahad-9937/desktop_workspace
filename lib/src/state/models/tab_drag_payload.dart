import 'workspace_tab.dart';

/// Данные перемещения вкладки при операциях Drag-and-Drop.
class TabDragPayload {
  /// Идентификатор окна, из которого перетаскивается вкладка.
  final String windowId;

  /// Индекс вкладки в исходном окне.
  final int tabIndex;

  /// Перетаскиваемая вкладка.
  final WorkspaceTab tab;

  /// Создает экземпляр [TabDragPayload].
  const TabDragPayload({
    required this.windowId,
    required this.tabIndex,
    required this.tab,
  });
}

/// Псевдоним обратной совместимости для [TabDragPayload].
typedef TabDragData = TabDragPayload;