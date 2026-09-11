// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Контроллер управления многооконным рабочим пространством, геометрией и вкладками.

@ProviderFor(WorkspaceController)
final workspaceControllerProvider = WorkspaceControllerProvider._();

/// Контроллер управления многооконным рабочим пространством, геометрией и вкладками.
final class WorkspaceControllerProvider
    extends $NotifierProvider<WorkspaceController, WorkspaceState> {
  /// Контроллер управления многооконным рабочим пространством, геометрией и вкладками.
  WorkspaceControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'workspaceControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$workspaceControllerHash();

  @$internal
  @override
  WorkspaceController create() => WorkspaceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceState>(value),
    );
  }
}

String _$workspaceControllerHash() =>
    r'01404291f4efdf5041c68b577313e3234ebfb4e5';

/// Контроллер управления многооконным рабочим пространством, геометрией и вкладками.

abstract class _$WorkspaceController extends $Notifier<WorkspaceState> {
  WorkspaceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkspaceState, WorkspaceState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<WorkspaceState, WorkspaceState>,
        WorkspaceState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
