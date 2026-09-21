import 'package:flutter/material.dart';
import 'workspace_theme_data.dart';

/// Виджет-провайдер темы оформления [WorkspaceThemeData] в визуальном дереве.
class WorkspaceTheme extends InheritedWidget {
  /// Текущий набор дизайн-токенов.
  final WorkspaceThemeData data;

  /// Создает экземпляр [WorkspaceTheme].
  const WorkspaceTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Возвращает ближайший [WorkspaceThemeData] из дерева виджетов.
  static WorkspaceThemeData of(BuildContext context) {
    final WorkspaceTheme? inherited =
        context.dependOnInheritedWidgetOfExactType<WorkspaceTheme>();
    if (inherited != null) {
      return inherited.data;
    }
    final WorkspaceThemeData? extensionTheme =
        Theme.of(context).extension<WorkspaceThemeData>();
    if (extensionTheme != null) {
      return extensionTheme;
    }
    return const WorkspaceThemeData.dark();
  }

  /// Возвращает [WorkspaceThemeData] либо `null`, если тема не зарегистрирована.
  static WorkspaceThemeData? maybeOf(BuildContext context) {
    final WorkspaceTheme? inherited =
        context.dependOnInheritedWidgetOfExactType<WorkspaceTheme>();
    if (inherited != null) {
      return inherited.data;
    }
    return Theme.of(context).extension<WorkspaceThemeData>();
  }

  @override
  bool updateShouldNotify(WorkspaceTheme oldWidget) => data != oldWidget.data;
}