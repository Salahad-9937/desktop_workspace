import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../config/workspace_config.dart';
import 'geometry_types.dart';
import 'window_state.dart';

/// Иммутабельное агрегированное состояние многооконного рабочего пространства.
@immutable
class WorkspaceState {
  /// Список всех созданных окон рабочего стола.
  final List<WindowState> windows;

  /// Идентификатор окна, находящегося в активном фокусе ввода.
  final String? focusedWindowId;

  /// Текущий размер рабочей области экрана.
  final Size screenSize;

  /// Прямоугольник визуализации предварительного просмотра прилипания к граням экрана.
  final Rect? snapPreviewRect;

  /// Целевая зона прилипания при активном перемещении окна.
  final SnapZone pendingSnapZone;

  /// Параметры конфигурации рабочего пространства.
  final WorkspaceConfig config;

  /// Создает экземпляр [WorkspaceState].
  const WorkspaceState({
    required this.windows,
    required this.focusedWindowId,
    required this.screenSize,
    required this.snapPreviewRect,
    required this.pendingSnapZone,
    this.config = const WorkspaceConfig(),
  });

  /// Доступная высота рабочей области экрана за вычетом панели задач.
  double get availableHeight =>
      (screenSize.height - config.taskbarHeight).clamp(0.0, double.infinity);

  /// Окно, находящееся в текущем активном фокусе ввода.
  WindowState? get focusedWindow {
    if (focusedWindowId == null) {
      return null;
    }
    for (final WindowState win in windows) {
      if (win.id == focusedWindowId) {
        return win;
      }
    }
    return null;
  }

  /// Начальное пустое состояние рабочего пространства.
  static const WorkspaceState initial = WorkspaceState(
    windows: <WindowState>[],
    focusedWindowId: null,
    screenSize: Size(1280.0, 800.0),
    snapPreviewRect: null,
    pendingSnapZone: SnapZone.none,
    config: WorkspaceConfig(),
  );

  /// Создает копию состояния с обновлением переданных параметров.
  WorkspaceState copyWith({
    List<WindowState>? windows,
    String? Function()? focusedWindowId,
    Size? screenSize,
    Rect? Function()? snapPreviewRect,
    SnapZone? pendingSnapZone,
    WorkspaceConfig? config,
  }) {
    return WorkspaceState(
      windows: windows ?? this.windows,
      focusedWindowId:
          focusedWindowId != null ? focusedWindowId() : this.focusedWindowId,
      screenSize: screenSize ?? this.screenSize,
      snapPreviewRect:
          snapPreviewRect != null ? snapPreviewRect() : this.snapPreviewRect,
      pendingSnapZone: pendingSnapZone ?? this.pendingSnapZone,
      config: config ?? this.config,
    );
  }
}