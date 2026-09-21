import '../../model/window_state.dart';

/// Структурированный снимок состояния рабочего пространства для долговременного хранения.
class WorkspaceSnapshot {
  /// Версия схемы сериализации данных.
  final int schemaVersion;

  /// Временная метка создания снимка в миллисекундах.
  final int timestamp;

  /// Список сохраненных оконных контейнеров.
  final List<WindowState> windows;

  /// Идентификатор сфокусированного окна.
  final String? focusedWindowId;

  /// Идентификатор окна в сольном режиме.
  final String? soloWindowId;

  /// Физическая ширина видового экрана на момент сохранения.
  final double canvasWidth;

  /// Физическая высота видового экрана на момент сохранения.
  final double canvasHeight;

  /// Создает неизменяемый экземпляр [WorkspaceSnapshot].
  const WorkspaceSnapshot({
    this.schemaVersion = 1,
    required this.timestamp,
    required this.windows,
    this.focusedWindowId,
    this.soloWindowId,
    this.canvasWidth = 0.0,
    this.canvasHeight = 0.0,
  });

  /// Сериализует снимок в карту данных.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'timestamp': timestamp,
      'windows': windows
          .map((WindowState w) => w.toMap())
          .toList(growable: false),
      'focusedWindowId': focusedWindowId,
      'soloWindowId': soloWindowId,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    };
  }

  /// Восстанавливает снимок из карты данных с безопасной деградацией.
  factory WorkspaceSnapshot.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawWindows =
        map['windows'] as List<dynamic>? ?? <dynamic>[];
    final List<WindowState> parsedWindows = <WindowState>[];

    for (final dynamic item in rawWindows) {
      if (item is Map<String, dynamic>) {
        try {
          parsedWindows.add(WindowState.fromMap(item));
        } catch (_) {
          // Пропуск поврежденных или устаревших записей
        }
      }
    }

    return WorkspaceSnapshot(
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      windows: parsedWindows,
      focusedWindowId: map['focusedWindowId'] as String?,
      soloWindowId: map['soloWindowId'] as String?,
      canvasWidth: (map['canvasWidth'] as num?)?.toDouble() ?? 0.0,
      canvasHeight: (map['canvasHeight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}