import 'dart:math' as math;

/// Конфигурация размерных ограничений оконного фрейма.
class WindowConstraints {
  /// Минимально допустимая ширина окна.
  final double minWidth;

  /// Минимально допустимая высота окна.
  final double minHeight;

  /// Максимально допустимая ширина окна.
  final double maxWidth;

  /// Максимально допустимая высота окна.
  final double maxHeight;

  /// Создает неизменяемый экземпляр [WindowConstraints].
  const WindowConstraints({
    this.minWidth = 260.0,
    this.minHeight = 180.0,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : assert(minWidth >= 0.0, 'minWidth не может быть отрицательным'),
        assert(minHeight >= 0.0, 'minHeight не может быть отрицательным'),
        assert(
          maxWidth >= minWidth,
          'maxWidth не может быть меньше minWidth',
        ),
        assert(
          maxHeight >= minHeight,
          'maxHeight не может быть меньше minHeight',
        );

  /// Ограничивает переданную ширину [width] допустимым диапазоном.
  double clampWidth(double width) {
    return width.clamp(minWidth, maxWidth);
  }

  /// Ограничивает переданную высоту [height] допустимым диапазоном.
  double clampHeight(double height) {
    return height.clamp(minHeight, maxHeight);
  }

  /// Выполняет иерархическое разрешение ограничений с приоритетом более строгих параметров.
  WindowConstraints resolveWith(WindowConstraints? overrideConstraints) {
    if (overrideConstraints == null) {
      return this;
    }
    final double effectiveMinWidth =
        math.max(minWidth, overrideConstraints.minWidth);
    final double effectiveMinHeight =
        math.max(minHeight, overrideConstraints.minHeight);
    final double effectiveMaxWidth =
        math.min(maxWidth, overrideConstraints.maxWidth);
    final double effectiveMaxHeight =
        math.min(maxHeight, overrideConstraints.maxHeight);

    return WindowConstraints(
      minWidth: effectiveMinWidth,
      minHeight: effectiveMinHeight,
      maxWidth: math.max(effectiveMinWidth, effectiveMaxWidth),
      maxHeight: math.max(effectiveMinHeight, effectiveMaxHeight),
    );
  }

  /// Создает копию объекта с опциональной заменой полей.
  WindowConstraints copyWith({
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    return WindowConstraints(
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WindowConstraints &&
        other.minWidth == minWidth &&
        other.minHeight == minHeight &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode => Object.hash(minWidth, minHeight, maxWidth, maxHeight);

  @override
  String toString() {
    return 'WindowConstraints(minWidth: $minWidth, minHeight: $minHeight, maxWidth: $maxWidth, maxHeight: $maxHeight)';
  }
}