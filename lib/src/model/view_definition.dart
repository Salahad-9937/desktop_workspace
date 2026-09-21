import 'package:flutter/widgets.dart';

import '../config/window_constraints.dart';
import 'window_state.dart';
import 'workspace_tab.dart';

/// Стратегия инстанцирования представления на холсте.
enum ViewInstanceStrategy {
  /// В рабочем пространстве допускается строго один экземпляр панели.
  singleton,

  /// Допускается создание множественных независимых копий панели.
  multiInstance,
}

/// Статус доступности и отображения зарегистрированного представления.
enum ViewInstanceStatus {
  /// Контейнер открыт на холсте и находится в фокусе.
  active,

  /// Контейнер открыт на холсте под другими окнами.
  inactive,

  /// Контейнер свернут в панель быстрого доступа.
  minimized,

  /// Компонент отсутствует на холсте.
  closed,
}

/// Контракт функции-фабрики содержимого вкладки.
typedef WorkspaceContentBuilder = Widget Function(
  BuildContext context,
  WindowState window,
  WorkspaceTab tab,
);

/// Декларативное определение прикладной панели для каталога представлений.
class ViewDefinition {
  /// Уникальный строковый идентификатор типа панели.
  final String typeId;

  /// Отображаемое наименование по умолчанию.
  final String title;

  /// Базовая пиктограмма представления.
  final IconData? icon;

  /// Акцентный цвет представления.
  final Color? accentColor;

  /// Индивидуальные размерные требования к окну.
  final WindowConstraints? constraints;

  /// Директива удержания внутреннего состояния в памяти.
  final bool keepAlive;

  /// Стратегия инстанцирования экземпляров представления.
  final ViewInstanceStrategy strategy;

  /// Фабрика сборки визуального дерева компонента.
  final WorkspaceContentBuilder builder;

  /// Создает определение панели [ViewDefinition].
  const ViewDefinition({
    required this.typeId,
    required this.title,
    this.icon,
    this.accentColor,
    this.constraints,
    this.keepAlive = true,
    this.strategy = ViewInstanceStrategy.multiInstance,
    required this.builder,
  });

  /// Создает спецификацию вкладки [WorkspaceTab] на основе данного определения.
  WorkspaceTab toTab({
    String? instanceId,
    String? customTitle,
    Map<String, dynamic>? payload,
  }) {
    return WorkspaceTab(
      id: instanceId ?? '${typeId}_${DateTime.now().microsecondsSinceEpoch}',
      typeId: typeId,
      title: customTitle ?? title,
      icon: icon,
      accentColor: accentColor,
      keepAlive: keepAlive,
      constraints: constraints,
      payload: payload,
    );
  }
}