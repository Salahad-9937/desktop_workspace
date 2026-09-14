import 'package:flutter/material.dart';
import '../state/models/window_state.dart';
import '../state/models/workspace_tab.dart';

/// Функция обратного вызова для отрисовки содержимого вкладки окна.
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

  /// Создает экземпляр [PanelDefinition].
  const PanelDefinition({
    required this.id,
    required this.title,
    this.icon,
    this.accentColor,
  });

  /// Преобразует определение в модель вкладки [WorkspaceTab].
  WorkspaceTab toTab({Map<String, Object?>? payload}) {
    return WorkspaceTab(
      id: id,
      title: title,
      icon: icon,
      accentColor: accentColor,
      payload: payload,
    );
  }
}