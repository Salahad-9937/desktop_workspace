import 'geometry_types.dart';

/// Описание параметров непрерывного общего шва между состыкованными окнами.
class SharedSeam {
  /// Является ли шов вертикальным (разделяет окна по горизонтали).
  final bool isVertical;

  /// Физическая координата шва на холсте (X для вертикального, Y для горизонтального).
  final double position;

  /// Начальная координата сегмента перекрытия.
  final double start;

  /// Конечная координата сегмента перекрытия.
  final double end;

  /// Идентификатор ведущего окна для расчета смещения.
  final String primaryWindowId;

  /// Идентификатор первого смежного ведомого окна.
  final String secondaryWindowId;

  /// Список идентификаторов всех окон, прилегающих к данному непрерывному шву.
  final List<String> participantWindowIds;

  /// Направление изменения габаритов для ведущего окна.
  final ResizeDirection direction;

  /// Создает неизменяемый экземпляр [SharedSeam].
  const SharedSeam({
    required this.isVertical,
    required this.position,
    required this.start,
    required this.end,
    required this.primaryWindowId,
    required this.secondaryWindowId,
    this.participantWindowIds = const <String>[],
    required this.direction,
  });
}

/// Точка перекрестного пересечения вертикального и горизонтального общих швов (4-Way Cross).
class SeamIntersection {
  /// Физическая координата X центра перекрестка.
  final double x;

  /// Физическая координата Y центра перекрестка.
  final double y;

  /// Вертикальный шов, проходящий через перекресток.
  final SharedSeam verticalSeam;

  /// Горизонтальный шов, проходящий через перекресток.
  final SharedSeam horizontalSeam;

  /// Создает неизменяемый экземпляр [SeamIntersection].
  const SeamIntersection({
    required this.x,
    required this.y,
    required this.verticalSeam,
    required this.horizontalSeam,
  });
}