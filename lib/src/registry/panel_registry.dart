import 'package:flutter/material.dart';
import '../config/workspace_config.dart';
import '../state/models/window_state.dart';
import '../state/models/workspace_tab.dart';

/// Функция обратного вызова для построения содержимого вкладки окна.
typedef WorkspaceContentBuilder = Widget Function(
  BuildContext context,
  WindowState win,
  WorkspaceTab tab,
);

/// Метаданные определения типа панели для регистрации в системе.
@immutable
class PanelDefinition {
  /// Уникальный строковый идентификатор типа панели.
  final String id;

  /// Отображаемое название панели.
  final String title;

  /// Иконка для отображения в меню и вкладках.
  final IconData? icon;

  /// Акцентный цвет панели.
  final Color? accentColor;

  /// Флаг сохранения состояния содержимого вкладки в памяти.
  final bool keepAlive;

  /// Геометрические ограничения окна при выборе данной панели.
  final WindowConstraints? constraints;

  /// Пользовательский фабричный построитель содержимого панели.
  final WorkspaceContentBuilder? builder;

  /// Создает экземпляр [PanelDefinition].
  const PanelDefinition({
    required this.id,
    required this.title,
    this.icon,
    this.accentColor,
    this.keepAlive = true,
    this.constraints,
    this.builder,
  });

  /// Преобразует определение в модель вкладки [WorkspaceTab].
  WorkspaceTab toTab({Map<String, Object?>? payload}) {
    return WorkspaceTab(
      id: id,
      title: title,
      icon: icon,
      accentColor: accentColor,
      keepAlive: keepAlive,
      constraints: constraints,
      payload: payload,
    );
  }
}

/// Декларативный реестр доступных модулей и определений панелей.
class PanelRegistry {
  PanelRegistry._();

  /// Глобальный экземпляр реестра панелей по умолчанию.
  static final PanelRegistry instance = PanelRegistry._();

  final Map<String, PanelDefinition> _panels = <String, PanelDefinition>{};

  /// Регистрирует новое определение панели в системе.
  void register(PanelDefinition definition) {
    _panels[definition.id] = definition;
  }

  /// Регистрирует перечень определений панелей.
  void registerAll(Iterable<PanelDefinition> definitions) {
    for (final PanelDefinition def in definitions) {
      register(def);
    }
  }

  /// Удаляет определение панели по идентификатору.
  void unregister(String id) {
    _panels.remove(id);
  }

  /// Возвращает определение панели по [id].
  PanelDefinition? get(String id) => _panels[id];

  /// Возвращает билдер контента панели по [id], если зарегистрирован.
  WorkspaceContentBuilder? getBuilder(String id) => _panels[id]?.builder;

  /// Список всех зарегистрированных определений панелей.
  List<PanelDefinition> get definitions =>
      List<PanelDefinition>.unmodifiable(_panels.values);

  /// Преобразует все определения в список шаблонов [WorkspaceTab].
  List<WorkspaceTab> toTabs() =>
      _panels.values.map((PanelDefinition p) => p.toTab()).toList();

  /// Очищает реестр.
  void clear() => _panels.clear();
}