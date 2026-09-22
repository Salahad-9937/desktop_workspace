import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/workspace_config.dart';
import '../engine/layout_generator.dart';
import '../model/geometry_types.dart';
import '../model/tab_drag_payload.dart';
import '../model/view_definition.dart';
import '../model/window_state.dart';
import '../model/workspace_profile.dart';
import '../model/workspace_tab.dart';
import 'persistence/session_storage.dart';
import 'persistence/workspace_snapshot.dart';
import 'tab_lifecycle_ops.dart';
import 'window_geometry_ops.dart';
import 'window_hierarchy_ops.dart';
import 'workspace_layout_ops.dart';
import 'workspace_state.dart';

part 'workspace_controller.g.dart';

/// Контроллер-оркестратор реактивного состояния холста на базе Riverpod Generator.
@Riverpod(keepAlive: true)
class WorkspaceController extends _$WorkspaceController {
  Timer? _autosaveTimer;
  SessionStorage? _sessionStorage;
  Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  WorkspaceState build() {
    ref.onDispose(() {
      _autosaveTimer?.cancel();
    });
    return const WorkspaceState();
  }

  /// Задает глобальную конфигурацию холста [config] с пересчетом полезной области при смене высоты дока.
  void updateConfig(WorkspaceConfig config) {
    final double oldDockHeight = state.config.dockHeight;
    final bool dockChanged = config.dockHeight != oldDockHeight;
    state = state.copyWith(config: config);

    if (dockChanged && state.availableArea.width > 0.0) {
      final double totalHeight =
          state.availableArea.height + oldDockHeight;
      updateViewportSize(state.availableArea.width, totalHeight);
    } else {
      _scheduleAutosave();
    }
  }

  /// Подключает адаптер хранилища для прозрачного автосохранения сессии.
  void attachSessionStorage(
    SessionStorage storage, {
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) {
    _sessionStorage = storage;
    _debounceDuration = debounceDuration;
  }

  /// Обновляет габариты родительского видового экрана и адаптирует окна.
  void updateViewportSize(double width, double height) {
    state = WindowGeometryOps.updateViewportSize(state, width, height);
  }

  /// Открывает прикладную панель из каталога без разрушения существующих окон.
  void openView({
    required ViewDefinition definition,
    Map<String, dynamic>? payload,
  }) {
    state = WorkspaceLayoutOps.openView(
      state,
      definition: definition,
      payload: payload,
    );
    _scheduleAutosave();
  }

  /// Передает активный фокус целевому окну.
  void focusWindow(String windowId) {
    state = WindowHierarchyOps.focusWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Выполняет свободное перемещение окна.
  void moveWindow({
    required String windowId,
    required double deltaX,
    required double deltaY,
    bool enableSnapping = true,
    bool enableTilingDetection = true,
    double? pointerX,
    double? pointerY,
  }) {
    state = WindowGeometryOps.moveWindow(
      state: state,
      windowId: windowId,
      deltaX: deltaX,
      deltaY: deltaY,
      enableSnapping: enableSnapping,
      enableTilingDetection: enableTilingDetection,
      pointerX: pointerX,
      pointerY: pointerY,
    );
  }

  /// Завершает интерактивную фазу перемещения окна (Commit Phase).
  void commitMove(String windowId) {
    state = WindowGeometryOps.commitMove(state, windowId);
    _scheduleAutosave();
  }

  /// Переводит окно в заданную зону тайлинга [zone].
  void tileWindow(String windowId, SnapZone zone) {
    state = WindowGeometryOps.tileWindow(state, windowId, zone);
    _scheduleAutosave();
  }

  /// Сбрасывает тайлинг и возвращает плавающую геометрию окна.
  void untileWindow(String windowId) {
    state = WindowGeometryOps.untileWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Изменяет габариты окна по ортогональным и диагональным направлениям.
  void resizeWindow({
    required String windowId,
    required ResizeDirection direction,
    required double deltaX,
    required double deltaY,
    bool enableSeamResizing = true,
    bool enableSnapping = true,
  }) {
    state = WindowGeometryOps.resizeWindow(
      state: state,
      windowId: windowId,
      direction: direction,
      deltaX: deltaX,
      deltaY: deltaY,
      enableSeamResizing: enableSeamResizing,
      enableSnapping: enableSnapping,
    );
    _scheduleAutosave();
  }

  /// Завершает интерактивную фазу изменения размеров окна.
  void commitResize() {
    state = WindowGeometryOps.commitResize(state);
    _scheduleAutosave();
  }

  /// Сворачивает окно в панель быстрого доступа.
  void minimizeWindow(String windowId) {
    state = WindowHierarchyOps.minimizeWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Восстанавливает свернутое окно на холст.
  void restoreWindow(String windowId) {
    state = WindowHierarchyOps.restoreWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Переключает полноэкранное развертывание окна.
  void toggleMaximizeWindow(String windowId) {
    state = WindowGeometryOps.toggleMaximizeWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Переключает статус закрепления поверх всех окон (Always on Top).
  void togglePinWindow(String windowId) {
    state = WindowHierarchyOps.togglePinWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Переключает режим монопольного фокуса (Solo Mode).
  void toggleSoloMode(String windowId) {
    state = WindowHierarchyOps.toggleSoloMode(state, windowId);
  }

  /// Закрывает оконный фрейм.
  void closeWindow(String windowId) {
    state = WindowHierarchyOps.closeWindow(state, windowId);
    _scheduleAutosave();
  }

  /// Выбирает активную вкладку по ее индексу.
  void selectTab(String windowId, int tabIndex) {
    state = TabLifecycleOps.selectTab(state, windowId, tabIndex);
    _scheduleAutosave();
  }

  /// Закрывает вкладку с каскадным уничтожением контейнера при опустошении.
  void closeTab({required String windowId, required String tabId}) {
    state = TabLifecycleOps.closeTab(state, windowId, tabId);
    _scheduleAutosave();
  }

  /// Создает дубликат активного представления.
  void duplicateTab({required String windowId, required String tabId}) {
    state = TabLifecycleOps.duplicateTab(state, windowId, tabId);
    _scheduleAutosave();
  }

  /// Инициирует операцию перетаскивания вкладки.
  void startTabDrag(TabDragPayload payload) {
    state = state.copyWith(draggingTabPayload: payload);
  }

  /// Завершает операцию перетаскивания вкладки.
  void endTabDrag() {
    state = state.copyWith(clearDraggingTab: true);
  }

  /// Поглощает перенесенную вкладку в целевое окно (Tab Merging).
  void dropTabOnWindow({
    required TabDragPayload payload,
    required String targetWindowId,
    int? insertIndex,
  }) {
    state = TabLifecycleOps.dropTabOnWindow(
      state: state,
      payload: payload,
      targetWindowId: targetWindowId,
      insertIndex: insertIndex,
    );
    _scheduleAutosave();
  }

  /// Отрывает вкладку в самостоятельное новое окно на холсте (Tear-off).
  void detachTabToNewWindow({
    required TabDragPayload payload,
    required double dropX,
    required double dropY,
    double? width,
    double? height,
  }) {
    state = TabLifecycleOps.detachTabToNewWindow(
      state: state,
      payload: payload,
      dropX: dropX,
      dropY: dropY,
      width: width,
      height: height,
    );
    _scheduleAutosave();
  }

  /// Применяет декларативный макет сетки 2x2.
  void applyPresetGrid(List<List<WorkspaceTab>> slotsTabs) {
    state = WorkspaceLayoutOps.applyPresetGrid(state, slotsTabs);
    _scheduleAutosave();
  }

  /// Применяет декларативный макет пропорционального сплита.
  void applyPresetSplit({
    required List<List<WorkspaceTab>> windowsTabs,
    SplitOrientation orientation = SplitOrientation.horizontal,
    double splitRatio = 0.5,
  }) {
    state = WorkspaceLayoutOps.applyPresetSplit(
      state,
      windowsTabs: windowsTabs,
      orientation: orientation,
      splitRatio: splitRatio,
    );
    _scheduleAutosave();
  }

  /// Применяет макет одиночного окна.
  void applyPresetSolo(List<WorkspaceTab> tabs) {
    state = WorkspaceLayoutOps.applyPresetSolo(state, tabs);
    _scheduleAutosave();
  }

  /// Применяет именованный профиль раскладки холста.
  void applyProfile(WorkspaceProfile profile) {
    state = WorkspaceLayoutOps.applyProfile(state, profile);
    _scheduleAutosave();
  }

  /// Создает снимок текущего состояния холста в именованный профиль.
  WorkspaceProfile createCurrentProfile({
    required String id,
    required String name,
    bool isFactory = false,
  }) {
    return WorkspaceLayoutOps.createCurrentProfile(
      state,
      id: id,
      name: name,
      isFactory: isFactory,
    );
  }

  /// Создает снимок текущей сессии для персистентности.
  WorkspaceSnapshot createSnapshot() {
    return WorkspaceSnapshot(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      windows: state.windows,
      focusedWindowId: state.focusedWindowId,
      soloWindowId: state.soloWindowId,
      canvasWidth: state.availableArea.width,
      canvasHeight: state.availableArea.height,
    );
  }

  /// Восстанавливает состояние холста из снимка сессии.
  void restoreFromSnapshot(WorkspaceSnapshot snapshot) {
    state = state.copyWith(
      windows: snapshot.windows,
      focusedWindowId: snapshot.focusedWindowId,
      soloWindowId: snapshot.soloWindowId,
      dockOrder: snapshot.windows
          .map<String>((WindowState w) => w.id)
          .toList(growable: false),
    );
  }

  void _scheduleAutosave() {
    if (_sessionStorage == null) {
      return;
    }
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      _debounceDuration,
      () {
        unawaited(_sessionStorage!.saveSnapshot(createSnapshot()));
      },
    );
  }
}