import 'package:flutter/material.dart';

/// Базовая темная тема оформления многооконного рабочего пространства.
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
