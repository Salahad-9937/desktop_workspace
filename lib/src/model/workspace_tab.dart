import 'package:flutter/widgets.dart';

import '../config/window_constraints.dart';

/// Метаданные вкладки, размещаемой внутри оконного контейнера.
class WorkspaceTab {
  /// Уникальный строковый идентификатор экземпляра вкладки.
  final String id;

  /// Идентификатор типа представления (сопоставляется с фабрикой контента).
  final String typeId;

  /// Отображаемый заголовок вкладки.
  final String title;

  /// Символическая пиктограмма вкладки.
  final IconData? icon;

  /// Акцентный цвет модальности вкладки.
  final Color? accentColor;

  /// Директива удержания внутреннего состояния представления в памяти.
  final bool keepAlive;

  /// Индивидуальные размерные требования вкладки.
  final WindowConstraints? constraints;

  /// Сериализуемый контейнер прикладных параметров вкладки.
  final Map<String, dynamic>? payload;

  /// Создает неизменяемый экземпляр [WorkspaceTab].
  const WorkspaceTab({
    required this.id,
    required this.typeId,
    required this.title,
    this.icon,
    this.accentColor,
    this.keepAlive = true,
    this.constraints,
    this.payload,
  });

  /// Создает копию метаданных с возможностью модификации полей.
  WorkspaceTab copyWith({
    String? id,
    String? typeId,
    String? title,
    IconData? icon,
    Color? accentColor,
    bool? keepAlive,
    WindowConstraints? constraints,
    Map<String, dynamic>? payload,
  }) {
    return WorkspaceTab(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      keepAlive: keepAlive ?? this.keepAlive,
      constraints: constraints ?? this.constraints,
      payload: payload ?? this.payload,
    );
  }

  /// Сериализует свойства вкладки в карту данных для долговременного сохранения.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'typeId': typeId,
      'title': title,
      'keepAlive': keepAlive,
      if (accentColor != null) 'accentColor': accentColor!.toARGB32(),
      if (constraints != null)
        'constraints': <String, dynamic>{
          'minWidth': constraints!.minWidth,
          'minHeight': constraints!.minHeight,
          'maxWidth': constraints!.maxWidth,
          'maxHeight': constraints!.maxHeight,
        },
      if (payload != null) 'payload': payload,
    };
  }

  /// Восстанавливает сущность вкладки из карты данных.
  factory WorkspaceTab.fromMap(
    Map<String, dynamic> map, {
    IconData? icon,
  }) {
    final dynamic rawColor = map['accentColor'];
    final dynamic rawConstraints = map['constraints'];

    WindowConstraints? parsedConstraints;
    if (rawConstraints is Map<String, dynamic>) {
      parsedConstraints = WindowConstraints(
        minWidth: (rawConstraints['minWidth'] as num?)?.toDouble() ?? 260.0,
        minHeight: (rawConstraints['minHeight'] as num?)?.toDouble() ?? 180.0,
        maxWidth:
            (rawConstraints['maxWidth'] as num?)?.toDouble() ?? double.infinity,
        maxHeight: (rawConstraints['maxHeight'] as num?)?.toDouble() ??
            double.infinity,
      );
    }

    return WorkspaceTab(
      id: map['id'] as String,
      typeId: map['typeId'] as String,
      title: map['title'] as String,
      icon: icon,
      accentColor: rawColor is int ? Color(rawColor) : null,
      keepAlive: map['keepAlive'] as bool? ?? true,
      constraints: parsedConstraints,
      payload: map['payload'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkspaceTab &&
        other.id == id &&
        other.typeId == typeId &&
        other.title == title &&
        other.icon == icon &&
        other.accentColor == accentColor &&
        other.keepAlive == keepAlive &&
        other.constraints == constraints;
  }

  @override
  int get hashCode => Object.hash(
        id,
        typeId,
        title,
        icon,
        accentColor,
        keepAlive,
        constraints,
      );

  @override
  String toString() => 'WorkspaceTab(id: $id, typeId: $typeId, title: $title)';
}