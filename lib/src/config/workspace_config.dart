import 'window_constraints.dart';

/// Глобальная конфигурация рабочего пространства и параметров физики.
class WorkspaceConfig {
  /// Пороговый радиус захвата магнитного притяжения в пикселях.
  final double magnetThreshold;

  /// Ширина краевой триггерной зоны тайлинга в пикселях.
  final double edgeTilingThreshold;

  /// Допустимый зазор для объединения окон в общий непрерывный шов.
  final double seamEpsilon;

  /// Минимальная длина взаимного проекционного перекрытия для общего шва.
  final double minSeamOverlap;

  /// Минимальная длина взаимного перекрытия для межоконного притягивания.
  final double minEdgeOverlap;

  /// Гарантированная минимальная видимая ширина заголовка в границах холста.
  final double minVisibleHeaderWidth;

  /// Физическая высота интерактивной полосы заголовка окна.
  final double headerHeight;

  /// Физическая высота встроенной док-панели.
  final double dockHeight;

  /// Дистанция смещения указателя для перехода из сортировки в отрыв вкладки.
  final double tearOffThreshold;

  /// Базовые ограничения габаритов окон холста по умолчанию.
  final WindowConstraints defaultConstraints;

  /// Создает неизменяемый экземпляр [WorkspaceConfig].
  const WorkspaceConfig({
    this.magnetThreshold = 10.0,
    this.edgeTilingThreshold = 48.0,
    this.seamEpsilon = 6.0,
    this.minSeamOverlap = 24.0,
    this.minEdgeOverlap = 24.0,
    this.minVisibleHeaderWidth = 48.0,
    this.headerHeight = 36.0,
    this.dockHeight = 48.0,
    this.tearOffThreshold = 20.0,
    this.defaultConstraints = const WindowConstraints(),
  })  : assert(magnetThreshold >= 0.0, 'magnetThreshold >= 0.0'),
        assert(edgeTilingThreshold > 0.0, 'edgeTilingThreshold > 0.0'),
        assert(seamEpsilon >= 0.0, 'seamEpsilon >= 0.0'),
        assert(minSeamOverlap > 0.0, 'minSeamOverlap > 0.0'),
        assert(minEdgeOverlap > 0.0, 'minEdgeOverlap > 0.0'),
        assert(minVisibleHeaderWidth > 0.0, 'minVisibleHeaderWidth > 0.0'),
        assert(headerHeight > 0.0, 'headerHeight > 0.0'),
        assert(dockHeight >= 0.0, 'dockHeight >= 0.0'),
        assert(tearOffThreshold > 0.0, 'tearOffThreshold > 0.0');

  /// Создает копию конфигурации с переопределением выбранных свойств.
  WorkspaceConfig copyWith({
    double? magnetThreshold,
    double? edgeTilingThreshold,
    double? seamEpsilon,
    double? minSeamOverlap,
    double? minEdgeOverlap,
    double? minVisibleHeaderWidth,
    double? headerHeight,
    double? dockHeight,
    double? tearOffThreshold,
    WindowConstraints? defaultConstraints,
  }) {
    return WorkspaceConfig(
      magnetThreshold: magnetThreshold ?? this.magnetThreshold,
      edgeTilingThreshold: edgeTilingThreshold ?? this.edgeTilingThreshold,
      seamEpsilon: seamEpsilon ?? this.seamEpsilon,
      minSeamOverlap: minSeamOverlap ?? this.minSeamOverlap,
      minEdgeOverlap: minEdgeOverlap ?? this.minEdgeOverlap,
      minVisibleHeaderWidth:
          minVisibleHeaderWidth ?? this.minVisibleHeaderWidth,
      headerHeight: headerHeight ?? this.headerHeight,
      dockHeight: dockHeight ?? this.dockHeight,
      tearOffThreshold: tearOffThreshold ?? this.tearOffThreshold,
      defaultConstraints: defaultConstraints ?? this.defaultConstraints,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkspaceConfig &&
        other.magnetThreshold == magnetThreshold &&
        other.edgeTilingThreshold == edgeTilingThreshold &&
        other.seamEpsilon == seamEpsilon &&
        other.minSeamOverlap == minSeamOverlap &&
        other.minEdgeOverlap == minEdgeOverlap &&
        other.minVisibleHeaderWidth == minVisibleHeaderWidth &&
        other.headerHeight == headerHeight &&
        other.dockHeight == dockHeight &&
        other.tearOffThreshold == tearOffThreshold &&
        other.defaultConstraints == defaultConstraints;
  }

  @override
  int get hashCode => Object.hash(
        magnetThreshold,
        edgeTilingThreshold,
        seamEpsilon,
        minSeamOverlap,
        minEdgeOverlap,
        minVisibleHeaderWidth,
        headerHeight,
        dockHeight,
        tearOffThreshold,
        defaultConstraints,
      );
}