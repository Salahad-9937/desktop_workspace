/// Целевая зона тайлинга при приближении к границам экрана.
enum SnapZone {
  /// Тайлинг не активен (свободный плавающий режим).
  none,

  /// Развертывание на всю полезную рабочую область холста.
  maximize,

  /// Левая вертикальная половина экрана.
  leftHalf,

  /// Правая вертикальная половина экрана.
  rightHalf,

  /// Верхняя левая четверть экрана.
  topLeft,

  /// Верхняя правая четверть экрана.
  topRight,

  /// Нижняя левая четверть экрана.
  bottomLeft,

  /// Нижняя правая четверть экрана.
  bottomRight,
}

/// Расширение удобных предикатов для [SnapZone].
extension SnapZoneExtension on SnapZone {
  /// Проверяет, является ли зона полноэкранным развертыванием.
  bool get isMaximize => this == SnapZone.maximize;

  /// Проверяет, является ли зона половинным разделением экрана.
  bool get isHalf => this == SnapZone.leftHalf || this == SnapZone.rightHalf;

  /// Проверяет, является ли зона четвертью экрана.
  bool get isQuarter =>
      this == SnapZone.topLeft ||
      this == SnapZone.topRight ||
      this == SnapZone.bottomLeft ||
      this == SnapZone.bottomRight;

  /// Проверяет отсутствие прилипания.
  bool get isNone => this == SnapZone.none;
}

/// Вектор сенсорной границы изменения габаритов окна.
enum ResizeDirection {
  /// Изменение размера не происходит.
  none,

  /// Северная грань (верх).
  north,

  /// Южная грань (низ).
  south,

  /// Восточная грань (право).
  east,

  /// Западная грань (лево).
  west,

  /// Северо-западный угол.
  northWest,

  /// Северо-восточный угол.
  northEast,

  /// Юго-западный угол.
  southWest,

  /// Юго-восточный угол.
  southEast,
}

/// Расширение свойств направления изменения габаритов [ResizeDirection].
extension ResizeDirectionExtension on ResizeDirection {
  /// Влияет ли жест на координату левой границы (X).
  bool get affectsLeft =>
      this == ResizeDirection.west ||
      this == ResizeDirection.northWest ||
      this == ResizeDirection.southWest;

  /// Влияет ли жест на координату правой границы (Width).
  bool get affectsRight =>
      this == ResizeDirection.east ||
      this == ResizeDirection.northEast ||
      this == ResizeDirection.southEast;

  /// Влияет ли жест на координату верхней границы (Y).
  bool get affectsTop =>
      this == ResizeDirection.north ||
      this == ResizeDirection.northWest ||
      this == ResizeDirection.northEast;

  /// Влияет ли жест на координату нижней границы (Height).
  bool get affectsBottom =>
      this == ResizeDirection.south ||
      this == ResizeDirection.southWest ||
      this == ResizeDirection.southEast;

  /// Является ли направление строго горизонтальным.
  bool get isHorizontal =>
      this == ResizeDirection.east || this == ResizeDirection.west;

  /// Является ли направление строго вертикальным.
  bool get isVertical =>
      this == ResizeDirection.north || this == ResizeDirection.south;

  /// Является ли направление диагональным.
  bool get isDiagonal =>
      this == ResizeDirection.northWest ||
      this == ResizeDirection.northEast ||
      this == ResizeDirection.southWest ||
      this == ResizeDirection.southEast;
}

/// Прямоугольная двумерная область в евклидовой плоскости координат холста.
class WorkspaceRect {
  /// Координата X левой границы.
  final double x;

  /// Координата Y верхней границы.
  final double y;

  /// Ширина прямоугольника.
  final double width;

  /// Высота прямоугольника.
  final double height;

  /// Создает неизменяемый экземпляр [WorkspaceRect].
  const WorkspaceRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  })  : assert(width >= 0.0, 'Ширина не может быть отрицательной'),
        assert(height >= 0.0, 'Высота не может быть отрицательной');

  /// Создает [WorkspaceRect] по координатам границ.
  factory WorkspaceRect.fromLTRB(
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return WorkspaceRect(
      x: left,
      y: top,
      width: (right - left) >= 0.0 ? right - left : 0.0,
      height: (bottom - top) >= 0.0 ? bottom - top : 0.0,
    );
  }

  /// Создает [WorkspaceRect] по левому верхнему углу и линейным размерам.
  factory WorkspaceRect.fromLTWH(
    double left,
    double top,
    double width,
    double height,
  ) {
    return WorkspaceRect(
      x: left,
      y: top,
      width: width >= 0.0 ? width : 0.0,
      height: height >= 0.0 ? height : 0.0,
    );
  }

  /// Левая граница.
  double get left => x;

  /// Верхняя граница.
  double get top => y;

  /// Правая граница.
  double get right => x + width;

  /// Нижняя граница.
  double get bottom => y + height;

  /// Проверяет попадание точки с координатами ([px], [py]) внутрь области.
  bool containsPoint(double px, double py) {
    return px >= left && px <= right && py >= top && py <= bottom;
  }

  /// Проверяет факт геометрического пересечения с другим прямоугольником.
  bool intersectsWith(WorkspaceRect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  /// Создает копию объекта с заменой параметров.
  WorkspaceRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return WorkspaceRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkspaceRect &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'WorkspaceRect(x: $x, y: $y, width: $width, height: $height)';
}