/// Библиотека многооконного рабочего пространства рабочего стола:
/// свободное перемещение, тайлинг, вкладки, панели задач и геометрия прилипания.
library desktop_workspace;

export 'src/controllers/workspace_controller.dart';
export 'src/models/geometry_types.dart';
export 'src/models/tab_drag_data.dart';
export 'src/models/window_state.dart';
export 'src/models/workspace_state.dart';
export 'src/models/workspace_tab.dart';
export 'src/theme/desktop_theme.dart';
export 'src/widgets/canvas/desktop_background.dart';
export 'src/widgets/canvas/snap_dock_guides.dart';
export 'src/widgets/canvas/snap_preview_overlay.dart';
export 'src/widgets/desktop_canvas.dart';
export 'src/widgets/taskbar/desktop_taskbar.dart';
export 'src/widgets/taskbar/hover_preview_card.dart';
export 'src/widgets/taskbar/system_tray.dart';
export 'src/widgets/taskbar/taskbar_item.dart';
export 'src/widgets/taskbar/tray_popup_card.dart';
export 'src/widgets/window/panel_content_host.dart';
export 'src/widgets/window/tab_chip.dart';
export 'src/widgets/window/window_frame.dart';
export 'src/widgets/window/window_resize_handles.dart';
export 'src/widgets/window/window_title_bar.dart';
