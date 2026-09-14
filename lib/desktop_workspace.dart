/// Библиотека многооконного рабочего пространства рабочего стола:
/// свободное перемещение, тайлинг, вкладки, панели задач и геометрия прилипания.
library desktop_workspace;

export 'src/config/workspace_config.dart';
export 'src/engine/geometry/magnet_snapper.dart';
export 'src/engine/layout/tile_calculator.dart';
export 'src/engine/seam/seam_resizer.dart';
export 'src/l10n/workspace_strings.dart';
export 'src/presentation/canvas/desktop_background.dart';
export 'src/presentation/canvas/desktop_canvas.dart';
export 'src/presentation/canvas/snap_dock_guides.dart';
export 'src/presentation/canvas/snap_preview_box.dart';
export 'src/presentation/taskbar/desktop_taskbar.dart';
export 'src/presentation/taskbar/hover_preview.dart';
export 'src/presentation/taskbar/system_tray.dart';
export 'src/presentation/taskbar/taskbar_window_chip.dart';
export 'src/presentation/taskbar/tray_popup_card.dart';
export 'src/presentation/window/tab_chip.dart';
export 'src/presentation/window/window_content_host.dart';
export 'src/presentation/window/window_frame.dart';
export 'src/presentation/window/window_resize_edge.dart';
export 'src/presentation/window/window_title_bar.dart';
export 'src/registry/panel_registry.dart';
export 'src/state/controllers/workspace_controller.dart';
export 'src/state/models/geometry_types.dart';
export 'src/state/models/tab_drag_payload.dart';
export 'src/state/models/window_state.dart';
export 'src/state/models/workspace_state.dart';
export 'src/state/models/workspace_tab.dart';
export 'src/theme/workspace_theme.dart';