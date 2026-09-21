import 'dart:ui';
import 'package:flutter/material.dart';

/// Система дизайн-токенов оформления рабочего пространства на базе ThemeExtension.
class WorkspaceThemeData extends ThemeExtension<WorkspaceThemeData> {
  /// Фоновая поверхность координатного холста.
  final Color spaceBackground;

  /// Базовая подложка тела окна.
  final Color windowBackground;

  /// Фон полосы заголовка активного окна.
  final Color titlebarActive;

  /// Фон полосы заголовка фонового окна.
  final Color titlebarInactive;

  /// Поверхность док-панели быстрого доступа.
  final Color dockBackground;

  /// Полупрозрачная заливка контура предпросмотра тайлинга.
  final Color previewOverlay;

  /// Цвет рамки сфокусированного окна.
  final Color borderActive;

  /// Цвет рамки неактивного окна.
  final Color borderInactive;

  /// Разделитель общего шва состыкованных окон.
  final Color seamDivider;

  /// Основной акцентный маркер темы.
  final Color accentColor;

  /// Вторичный акцентный цвет.
  final Color secondaryAccent;

  /// Цвет индикации предупреждений.
  final Color warningColor;

  /// Пиктограмма и статус постоянного закрепления (Always on Top).
  final Color statusPinned;

  /// Цвет подсветки кнопки закрытия при наведении.
  final Color actionCloseHover;

  /// Основной контрастный цвет типографики.
  final Color textPrimary;

  /// Приглушенный цвет вспомогательного текста.
  final Color textMuted;

  /// Радиус скругления внешних углов оконного фрейма.
  final double windowRadius;

  /// Физическая высота полосы заголовка окна.
  final double titlebarHeight;

  /// Физическая высота док-панели.
  final double dockHeight;

  /// Толщина внешней рамки окна.
  final double borderWidth;

  /// Высота пространственной тени окна.
  final double shadowElevation;

  /// Высота тени сфокусированного окна.
  final double activeShadowElevation;

  /// Создает неизменяемый экземпляр дизайн-токенов [WorkspaceThemeData].
  const WorkspaceThemeData({
    required this.spaceBackground,
    required this.windowBackground,
    required this.titlebarActive,
    required this.titlebarInactive,
    required this.dockBackground,
    required this.previewOverlay,
    required this.borderActive,
    required this.borderInactive,
    required this.seamDivider,
    required this.accentColor,
    required this.secondaryAccent,
    required this.warningColor,
    required this.statusPinned,
    required this.actionCloseHover,
    required this.textPrimary,
    required this.textMuted,
    this.windowRadius = 8.0,
    this.titlebarHeight = 36.0,
    this.dockHeight = 48.0,
    this.borderWidth = 1.0,
    this.shadowElevation = 8.0,
    this.activeShadowElevation = 16.0,
  });

  /// Базовая темная тема оформления по умолчанию.
  const WorkspaceThemeData.dark({
    this.spaceBackground = const Color(0xFF121418),
    this.windowBackground = const Color(0xFF1E222B),
    this.titlebarActive = const Color(0xFF282D39),
    this.titlebarInactive = const Color(0xFF1A1D24),
    this.dockBackground = const Color(0xFF161920),
    this.previewOverlay = const Color(0x3300E5FF),
    this.borderActive = const Color(0xFF00E5FF),
    this.borderInactive = const Color(0xFF323846),
    this.seamDivider = const Color(0xFF00E5FF),
    this.accentColor = const Color(0xFF00E5FF),
    this.secondaryAccent = const Color(0xFF7C4DFF),
    this.warningColor = const Color(0xFFFFAB00),
    this.statusPinned = const Color(0xFFFFD600),
    this.actionCloseHover = const Color(0xFFFF5252),
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textMuted = const Color(0xFF8B949E),
    this.windowRadius = 8.0,
    this.titlebarHeight = 36.0,
    this.dockHeight = 48.0,
    this.borderWidth = 1.0,
    this.shadowElevation = 8.0,
    this.activeShadowElevation = 16.0,
  });

  /// Базовая светлая тема оформления.
  const WorkspaceThemeData.light({
    this.spaceBackground = const Color(0xFFF0F2F5),
    this.windowBackground = const Color(0xFFFFFFFF),
    this.titlebarActive = const Color(0xFFE4E7EB),
    this.titlebarInactive = const Color(0xFFF7F8FA),
    this.dockBackground = const Color(0xFFE8ECEF),
    this.previewOverlay = const Color(0x330066FF),
    this.borderActive = const Color(0xFF0066FF),
    this.borderInactive = const Color(0xFFD0D7DE),
    this.seamDivider = const Color(0xFF0066FF),
    this.accentColor = const Color(0xFF0066FF),
    this.secondaryAccent = const Color(0xFF6200EE),
    this.warningColor = const Color(0xFFE65100),
    this.statusPinned = const Color(0xFFF57F17),
    this.actionCloseHover = const Color(0xFFD32F2F),
    this.textPrimary = const Color(0xFF1F2328),
    this.textMuted = const Color(0xFF656D76),
    this.windowRadius = 8.0,
    this.titlebarHeight = 36.0,
    this.dockHeight = 48.0,
    this.borderWidth = 1.0,
    this.shadowElevation = 4.0,
    this.activeShadowElevation = 12.0,
  });

  @override
  WorkspaceThemeData copyWith({
    Color? spaceBackground,
    Color? windowBackground,
    Color? titlebarActive,
    Color? titlebarInactive,
    Color? dockBackground,
    Color? previewOverlay,
    Color? borderActive,
    Color? borderInactive,
    Color? seamDivider,
    Color? accentColor,
    Color? secondaryAccent,
    Color? warningColor,
    Color? statusPinned,
    Color? actionCloseHover,
    Color? textPrimary,
    Color? textMuted,
    double? windowRadius,
    double? titlebarHeight,
    double? dockHeight,
    double? borderWidth,
    double? shadowElevation,
    double? activeShadowElevation,
  }) {
    return WorkspaceThemeData(
      spaceBackground: spaceBackground ?? this.spaceBackground,
      windowBackground: windowBackground ?? this.windowBackground,
      titlebarActive: titlebarActive ?? this.titlebarActive,
      titlebarInactive: titlebarInactive ?? this.titlebarInactive,
      dockBackground: dockBackground ?? this.dockBackground,
      previewOverlay: previewOverlay ?? this.previewOverlay,
      borderActive: borderActive ?? this.borderActive,
      borderInactive: borderInactive ?? this.borderInactive,
      seamDivider: seamDivider ?? this.seamDivider,
      accentColor: accentColor ?? this.accentColor,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      warningColor: warningColor ?? this.warningColor,
      statusPinned: statusPinned ?? this.statusPinned,
      actionCloseHover: actionCloseHover ?? this.actionCloseHover,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      windowRadius: windowRadius ?? this.windowRadius,
      titlebarHeight: titlebarHeight ?? this.titlebarHeight,
      dockHeight: dockHeight ?? this.dockHeight,
      borderWidth: borderWidth ?? this.borderWidth,
      shadowElevation: shadowElevation ?? this.shadowElevation,
      activeShadowElevation:
          activeShadowElevation ?? this.activeShadowElevation,
    );
  }

  @override
  WorkspaceThemeData lerp(
    ThemeExtension<WorkspaceThemeData>? other,
    double t,
  ) {
    if (other is! WorkspaceThemeData) {
      return this;
    }
    return WorkspaceThemeData(
      spaceBackground:
          Color.lerp(spaceBackground, other.spaceBackground, t) ?? spaceBackground,
      windowBackground:
          Color.lerp(windowBackground, other.windowBackground, t) ?? windowBackground,
      titlebarActive:
          Color.lerp(titlebarActive, other.titlebarActive, t) ?? titlebarActive,
      titlebarInactive:
          Color.lerp(titlebarInactive, other.titlebarInactive, t) ?? titlebarInactive,
      dockBackground:
          Color.lerp(dockBackground, other.dockBackground, t) ?? dockBackground,
      previewOverlay:
          Color.lerp(previewOverlay, other.previewOverlay, t) ?? previewOverlay,
      borderActive:
          Color.lerp(borderActive, other.borderActive, t) ?? borderActive,
      borderInactive:
          Color.lerp(borderInactive, other.borderInactive, t) ?? borderInactive,
      seamDivider:
          Color.lerp(seamDivider, other.seamDivider, t) ?? seamDivider,
      accentColor:
          Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
      secondaryAccent:
          Color.lerp(secondaryAccent, other.secondaryAccent, t) ?? secondaryAccent,
      warningColor:
          Color.lerp(warningColor, other.warningColor, t) ?? warningColor,
      statusPinned:
          Color.lerp(statusPinned, other.statusPinned, t) ?? statusPinned,
      actionCloseHover:
          Color.lerp(actionCloseHover, other.actionCloseHover, t) ?? actionCloseHover,
      textPrimary:
          Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted:
          Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      windowRadius:
          lerpDouble(windowRadius, other.windowRadius, t) ?? windowRadius,
      titlebarHeight:
          lerpDouble(titlebarHeight, other.titlebarHeight, t) ?? titlebarHeight,
      dockHeight:
          lerpDouble(dockHeight, other.dockHeight, t) ?? dockHeight,
      borderWidth:
          lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      shadowElevation:
          lerpDouble(shadowElevation, other.shadowElevation, t) ?? shadowElevation,
      activeShadowElevation:
          lerpDouble(activeShadowElevation, other.activeShadowElevation, t) ??
              activeShadowElevation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkspaceThemeData &&
        other.spaceBackground == spaceBackground &&
        other.windowBackground == windowBackground &&
        other.titlebarActive == titlebarActive &&
        other.titlebarInactive == titlebarInactive &&
        other.dockBackground == dockBackground &&
        other.previewOverlay == previewOverlay &&
        other.borderActive == borderActive &&
        other.borderInactive == borderInactive &&
        other.seamDivider == seamDivider &&
        other.accentColor == accentColor &&
        other.secondaryAccent == secondaryAccent &&
        other.warningColor == warningColor &&
        other.statusPinned == statusPinned &&
        other.actionCloseHover == actionCloseHover &&
        other.textPrimary == textPrimary &&
        other.textMuted == textMuted &&
        other.windowRadius == windowRadius &&
        other.titlebarHeight == titlebarHeight &&
        other.dockHeight == dockHeight &&
        other.borderWidth == borderWidth &&
        other.shadowElevation == shadowElevation &&
        other.activeShadowElevation == activeShadowElevation;
  }

  @override
  int get hashCode => Object.hashAll(<Object>[
        spaceBackground,
        windowBackground,
        titlebarActive,
        titlebarInactive,
        dockBackground,
        previewOverlay,
        borderActive,
        borderInactive,
        seamDivider,
        accentColor,
        secondaryAccent,
        warningColor,
        statusPinned,
        actionCloseHover,
        textPrimary,
        textMuted,
        windowRadius,
        titlebarHeight,
        dockHeight,
        borderWidth,
      ]);
}