import 'geometry_types.dart';
import 'workspace_tab.dart';

/// Нормализованное относительное размещение окна для адаптивных профилей.
class RelativeWindowPlacement {
  /// Уникальный строковый идентификатор окна.
  final String windowId;

  /// Относительная координата X (в диапазоне от 0.0 до 1.0).
  final double relativeX;

  /// Относительная координата Y (в диапазоне от 0.0 до 1.0).
  final double relativeY;

  /// Относительная ширина окна (в диапазоне от 0.0 до 1.0).
  final double relativeWidth;

  /// Относительная высота окна (в диапазоне от 0.0 до 1.0).
  final double relativeHeight;

  /// Стек вкладок контейнера.
  final List<WorkspaceTab> tabs;

  /// Индекс активной вкладки.
  final int activeTabIndex;

  /// Флаг закрепления окна поверх остальных.
  final bool isPinnedOnTop;

  /// Флаг сворачивания окна.
  final bool isMinimized;

  /// Флаг полноэкранного развертывания.
  final bool isMaximized;

  /// Режим тайлинга.
  final SnapZone snapZone;

  /// Создает неизменяемый экземпляр [RelativeWindowPlacement].
  const RelativeWindowPlacement({
    required this.windowId,
    required this.relativeX,
    required this.relativeY,
    required this.relativeWidth,
    required this.relativeHeight,
    required this.tabs,
    this.activeTabIndex = 0,
    this.isPinnedOnTop = false,
    this.isMinimized = false,
    this.isMaximized = false,
    this.snapZone = SnapZone.none,
  });

  /// Сериализует относительное размещение в карту данных.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'windowId': windowId,
      'relativeX': relativeX,
      'relativeY': relativeY,
      'relativeWidth': relativeWidth,
      'relativeHeight': relativeHeight,
      'tabs': tabs
          .map((WorkspaceTab tab) => tab.toMap())
          .toList(growable: false),
      'activeTabIndex': activeTabIndex,
      'isPinnedOnTop': isPinnedOnTop,
      'isMinimized': isMinimized,
      'isMaximized': isMaximized,
      'snapZone': snapZone.name,
    };
  }

  /// Восстанавливает относительное размещение из карты данных.
  factory RelativeWindowPlacement.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawTabs = map['tabs'] as List<dynamic>? ?? <dynamic>[];
    final List<WorkspaceTab> parsedTabs = rawTabs
        .whereType<Map<String, dynamic>>()
        .map(WorkspaceTab.fromMap)
        .toList();

    final String rawSnapZone = map['snapZone'] as String? ?? SnapZone.none.name;
    final SnapZone parsedSnap = SnapZone.values.firstWhere(
      (SnapZone z) => z.name == rawSnapZone,
      orElse: () => SnapZone.none,
    );

    return RelativeWindowPlacement(
      windowId: map['windowId'] as String,
      relativeX: (map['relativeX'] as num).toDouble(),
      relativeY: (map['relativeY'] as num).toDouble(),
      relativeWidth: (map['relativeWidth'] as num).toDouble(),
      relativeHeight: (map['relativeHeight'] as num).toDouble(),
      tabs: parsedTabs,
      activeTabIndex: map['activeTabIndex'] as int? ?? 0,
      isPinnedOnTop: map['isPinnedOnTop'] as bool? ?? false,
      isMinimized: map['isMinimized'] as bool? ?? false,
      isMaximized: map['isMaximized'] as bool? ?? false,
      snapZone: parsedSnap,
    );
  }
}

/// Именованный профиль компоновки холста (перспектива рабочего стола).
class WorkspaceProfile {
  /// Уникальный строковый идентификатор профиля.
  final String id;

  /// Отображаемое наименование профиля.
  final String name;

  /// Признак системного заводского профиля (защищен от перезаписи).
  final bool isFactory;

  /// Спецификация относительного расположения окон на холсте.
  final List<RelativeWindowPlacement> placements;

  /// Создает неизменяемый экземпляр [WorkspaceProfile].
  const WorkspaceProfile({
    required this.id,
    required this.name,
    this.isFactory = false,
    required this.placements,
  });

  /// Сериализует профиль в карту данных.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'isFactory': isFactory,
      'placements': placements
          .map((RelativeWindowPlacement p) => p.toMap())
          .toList(growable: false),
    };
  }

  /// Восстанавливает профиль из карты данных.
  factory WorkspaceProfile.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawPlacements =
        map['placements'] as List<dynamic>? ?? <dynamic>[];
    final List<RelativeWindowPlacement> parsedPlacements = rawPlacements
        .whereType<Map<String, dynamic>>()
        .map(RelativeWindowPlacement.fromMap)
        .toList();

    return WorkspaceProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      isFactory: map['isFactory'] as bool? ?? false,
      placements: parsedPlacements,
    );
  }
}