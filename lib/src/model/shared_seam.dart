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

  /// Идентификатор ведомого смежного окна.
  final String secondaryWindowId;

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
    required this.direction,
  });
}