import '../config/window_constraints.dart';
import 'geometry_types.dart';
import 'workspace_tab.dart';

/// Неизменяемое состояние контейнера окна на холсте.
class WindowState {
  /// Уникальный строковый идентификатор окна.
  final String id;

  /// Координата X левой границы на холсте.
  final double x;

  /// Координата Y верхней границы на холсте.
  final double y;

  /// Текущая физическая ширина окна.
  final double width;

  /// Текущая физическая высота окна.
  final double height;

  /// Упорядоченный массив вложенных вкладок контейнера.
  final List<WorkspaceTab> tabs;

  /// Индекс активной вкладки, отображаемой в текущий момент.
  final int activeTabIndex;

  /// Флаг закрепления окна поверх всех остальных слоев (Always on Top).
  final bool isPinnedOnTop;

  /// Флаг сворачивания окна в док-панель.
  final bool isMinimized;

  /// Флаг полноэкранного развертывания на всю полезную область.
  final bool isMaximized;

  /// Текущий режим тайлинга окна.
  final SnapZone snapZone;

  /// Сохраненная геометрия для возврата из развернутого или тайлового состояния.
  final WorkspaceRect? restoreRect;

  /// Временная метка создания окна для сохранения стабильного порядка в док-панели.
  final int createdAt;

  /// Создает неизменяемый экземпляр [WindowState].
  const WindowState({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.tabs,
    this.activeTabIndex = 0,
    this.isPinnedOnTop = false,
    this.isMinimized = false,
    this.isMaximized = false,
    this.snapZone = SnapZone.none,
    this.restoreRect,
    this.createdAt = 0,
  })  : assert(width >= 0.0, 'Ширина окна не может быть отрицательной'),
        assert(height >= 0.0, 'Высота окна не может быть отрицательной');

  /// Возвращает метаданные активной вкладки либо `null`, если вкладки отсутствуют.
  WorkspaceTab? get activeTab {
    if (tabs.isEmpty || activeTabIndex < 0 || activeTabIndex >= tabs.length) {
      return null;
    }
    return tabs[activeTabIndex];
  }

  /// Возвращает текущий геометрический прямоугольник окна.
  WorkspaceRect get rect =>
      WorkspaceRect(x: x, y: y, width: width, height: height);

  /// Вычисляет действующие размерные ограничения окна с учетом активной вкладки.
  WindowConstraints resolveEffectiveConstraints(
    WindowConstraints globalDefault,
  ) {
    final WorkspaceTab? tab = activeTab;
    if (tab?.constraints == null) {
      return globalDefault;
    }
    return globalDefault.resolveWith(tab!.constraints);
  }

  /// Создает копию состояния окна с модификацией выбранных свойств.
  WindowState copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    List<WorkspaceTab>? tabs,
    int? activeTabIndex,
    bool? isPinnedOnTop,
    bool? isMinimized,
    bool? isMaximized,
    SnapZone? snapZone,
    WorkspaceRect? restoreRect,
    int? createdAt,
  }) {
    return WindowState(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isPinnedOnTop: isPinnedOnTop ?? this.isPinnedOnTop,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
      snapZone: snapZone ?? this.snapZone,
      restoreRect: restoreRect ?? this.restoreRect,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Сериализует состояние окна в карту данных для долговременного хранения.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'tabs': tabs
          .map((WorkspaceTab tab) => tab.toMap())
          .toList(growable: false),
      'activeTabIndex': activeTabIndex,
      'isPinnedOnTop': isPinnedOnTop,
      'isMinimized': isMinimized,
      'isMaximized': isMaximized,
      'snapZone': snapZone.name,
      'createdAt': createdAt,
      if (restoreRect != null)
        'restoreRect': <String, dynamic>{
          'x': restoreRect!.x,
          'y': restoreRect!.y,
          'width': restoreRect!.width,
          'height': restoreRect!.height,
        },
    };
  }

  /// Восстанавливает состояние окна из карты данных.
  factory WindowState.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawTabs = map['tabs'] as List<dynamic>? ?? <dynamic>[];
    final List<WorkspaceTab> parsedTabs = rawTabs
        .whereType<Map<String, dynamic>>()
        .map(WorkspaceTab.fromMap)
        .toList();

    WorkspaceRect? parsedRestore;
    final dynamic rawRestore = map['restoreRect'];
    if (rawRestore is Map<String, dynamic>) {
      parsedRestore = WorkspaceRect(
        x: (rawRestore['x'] as num).toDouble(),
        y: (rawRestore['y'] as num).toDouble(),
        width: (rawRestore['width'] as num).toDouble(),
        height: (rawRestore['height'] as num).toDouble(),
      );
    }

    final String rawSnapZone = map['snapZone'] as String? ?? SnapZone.none.name;
    final SnapZone parsedSnap = SnapZone.values.firstWhere(
      (SnapZone z) => z.name == rawSnapZone,
      orElse: () => SnapZone.none,
    );

    return WindowState(
      id: map['id'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      tabs: parsedTabs,
      activeTabIndex: map['activeTabIndex'] as int? ?? 0,
      isPinnedOnTop: map['isPinnedOnTop'] as bool? ?? false,
      isMinimized: map['isMinimized'] as bool? ?? false,
      isMaximized: map['isMaximized'] as bool? ?? false,
      snapZone: parsedSnap,
      restoreRect: parsedRestore,
      createdAt: map['createdAt'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WindowState &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.activeTabIndex == activeTabIndex &&
        other.isPinnedOnTop == isPinnedOnTop &&
        other.isMinimized == isMinimized &&
        other.isMaximized == isMaximized &&
        other.snapZone == snapZone &&
        other.restoreRect == restoreRect &&
        other.createdAt == createdAt &&
        _listEquals(other.tabs, tabs);
  }

  static bool _listEquals(List<WorkspaceTab> a, List<WorkspaceTab> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        width,
        height,
        activeTabIndex,
        isPinnedOnTop,
        isMinimized,
        isMaximized,
        snapZone,
        restoreRect,
        createdAt,
      );

  @override
  String toString() =>
      'WindowState(id: $id, rect: $rect, tabs: ${tabs.length}, active: $activeTabIndex)';
}