import 'package:flutter/material.dart';

/// Расширение темы Flutter для многооконного рабочего пространства.
@immutable
class WorkspaceThemeData extends ThemeExtension<WorkspaceThemeData> {
  /// Фоновый цвет рабочего стола.
  final Color spaceBackground;

  /// Фоновый цвет панелей и окон.
  final Color panelBackground;

  /// Цвет границ окон и разделителей.
  final Color surfaceBorder;

  /// Основной акцентный цвет активных элементов и фокуса.
  final Color accentColor;

  /// Вторичный акцентный цвет.
  final Color secondaryAccent;

  /// Цвет предупреждающих индикаторов.
  final Color warningColor;

  /// Цвет успешных состояний и онлайна.
  final Color successColor;

  /// Цвет ошибок и аварийных состояний.
  final Color errorColor;

  /// Цвет приглушенного текста и неактивных элементов.
  final Color textMuted;

  /// Фоновый цвет панели задач.
  final Color taskbarBackground;

  /// Фоновый цвет активного заголовка окна.
  final Color titleBarActiveBackground;

  /// Фоновый цвет неактивного заголовка окна.
  final Color titleBarInactiveBackground;

  /// Фоновый цвет всплывающих карточек и меню.
  final Color cardBackground;

  /// Радиус скругления окон.
  final double windowBorderRadius;

  /// Создает экземпляр [WorkspaceThemeData].
  const WorkspaceThemeData({
    required this.spaceBackground,
    required this.panelBackground,
    required this.surfaceBorder,
    required this.accentColor,
    required this.secondaryAccent,
    required this.warningColor,
    required this.successColor,
    required this.errorColor,
    required this.textMuted,
    required this.taskbarBackground,
    required this.titleBarActiveBackground,
    required this.titleBarInactiveBackground,
    required this.cardBackground,
    this.windowBorderRadius = 8.0,
  });

  /// Темная цветовая тема по умолчанию.
  const WorkspaceThemeData.dark({
    this.spaceBackground = const Color(0xFF0A0D14),
    this.panelBackground = const Color(0xFF121722),
    this.surfaceBorder = const Color(0xFF1E2836),
    this.accentColor = const Color(0xFF00E5FF),
    this.secondaryAccent = const Color(0xFFD500F9),
    this.warningColor = const Color(0xFFFFAB00),
    this.successColor = const Color(0xFF00E676),
    this.errorColor = const Color(0xFFFF1744),
    this.textMuted = const Color(0xFF78909C),
    this.taskbarBackground = const Color(0xFF0A0E18),
    this.titleBarActiveBackground = const Color(0xFF121B2B),
    this.titleBarInactiveBackground = const Color(0xFF0C121D),
    this.cardBackground = const Color(0xFF0F1626),
    this.windowBorderRadius = 8.0,
  });

  /// Светлая цветовая тема рабочего пространства.
  const WorkspaceThemeData.light({
    this.spaceBackground = const Color(0xFFF0F4F8),
    this.panelBackground = const Color(0xFFFFFFFF),
    this.surfaceBorder = const Color(0xFFCFD8DC),
    this.accentColor = const Color(0xFF0091EA),
    this.secondaryAccent = const Color(0xFFAA00FF),
    this.warningColor = const Color(0xFFFF8F00),
    this.successColor = const Color(0xFF00C853),
    this.errorColor = const Color(0xFFD50000),
    this.textMuted = const Color(0xFF546E7A),
    this.taskbarBackground = const Color(0xFFECEFF1),
    this.titleBarActiveBackground = const Color(0xFFE1F5FE),
    this.titleBarInactiveBackground = const Color(0xFFF5F7FA),
    this.cardBackground = const Color(0xFFFFFFFF),
    this.windowBorderRadius = 8.0,
  });

  @override
  ThemeExtension<WorkspaceThemeData> copyWith({
    Color? spaceBackground,
    Color? panelBackground,
    Color? surfaceBorder,
    Color? accentColor,
    Color? secondaryAccent,
    Color? warningColor,
    Color? successColor,
    Color? errorColor,
    Color? textMuted,
    Color? taskbarBackground,
    Color? titleBarActiveBackground,
    Color? titleBarInactiveBackground,
    Color? cardBackground,
    double? windowBorderRadius,
  }) {
    return WorkspaceThemeData(
      spaceBackground: spaceBackground ?? this.spaceBackground,
      panelBackground: panelBackground ?? this.panelBackground,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      accentColor: accentColor ?? this.accentColor,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      warningColor: warningColor ?? this.warningColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      textMuted: textMuted ?? this.textMuted,
      taskbarBackground: taskbarBackground ?? this.taskbarBackground,
      titleBarActiveBackground:
          titleBarActiveBackground ?? this.titleBarActiveBackground,
      titleBarInactiveBackground:
          titleBarInactiveBackground ?? this.titleBarInactiveBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      windowBorderRadius: windowBorderRadius ?? this.windowBorderRadius,
    );
  }

  @override
  ThemeExtension<WorkspaceThemeData> lerp(
    covariant ThemeExtension<WorkspaceThemeData>? other,
    double t,
  ) {
    if (other is! WorkspaceThemeData) {
      return this;
    }
    return WorkspaceThemeData(
      spaceBackground:
          Color.lerp(spaceBackground, other.spaceBackground, t) ?? spaceBackground,
      panelBackground:
          Color.lerp(panelBackground, other.panelBackground, t) ?? panelBackground,
      surfaceBorder:
          Color.lerp(surfaceBorder, other.surfaceBorder, t) ?? surfaceBorder,
      accentColor: Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
      secondaryAccent:
          Color.lerp(secondaryAccent, other.secondaryAccent, t) ?? secondaryAccent,
      warningColor:
          Color.lerp(warningColor, other.warningColor, t) ?? warningColor,
      successColor:
          Color.lerp(successColor, other.successColor, t) ?? successColor,
      errorColor: Color.lerp(errorColor, other.errorColor, t) ?? errorColor,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      taskbarBackground:
          Color.lerp(taskbarBackground, other.taskbarBackground, t) ??
              taskbarBackground,
      titleBarActiveBackground: Color.lerp(
            titleBarActiveBackground,
            other.titleBarActiveBackground,
            t,
          ) ??
          titleBarActiveBackground,
      titleBarInactiveBackground: Color.lerp(
            titleBarInactiveBackground,
            other.titleBarInactiveBackground,
            t,
          ) ??
          titleBarInactiveBackground,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      windowBorderRadius:
          lerpDouble(windowBorderRadius, other.windowBorderRadius, t) ??
              windowBorderRadius,
    );
  }

  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Утилита доступа к стилям рабочего пространства с поддержкой обратной совместимости.
abstract class WorkspaceTheme {
  /// Получает действующую [WorkspaceThemeData] из текущего [BuildContext].
  static WorkspaceThemeData of(BuildContext context) {
    final WorkspaceThemeData? ext =
        Theme.of(context).extension<WorkspaceThemeData>();
    if (ext != null) {
      return ext;
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const WorkspaceThemeData.dark()
        : const WorkspaceThemeData.light();
  }
}

/// Базовая статическая темная палитра для обратной совместимости.
abstract class DesktopTheme {
  /// Фоновый цвет рабочего стола.
  static const Color spaceBackground = Color(0xFF0A0D14);

  /// Фоновый цвет панелей и окон.
  static const Color panelBackground = Color(0xFF121722);

  /// Цвет границ окон и разделителей.
  static const Color surfaceBorder = Color(0xFF1E2836);

  /// Основной акцентный цвет активных элементов и фокуса.
  static const Color accentColor = Color(0xFF00E5FF);

  /// Вторичный акцентный цвет.
  static const Color secondaryAccent = Color(0xFFD500F9);

  /// Цвет предупреждающих индикаторов.
  static const Color warningColor = Color(0xFFFFAB00);

  /// Цвет успешных состояний и онлайна.
  static const Color successColor = Color(0xFF00E676);

  /// Цвет ошибок и аварийных состояний.
  static const Color errorColor = Color(0xFFFF1744);

  /// Цвет приглушенного текста и неактивных элементов.
  static const Color textMuted = Color(0xFF78909C);
}