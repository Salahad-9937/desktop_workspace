import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Models & Serialization Tests', () {
    test('WindowConstraints: clamp, resolveWith, copyWith, equality, toString', () {
      const WindowConstraints c1 = WindowConstraints(
        minWidth: 300.0,
        minHeight: 200.0,
        maxWidth: 800.0,
        maxHeight: 600.0,
      );

      expect(c1.clampWidth(250.0), 300.0);
      expect(c1.clampWidth(900.0), 800.0);
      expect(c1.clampWidth(500.0), 500.0);

      expect(c1.clampHeight(150.0), 200.0);
      expect(c1.clampHeight(700.0), 600.0);
      expect(c1.clampHeight(400.0), 400.0);

      expect(c1.resolveWith(null), c1);

      const WindowConstraints overrideC = WindowConstraints(
        minWidth: 400.0,
        minHeight: 250.0,
        maxWidth: 700.0,
        maxHeight: 500.0,
      );
      final WindowConstraints resolved = c1.resolveWith(overrideC);
      expect(resolved.minWidth, 400.0);
      expect(resolved.minHeight, 250.0);
      expect(resolved.maxWidth, 700.0);
      expect(resolved.maxHeight, 500.0);

      final WindowConstraints copied = c1.copyWith(minWidth: 350.0);
      expect(copied.minWidth, 350.0);
      expect(copied.minHeight, 200.0);
      expect(copied == c1, isFalse);
      expect(
        c1 ==
            const WindowConstraints(
              minWidth: 300.0,
              minHeight: 200.0,
              maxWidth: 800.0,
              maxHeight: 600.0,
            ),
        isTrue,
      );
      expect(c1.hashCode, isNotNull);
      expect(c1.toString(), contains('WindowConstraints'));
    });

    test('WorkspaceConfig: defaults, copyWith, equality, hashCode', () {
      const WorkspaceConfig conf = WorkspaceConfig();
      expect(conf.magnetThreshold, 10.0);
      expect(conf.dockHeight, 48.0);
      expect(conf.headerHeight, 36.0);

      final WorkspaceConfig copied = conf.copyWith(
        magnetThreshold: 15.0,
        dockHeight: 54.0,
      );
      expect(copied.magnetThreshold, 15.0);
      expect(copied.dockHeight, 54.0);
      expect(copied.headerHeight, 36.0);
      expect(conf == copied, isFalse);
      expect(conf.hashCode, isNotNull);
      expect(conf == const WorkspaceConfig(), isTrue);
    });

    test('WorkspaceState: getters, copyWith resets, toString', () {
      const WindowState standardWin = WindowState(
        id: 'w_std',
        x: 0,
        y: 0,
        width: 400,
        height: 300,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v', title: 'T1')],
      );
      const WindowState pinnedWin = WindowState(
        id: 'w_pinned',
        x: 400,
        y: 0,
        width: 400,
        height: 300,
        isPinnedOnTop: true,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't2', typeId: 'v', title: 'T2')],
      );
      const WindowState minWin = WindowState(
        id: 'w_min',
        x: 0,
        y: 300,
        width: 400,
        height: 300,
        isMinimized: true,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't3', typeId: 'v', title: 'T3')],
      );

      const WorkspaceState state = WorkspaceState(
        windows: <WindowState>[standardWin, pinnedWin, minWin],
        focusedWindowId: 'w_std',
        soloWindowId: 'w_std',
      );

      expect(state.focusedWindow?.id, 'w_std');
      expect(state.soloWindow?.id, 'w_std');
      expect(state.isSoloMode, isTrue);

      expect(state.standardWindows.length, 1);
      expect(state.standardWindows.first.id, 'w_std');

      expect(state.pinnedWindows.length, 1);
      expect(state.pinnedWindows.first.id, 'w_pinned');

      expect(state.minimizedWindows.length, 1);
      expect(state.minimizedWindows.first.id, 'w_min');

      expect(state.visibleWindows.length, 2);

      final WorkspaceState cleared = state.copyWith(
        clearFocusedWindow: true,
        clearSoloWindow: true,
        clearDraggingTab: true,
        clearRawDrag: true,
      );
      expect(cleared.focusedWindowId, isNull);
      expect(cleared.soloWindowId, isNull);
      expect(cleared.isSoloMode, isFalse);
      expect(cleared.rawDragX, isNull);
      expect(cleared.rawDragY, isNull);
      expect(state.toString(), contains('WorkspaceState'));
    });

    test('WorkspaceRect: factory constructors, containsPoint, intersectsWith, copyWith, toString', () {
      final WorkspaceRect r1 = WorkspaceRect.fromLTRB(10.0, 20.0, 110.0, 120.0);
      expect(r1.x, 10.0);
      expect(r1.y, 20.0);
      expect(r1.width, 100.0);
      expect(r1.height, 100.0);
      expect(r1.right, 110.0);
      expect(r1.bottom, 120.0);

      final WorkspaceRect r2 = WorkspaceRect.fromLTWH(50.0, 50.0, 100.0, 100.0);
      expect(r1.containsPoint(50.0, 50.0), isTrue);
      expect(r1.containsPoint(200.0, 200.0), isFalse);
      expect(r1.intersectsWith(r2), isTrue);

      final WorkspaceRect r3 = WorkspaceRect.fromLTWH(500.0, 500.0, 50.0, 50.0);
      expect(r1.intersectsWith(r3), isFalse);

      final WorkspaceRect copied = r1.copyWith(x: 15.0);
      expect(copied.x, 15.0);
      expect(copied.width, 100.0);
      expect(r1 == copied, isFalse);
      expect(r1.hashCode, isNotNull);
      expect(r1.toString(), contains('WorkspaceRect'));
    });

    test('WorkspaceTab: copyWith, toMap, fromMap, equality, toString', () {
      const WorkspaceTab tab = WorkspaceTab(
        id: 'tab_test_1',
        typeId: 'type_test_1',
        title: 'Тестовый таб',
        icon: Icons.analytics_outlined,
        accentColor: Color(0xFF00E5FF),
        keepAlive: true,
        constraints: WindowConstraints(minWidth: 320.0, minHeight: 240.0),
        payload: <String, dynamic>{'key': 'value'},
      );

      final Map<String, dynamic> map = tab.toMap();
      expect(map['id'], 'tab_test_1');
      expect(map['title'], 'Тестовый таб');

      final Map<String, dynamic>? payloadMap =
          map['payload'] as Map<String, dynamic>?;
      expect(payloadMap?['key'], 'value');

      final WorkspaceTab fromMapTab =
          WorkspaceTab.fromMap(map, icon: Icons.analytics_outlined);
      expect(fromMapTab.id, tab.id);
      expect(fromMapTab.typeId, tab.typeId);
      expect(fromMapTab.title, tab.title);
      expect(fromMapTab.accentColor, tab.accentColor);
      expect(fromMapTab.constraints?.minWidth, 320.0);
      expect(fromMapTab.payload?['key'], 'value');
      expect(fromMapTab == tab, isTrue);

      final WorkspaceTab copied = tab.copyWith(title: 'Новый заголовок');
      expect(copied.title, 'Новый заголовок');
      expect(copied.id, tab.id);
      expect(tab.toString(), contains('WorkspaceTab'));
    });

    test('WindowState: toMap, fromMap, activeTab, resolveEffectiveConstraints, copyWith, equality', () {
      const WorkspaceTab tab1 = WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1');
      const WorkspaceTab tab2 = WorkspaceTab(id: 't2', typeId: 'v2', title: 'T2');

      const WindowState state = WindowState(
        id: 'win_state_1',
        x: 50.0,
        y: 60.0,
        width: 400.0,
        height: 300.0,
        tabs: <WorkspaceTab>[tab1, tab2],
        activeTabIndex: 1,
        isPinnedOnTop: true,
        isMinimized: false,
        isMaximized: false,
        snapZone: SnapZone.topLeft,
        restoreRect: WorkspaceRect(x: 10.0, y: 10.0, width: 350.0, height: 250.0),
        createdAt: 123456789,
      );

      expect(state.activeTab, tab2);

      const WindowState emptyTabsState =
          WindowState(id: 'empty', x: 0, y: 0, width: 100, height: 100, tabs: <WorkspaceTab>[]);
      expect(emptyTabsState.activeTab, isNull);

      final Map<String, dynamic> map = state.toMap();
      final WindowState fromMapState = WindowState.fromMap(map);

      expect(fromMapState.id, state.id);
      expect(fromMapState.x, state.x);
      expect(fromMapState.width, state.width);
      expect(fromMapState.activeTabIndex, 1);
      expect(fromMapState.isPinnedOnTop, isTrue);
      expect(fromMapState.snapZone, SnapZone.topLeft);
      expect(fromMapState.restoreRect?.width, 350.0);

      const WindowConstraints globalDefault =
          WindowConstraints(minWidth: 260.0, minHeight: 180.0);
      expect(state.resolveEffectiveConstraints(globalDefault), globalDefault);

      final WindowState copied = state.copyWith(width: 450.0);
      expect(copied.width, 450.0);
      expect(state == copied, isFalse);
      expect(state.hashCode, isNotNull);
      expect(state.toString(), contains('WindowState'));
    });

    test('TabDragPayload: copyWith, equality, hashCode, toString', () {
      const WorkspaceTab tab = WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1');
      const TabDragPayload p1 = TabDragPayload(
        tab: tab,
        sourceWindowId: 'win_1',
        sourceTabIndex: 0,
        isSingleTab: true,
      );

      final TabDragPayload p2 = p1.copyWith(sourceTabIndex: 1);
      expect(p2.sourceTabIndex, 1);
      expect(p2.sourceWindowId, 'win_1');
      expect(p1 == p2, isFalse);
      expect(
        p1 ==
            const TabDragPayload(
              tab: tab,
              sourceWindowId: 'win_1',
              sourceTabIndex: 0,
              isSingleTab: true,
            ),
        isTrue,
      );
      expect(p1.hashCode, isNotNull);
      expect(p1.toString(), contains('TabDragPayload'));
    });

    test('WorkspaceProfile & RelativeWindowPlacement: toMap, fromMap', () {
      const RelativeWindowPlacement placement = RelativeWindowPlacement(
        windowId: 'win_p1',
        relativeX: 0.1,
        relativeY: 0.1,
        relativeWidth: 0.4,
        relativeHeight: 0.8,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
        activeTabIndex: 0,
        isPinnedOnTop: false,
        isMinimized: false,
        isMaximized: false,
        snapZone: SnapZone.none,
      );

      final Map<String, dynamic> placementMap = placement.toMap();
      final RelativeWindowPlacement fromMapPlacement =
          RelativeWindowPlacement.fromMap(placementMap);
      expect(fromMapPlacement.windowId, 'win_p1');
      expect(fromMapPlacement.relativeX, 0.1);
      expect(fromMapPlacement.relativeWidth, 0.4);

      const WorkspaceProfile profile = WorkspaceProfile(
        id: 'prof_analytics',
        name: 'Аналитический дашборд',
        isFactory: true,
        placements: <RelativeWindowPlacement>[placement],
      );

      final Map<String, dynamic> profileMap = profile.toMap();
      final WorkspaceProfile fromMapProfile =
          WorkspaceProfile.fromMap(profileMap);
      expect(fromMapProfile.id, 'prof_analytics');
      expect(fromMapProfile.name, 'Аналитический дашборд');
      expect(fromMapProfile.isFactory, isTrue);
      expect(fromMapProfile.placements.length, 1);
    });

    test('WorkspaceSnapshot: toMap, fromMap с безопасной деградацией', () {
      const WindowState win = WindowState(
        id: 'w1',
        x: 10,
        y: 20,
        width: 300,
        height: 200,
        tabs: <WorkspaceTab>[WorkspaceTab(id: 't1', typeId: 'v1', title: 'T1')],
      );
      const WorkspaceSnapshot snapshot = WorkspaceSnapshot(
        timestamp: 123456789,
        windows: <WindowState>[win],
        focusedWindowId: 'w1',
        canvasWidth: 1280.0,
        canvasHeight: 800.0,
      );

      final Map<String, dynamic> map = snapshot.toMap();
      final WorkspaceSnapshot restored = WorkspaceSnapshot.fromMap(map);

      expect(restored.windows.length, 1);
      expect(restored.windows.first.id, 'w1');
      expect(restored.focusedWindowId, 'w1');
      expect(restored.canvasWidth, 1280.0);

      final WorkspaceSnapshot degraded = WorkspaceSnapshot.fromMap(<String, dynamic>{
        'windows': <dynamic>[
          'invalid_item_string',
          null,
          win.toMap(),
        ],
      });
      expect(degraded.windows.length, 1);
    });

    test('InMemorySessionStorage: clearSnapshot очищает данные', () async {
      final InMemorySessionStorage storage = InMemorySessionStorage();
      await storage.saveSnapshot(
        const WorkspaceSnapshot(timestamp: 1, windows: <WindowState>[]),
      );
      expect(await storage.loadSnapshot(), isNotNull);

      await storage.clearSnapshot();
      expect(await storage.loadSnapshot(), isNull);
    });

    test('WorkspaceThemeData: light, copyWith, lerp, equality, hashCode', () {
      const WorkspaceThemeData lightTheme = WorkspaceThemeData.light();
      expect(lightTheme.spaceBackground, const Color(0xFFF0F2F5));

      final WorkspaceThemeData copied = lightTheme.copyWith(windowRadius: 12.0);
      expect(copied.windowRadius, 12.0);
      expect(copied == lightTheme, isFalse);

      final WorkspaceThemeData lerped = lightTheme.lerp(copied, 0.5);
      expect(lerped.windowRadius, 10.0);
      expect(lightTheme.hashCode, isNotNull);
    });

    test('Geometry Extensions: SnapZoneExtension & ResizeDirectionExtension', () {
      expect(SnapZone.maximize.isMaximize, isTrue);
      expect(SnapZone.leftHalf.isHalf, isTrue);
      expect(SnapZone.rightHalf.isHalf, isTrue);
      expect(SnapZone.topLeft.isQuarter, isTrue);
      expect(SnapZone.none.isNone, isTrue);

      expect(ResizeDirection.east.isHorizontal, isTrue);
      expect(ResizeDirection.west.isHorizontal, isTrue);
      expect(ResizeDirection.north.isVertical, isTrue);
      expect(ResizeDirection.south.isVertical, isTrue);
      expect(ResizeDirection.southEast.isDiagonal, isTrue);
      expect(ResizeDirection.northWest.isDiagonal, isTrue);

      expect(ResizeDirection.west.affectsLeft, isTrue);
      expect(ResizeDirection.east.affectsRight, isTrue);
      expect(ResizeDirection.north.affectsTop, isTrue);
      expect(ResizeDirection.south.affectsBottom, isTrue);
    });
  });
}