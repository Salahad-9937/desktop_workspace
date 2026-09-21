import 'workspace_tab.dart';

/// Полезная нагрузка операции Drag-and-Drop при перемещении чипа вкладки.
class TabDragPayload {
  /// Перемещаемая вкладка.
  final WorkspaceTab tab;

  /// Идентификатор окна-источника, из которого перемещается вкладка.
  final String sourceWindowId;

  /// Начальный индекс вкладки в стеке окна-источника.
  final int sourceTabIndex;

  /// Флаг, определяющий, является ли вкладка единственной в окне-источнике.
  final bool isSingleTab;

  /// Создает неизменяемый экземпляр [TabDragPayload].
  const TabDragPayload({
    required this.tab,
    required this.sourceWindowId,
    required this.sourceTabIndex,
    required this.isSingleTab,
  });

  /// Создает копию нагрузки с возможностью замены полей.
  TabDragPayload copyWith({
    WorkspaceTab? tab,
    String? sourceWindowId,
    int? sourceTabIndex,
    bool? isSingleTab,
  }) {
    return TabDragPayload(
      tab: tab ?? this.tab,
      sourceWindowId: sourceWindowId ?? this.sourceWindowId,
      sourceTabIndex: sourceTabIndex ?? this.sourceTabIndex,
      isSingleTab: isSingleTab ?? this.isSingleTab,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TabDragPayload &&
        other.tab == tab &&
        other.sourceWindowId == sourceWindowId &&
        other.sourceTabIndex == sourceTabIndex &&
        other.isSingleTab == isSingleTab;
  }

  @override
  int get hashCode =>
      Object.hash(tab, sourceWindowId, sourceTabIndex, isSingleTab);

  @override
  String toString() {
    return 'TabDragPayload(tab: ${tab.id}, sourceWindow: $sourceWindowId, index: $sourceTabIndex, isSingle: $isSingleTab)';
  }
}