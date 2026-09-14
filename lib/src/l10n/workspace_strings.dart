import 'package:flutter/widgets.dart';

/// Контракт локализованных строковых ресурсов рабочего пространства.
abstract class WorkspaceStrings {
  /// Текст кнопки системного лаунчера в таскбаре.
  String get menu;

  /// Пресет сетки 2x2.
  String get preset2x2;

  /// Пресет вертикального разделения экрана.
  String get presetSplit;

  /// Пункт сохранения раскладки в буфер.
  String get exportLayout;

  /// Пункт восстановления раскладки из буфера.
  String get importLayout;

  /// Пункт закрытия всех окон.
  String get clearAllWindows;

  /// Уведомление об успешном копировании раскладки.
  String get layoutCopiedSnackbar;

  /// Уведомление об успешном восстановлении раскладки.
  String get layoutRestoredSnackbar;

  /// Ошибка чтения конфигурации раскладки.
  String get layoutRestoreFailedSnackbar;

  /// Заголовок попапа системного времени.
  String get systemTimeTitle;

  /// Текст деталей системного времени.
  String systemTimeDetail(String dateStr);

  /// Подсказка кнопки прикрепления окна.
  String get pinTooltip;

  /// Подсказка кнопки открепления окна.
  String get unpinTooltip;

  /// Подсказка сворачивания окна.
  String get minimizeTooltip;

  /// Подсказка развертывания окна.
  String get maximizeTooltip;

  /// Подсказка восстановления окна.
  String get restoreTooltip;

  /// Подсказка закрытия окна.
  String get closeWindowTooltip;

  /// Подсказка меню быстрого тайлинга окна.
  String get quickTileTooltip;

  /// Подсказка добавления вкладки.
  String get addTabTooltip;

  /// Контекстное меню вкладки: закрыть.
  String get tabClose;

  /// Контекстное меню вкладки: дублировать.
  String get tabDuplicate;

  /// Контекстное меню вкладки: открепить в отдельное окно.
  String get tabDetach;

  /// Контекстное меню вкладки: сменить модуль.
  String get tabChangeModule;

  /// Префикс копии вкладки.
  String tabCopySuffix(String title);

  /// Текст количества скрытых вкладок в превью таскбара.
  String moreTabs(int count);

  /// Название зоны тайлинга: весь экран.
  String get tileMaximize;

  /// Название зоны тайлинга: левая половина.
  String get tileLeftHalf;

  /// Название зоны тайлинга: правая половина.
  String get tileRightHalf;

  /// Название зоны тайлинга: верхняя левая четверть.
  String get tileTopLeft;

  /// Название зоны тайлинга: верхняя правая четверть.
  String get tileTopRight;

  /// Название зоны тайлинга: нижняя левая четверть.
  String get tileBottomLeft;

  /// Название зоны тайлинга: нижняя правая четверть.
  String get tileBottomRight;

  /// Заголовок окна по умолчанию.
  String defaultWindowTitle(int index);

  /// Заголовок вкладки по умолчанию.
  String defaultTabTitle(int index);
}

/// Реализация строковых ресурсов по умолчанию на русском языке.
class DefaultWorkspaceStrings implements WorkspaceStrings {
  /// Создает экземпляр [DefaultWorkspaceStrings].
  const DefaultWorkspaceStrings();

  @override
  String get menu => 'МЕНЮ';

  @override
  String get preset2x2 => 'Пресет: Сетка 2x2';

  @override
  String get presetSplit => 'Пресет: Разделенный экран';

  @override
  String get exportLayout => 'Сохранить раскладку (в буфер, JSON)';

  @override
  String get importLayout => 'Восстановить раскладку (из буфера)';

  @override
  String get clearAllWindows => 'Закрыть все окна';

  @override
  String get layoutCopiedSnackbar =>
      'Раскладка окон скопирована в буфер обмена (JSON)';

  @override
  String get layoutRestoredSnackbar =>
      'Раскладка успешно восстановлена из буфера обмена';

  @override
  String get layoutRestoreFailedSnackbar =>
      'Не удалось прочитать JSON-конфигурацию из буфера';

  @override
  String get systemTimeTitle => 'Системное время';

  @override
  String systemTimeDetail(String dateStr) =>
      'Текущая дата: $dateStr\nМногооконное рабочее пространство активно.';

  @override
  String get pinTooltip => 'Закрепить поверх всех';

  @override
  String get unpinTooltip => 'Открепить окно';

  @override
  String get minimizeTooltip => 'Свернуть в панель задач';

  @override
  String get maximizeTooltip => 'На весь экран';

  @override
  String get restoreTooltip => 'Восстановить';

  @override
  String get closeWindowTooltip => 'Закрыть окно';

  @override
  String get quickTileTooltip => 'Прикрепить к области экрана (Quick Tile)';

  @override
  String get addTabTooltip => 'Добавить вкладку';

  @override
  String get tabClose => 'Закрыть';

  @override
  String get tabDuplicate => 'Дублировать';

  @override
  String get tabDetach => 'Открепить в отдельное окно';

  @override
  String get tabChangeModule => 'Сменить модуль…';

  @override
  String tabCopySuffix(String title) => '$title (Копия)';

  @override
  String moreTabs(int count) => '+ ещё $count вкладок в окне';

  @override
  String get tileMaximize => 'ВЕСЬ ЭКРАН';

  @override
  String get tileLeftHalf => 'ЛЕВАЯ ПОЛОВИНА';

  @override
  String get tileRightHalf => 'ПРАВАЯ ПОЛОВИНА';

  @override
  String get tileTopLeft => 'ВЕРХНЯЯ 1/4';

  @override
  String get tileTopRight => 'ВЕРХНЯЯ 1/4';

  @override
  String get tileBottomLeft => 'НИЖНЯЯ 1/4';

  @override
  String get tileBottomRight => 'НИЖНЯЯ 1/4';

  @override
  String defaultWindowTitle(int index) => 'Окно $index';

  @override
  String defaultTabTitle(int index) => 'Вкладка $index';
}

/// Англоязычная реализация строковых ресурсов рабочего пространства.
class EnglishWorkspaceStrings implements WorkspaceStrings {
  /// Создает экземпляр [EnglishWorkspaceStrings].
  const EnglishWorkspaceStrings();

  @override
  String get menu => 'MENU';

  @override
  String get preset2x2 => 'Preset: 2x2 Grid';

  @override
  String get presetSplit => 'Preset: Split Screen';

  @override
  String get exportLayout => 'Export layout (to clipboard, JSON)';

  @override
  String get importLayout => 'Import layout (from clipboard)';

  @override
  String get clearAllWindows => 'Close all windows';

  @override
  String get layoutCopiedSnackbar => 'Window layout copied to clipboard (JSON)';

  @override
  String get layoutRestoredSnackbar =>
      'Window layout successfully restored from clipboard';

  @override
  String get layoutRestoreFailedSnackbar =>
      'Failed to parse JSON configuration from clipboard';

  @override
  String get systemTimeTitle => 'System Clock';

  @override
  String systemTimeDetail(String dateStr) =>
      'Current date: $dateStr\nMulti-window workspace active.';

  @override
  String get pinTooltip => 'Always on top';

  @override
  String get unpinTooltip => 'Unpin window';

  @override
  String get minimizeTooltip => 'Minimize to taskbar';

  @override
  String get maximizeTooltip => 'Maximize';

  @override
  String get restoreTooltip => 'Restore';

  @override
  String get closeWindowTooltip => 'Close window';

  @override
  String get quickTileTooltip => 'Snap window to region (Quick Tile)';

  @override
  String get addTabTooltip => 'Add tab';

  @override
  String get tabClose => 'Close';

  @override
  String get tabDuplicate => 'Duplicate';

  @override
  String get tabDetach => 'Detach to new window';

  @override
  String get tabChangeModule => 'Switch module…';

  @override
  String tabCopySuffix(String title) => '$title (Copy)';

  @override
  String moreTabs(int count) => '+ $count more tabs';

  @override
  String get tileMaximize => 'FULL SCREEN';

  @override
  String get tileLeftHalf => 'LEFT HALF';

  @override
  String get tileRightHalf => 'RIGHT HALF';

  @override
  String get tileTopLeft => 'TOP-LEFT 1/4';

  @override
  String get tileTopRight => 'TOP-RIGHT 1/4';

  @override
  String get tileBottomLeft => 'BOTTOM-LEFT 1/4';

  @override
  String get tileBottomRight => 'BOTTOM-RIGHT 1/4';

  @override
  String defaultWindowTitle(int index) => 'Window $index';

  @override
  String defaultTabTitle(int index) => 'Tab $index';
}

/// Виджет внедрения локализованных строковых ресурсов в дерево контекста.
class WorkspaceLocalizations extends InheritedWidget {
  /// Экземпляр строковых ресурсов.
  final WorkspaceStrings strings;

  /// Создает экземпляр [WorkspaceLocalizations].
  const WorkspaceLocalizations({
    super.key,
    required this.strings,
    required super.child,
  });

  /// Получает действующие строковые ресурсы из [BuildContext].
  static WorkspaceStrings of(BuildContext context) {
    final WorkspaceLocalizations? scope =
        context.dependOnInheritedWidgetOfExactType<WorkspaceLocalizations>();
    return scope?.strings ?? const DefaultWorkspaceStrings();
  }

  @override
  bool updateShouldNotify(covariant WorkspaceLocalizations oldWidget) =>
      strings != oldWidget.strings;
}