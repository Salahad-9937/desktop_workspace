import 'package:flutter/material.dart';
import '../../config/workspace_config.dart';

/// Иммутабельная модель вкладки окна рабочего пространства.
@immutable
class WorkspaceTab {
  /// Уникальный строковый идентификатор типа или экземпляра вкладки.
  final String id;

  /// Отображаемый заголовок вкладки.
  final String title;

  /// Иконка для отображения во вкладке и панели задач.
  final IconData? icon;

  /// Акцентный цвет модальности вкладки.
  final Color? accentColor;

  /// Флаг сохранения состояния дерева виджетов при неактивном статусе вкладки.
  final bool keepAlive;

  /// Индивидуальные геометрические ограничения окна при выборе данной вкладки.
  final WindowConstraints? constraints;

  /// Произвольные сериализуемые пользовательские данные состояния вкладки.
  final Map<String, Object?>? payload;

  /// Создает экземпляр [WorkspaceTab].
  const WorkspaceTab({
    required this.id,
    required this.title,
    this.icon,
    this.accentColor,
    this.keepAlive = true,
    this.constraints,
    this.payload,
  });

  /// Создает копию вкладки с обновленными параметрами.
  WorkspaceTab copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? accentColor,
    bool? keepAlive,
    WindowConstraints? Function()? constraints,
    Map<String, Object?>? payload,
  }) {
    return WorkspaceTab(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      keepAlive: keepAlive ?? this.keepAlive,
      constraints: constraints != null ? constraints() : this.constraints,
      payload: payload ?? this.payload,
    );
  }

  /// Сериализует вкладку в словарь JSON.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'keepAlive': keepAlive,
        if (icon != null) 'iconCodePoint': icon!.codePoint,
        if (icon != null && icon!.fontFamily != null)
          'iconFontFamily': icon!.fontFamily,
        if (accentColor != null) 'accentColor': accentColor!.toARGB32(),
        if (constraints != null) 'constraints': constraints!.toJson(),
        if (payload != null) 'payload': payload,
      };

  /// Восстанавливает вкладку из словаря JSON.
  factory WorkspaceTab.fromJson(Map<String, Object?> json) {
    final int? codePoint = (json['iconCodePoint'] as num?)?.toInt();
    final String? fontFamily = json['iconFontFamily'] as String?;
    final int? colorValue = (json['accentColor'] as num?)?.toInt();

    final Object? rawConstraints = json['constraints'];
    WindowConstraints? constraints;
    if (rawConstraints is Map<String, Object?>) {
      constraints = WindowConstraints.fromJson(rawConstraints);
    } else if (rawConstraints is Map) {
      constraints =
          WindowConstraints.fromJson(Map<String, Object?>.from(rawConstraints));
    }

    final Object? rawPayload = json['payload'];
    final Map<String, Object?>? parsedPayload =
        rawPayload is Map ? Map<String, Object?>.from(rawPayload) : null;

    return WorkspaceTab(
      id: json['id'] as String? ?? 'tab_unknown',
      title: json['title'] as String? ?? '',
      keepAlive: json['keepAlive'] as bool? ?? true,
      // ignore: non_const_argument_for_const_parameter
      icon: codePoint != null
          // ignore: non_const_argument_for_const_parameter
          ? IconData(codePoint, fontFamily: fontFamily)
          : null,
      accentColor: colorValue != null ? Color(colorValue) : null,
      constraints: constraints,
      payload: parsedPayload,
    );
  }
}