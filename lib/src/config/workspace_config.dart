import 'package:flutter/foundation.dart';

/// Высота нижней панели задач (Taskbar) по умолчанию в логических пикселях.
const double kTaskbarHeight = 42.0;

/// Дистанция магнитного прилипания к границам экрана и соседним окнам по умолчанию (px).
const double kMagnetThreshold = 10.0;

/// Дистанция активации краевых зон быстрого тайлинга по умолчанию (px).
const double kEdgeSnapTriggerZone = 52.0;

/// Минимально допустимая ширина окна по умолчанию (px).
const double kMinWindowWidth = 320.0;

/// Минимально допустимая высота окна по умолчанию (px).
const double kMinWindowHeight = 180.0;

/// Максимально допустимый геометрический размер окна по умолчанию (px).
const double kMaxWindowExtent = 4000.0;

/// Ограничения геометрических размеров окна.
@immutable
class WindowConstraints {
  /// Минимальная ширина окна.
  final double minWidth;

  /// Минимальная высота окна.
  final double minHeight;

  /// Максимальная ширина окна.
  final double maxWidth;

  /// Максимальная высота окна.
  final double maxHeight;

  /// Создает экземпляр [WindowConstraints].
  const WindowConstraints({
    this.minWidth = kMinWindowWidth,
    this.minHeight = kMinWindowHeight,
    this.maxWidth = kMaxWindowExtent,
    this.maxHeight = kMaxWindowExtent,
  });

  /// Создает копию ограничений с обновлением параметров.
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

  /// Сериализует ограничения в JSON-словарь.
  Map<String, Object?> toJson() => <String, Object?>{
        'minWidth': minWidth,
        'minHeight': minHeight,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      };

  /// Восстанавливает ограничения из JSON-словаря.
  factory WindowConstraints.fromJson(Map<String, Object?> json) {
    return WindowConstraints(
      minWidth: (json['minWidth'] as num?)?.toDouble() ?? kMinWindowWidth,
      minHeight: (json['minHeight'] as num?)?.toDouble() ?? kMinWindowHeight,
      maxWidth: (json['maxWidth'] as num?)?.toDouble() ?? kMaxWindowExtent,
      maxHeight: (json['maxHeight'] as num?)?.toDouble() ?? kMaxWindowExtent,
    );
  }
}

/// Параметры конфигурации рабочего пространства.
@immutable
class WorkspaceConfig {
  /// Высота панели задач.
  final double taskbarHeight;

  /// Дистанция магнитного притягивания.
  final double magnetThreshold;

  /// Порог активации зон прилипания у краев экрана.
  final double edgeSnapTriggerZone;

  /// Геометрические ограничения окон по умолчанию.
  final WindowConstraints constraints;

  /// Создает экземпляр [WorkspaceConfig].
  const WorkspaceConfig({
    this.taskbarHeight = kTaskbarHeight,
    this.magnetThreshold = kMagnetThreshold,
    this.edgeSnapTriggerZone = kEdgeSnapTriggerZone,
    this.constraints = const WindowConstraints(),
  });
}