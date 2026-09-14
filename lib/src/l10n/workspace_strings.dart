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
  String get layoutCopiedSnackbar => 'Раскладка окон скопирована в буфер обмена (JSON)';

  @override
  String get layoutRestoredSnackbar => 'Раскладка успешно восстановлена из буфера обмена';

  @override
  String get layoutRestoreFailedSnackbar => 'Не удалось прочитать JSON-конфигурацию из буфера';

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
}