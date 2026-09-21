/// Библиотека модульного оконного менеджера холста для настольных приложений.
library desktop_workspace;

// Конфигурация
export 'src/config/window_constraints.dart';
export 'src/config/workspace_config.dart';

// Доменные модели и геометрия
export 'src/model/geometry_types.dart';
export 'src/model/tab_drag_payload.dart';
export 'src/model/view_definition.dart';
export 'src/model/window_state.dart';
export 'src/model/workspace_profile.dart';
export 'src/model/workspace_tab.dart';

// Вычислительное ядро геометрии
export 'src/engine/bounds_clamper.dart';
export 'src/engine/layout_generator.dart';
export 'src/engine/magnet_snapper.dart';
export 'src/engine/seam_resizer.dart';
export 'src/engine/snap_zone_detector.dart';

// Стилизация и дизайн-токены
export 'src/theme/workspace_theme.dart';
export 'src/theme/workspace_theme_data.dart';

// Управление состоянием и персистентность
export 'src/state/persistence/session_storage.dart';
export 'src/state/persistence/workspace_snapshot.dart';
export 'src/state/workspace_controller.dart';
export 'src/state/workspace_state.dart';

// Презентационный слой
export 'src/presentation/canvas/canvas_background.dart';
export 'src/presentation/canvas/snap_dock_guides.dart';
export 'src/presentation/canvas/snap_preview_box.dart';
export 'src/presentation/canvas/workspace_canvas.dart';
export 'src/presentation/catalog/view_catalog_palette.dart';
export 'src/presentation/dock/dock_hover_preview.dart';
export 'src/presentation/dock/dock_window_chip.dart';
export 'src/presentation/dock/workspace_dock.dart';
export 'src/presentation/window/tab_chip.dart';
export 'src/presentation/window/window_content_host.dart';
export 'src/presentation/window/window_frame.dart';
export 'src/presentation/window/window_resize_edge.dart';
export 'src/presentation/window/window_title_bar.dart';