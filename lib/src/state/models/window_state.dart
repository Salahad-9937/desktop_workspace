import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'workspace_tab.dart';

/// Иммутабельная модель состояния отдельного плавающего окна рабочего пространства.
@immutable
class WindowState {
  /// Уникальный строковый идентификатор окна.
  final String id;

  /// Список открытых вкладок в окне.
  final List<WorkspaceTab> tabs;

  /// Индекс текущей активной вкладки.
  final int activeTabIndex;

  /// Координата X верхнего левого угла окна на рабочем столе.
  final double x;

  /// Координата Y верхнего левого угла окна на рабочем столе.
  final double y;

  /// Ширина окна в пикселях.
  final double width;

  /// Высота окна в пикселях.
  final double height;

  /// Флаг закрепления окна поверх всех остальных (Always on Top).
  final bool isPinnedOnTop;

  /// Флаг минимизации окна в панель задач.
  final bool isMinimized;

  /// Флаг максимизации окна на всю рабочую область.
  final bool isMaximized;

  /// Исходные геометрические координаты окна до максимизации или тайлинга.
  final Rect? restoreRect;

  /// Создает экземпляр [WindowState].
  const WindowState({
    required this.id,
    required this.tabs,
    this.activeTabIndex = 0,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isPinnedOnTop = false,
    this.isMinimized = false,
    this.isMaximized = false,
    this.restoreRect,
  });

  /// Возвращает текущую активную вкладку окна.
  WorkspaceTab? get activeTab {
    if (tabs.isEmpty) {
      return null;
    }
    final int safeIndex = activeTabIndex.clamp(0, tabs.length - 1);
    return tabs[safeIndex];
  }

  /// Создает копию окна с обновлением указанных параметров.
  WindowState copyWith({
    String? id,
    List<WorkspaceTab>? tabs,
    int? activeTabIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isPinnedOnTop,
    bool? isMinimized,
    bool? isMaximized,
    Rect? Function()? restoreRect,
  }) {
    return WindowState(
      id: id ?? this.id,
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isPinnedOnTop: isPinnedOnTop ?? this.isPinnedOnTop,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
      restoreRect: restoreRect != null ? restoreRect() : this.restoreRect,
    );
  }

  /// Сериализует состояние окна в JSON-совместимый словарь.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'tabs': tabs.map((WorkspaceTab t) => t.toJson()).toList(),
        'activeTabIndex': activeTabIndex,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'isPinnedOnTop': isPinnedOnTop,
        'isMinimized': isMinimized,
        'isMaximized': isMaximized,
        if (restoreRect != null)
          'restoreRect': <String, Object?>{
            'left': restoreRect!.left,
            'top': restoreRect!.top,
            'width': restoreRect!.width,
            'height': restoreRect!.height,
          },
      };

  /// Восстанавливает объект [WindowState] из типизированного словаря без dynamic-вызовов.
  factory WindowState.fromJson(Map<String, Object?> json) {
    final List<WorkspaceTab> tabs = <WorkspaceTab>[];
    final Object? rawTabs = json['tabs'];
    if (rawTabs is List) {
      for (final Object? item in rawTabs) {
        if (item is Map<String, Object?>) {
          tabs.add(WorkspaceTab.fromJson(item));
        } else if (item is Map) {
          tabs.add(WorkspaceTab.fromJson(Map<String, Object?>.from(item)));
        }
      }
    }

    final Object? rawRestore = json['restoreRect'];
    Rect? restoreRect;
    if (rawRestore is Map) {
      final Object? l = rawRestore['left'];
      final Object? t = rawRestore['top'];
      final Object? w = rawRestore['width'];
      final Object? h = rawRestore['height'];
      if (l is num && t is num && w is num && h is num) {
        restoreRect = Rect.fromLTWH(
          l.toDouble(),
          t.toDouble(),
          w.toDouble(),
          h.toDouble(),
        );
      }
    }

    return WindowState(
      id: json['id'] as String? ?? 'win_unknown',
      tabs: tabs.isEmpty
          ? const <WorkspaceTab>[WorkspaceTab(id: 'default', title: 'Окно')]
          : List<WorkspaceTab>.unmodifiable(tabs),
      activeTabIndex: (json['activeTabIndex'] as num?)?.toInt() ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 50.0,
      y: (json['y'] as num?)?.toDouble() ?? 50.0,
      width: (json['width'] as num?)?.toDouble() ?? 580.0,
      height: (json['height'] as num?)?.toDouble() ?? 420.0,
      isPinnedOnTop: json['isPinnedOnTop'] as bool? ?? false,
      isMinimized: json['isMinimized'] as bool? ?? false,
      isMaximized: json['isMaximized'] as bool? ?? false,
      restoreRect: restoreRect,
    );
  }
}