// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Контроллер-оркестратор реактивного состояния холста на базе Riverpod Generator.

@ProviderFor(WorkspaceController)
final workspaceControllerProvider = WorkspaceControllerProvider._();

/// Контроллер-оркестратор реактивного состояния холста на базе Riverpod Generator.
final class WorkspaceControllerProvider
    extends $NotifierProvider<WorkspaceController, WorkspaceState> {
  /// Контроллер-оркестратор реактивного состояния холста на базе Riverpod Generator.
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
    r'18b60f87ed16466a786a3458fefeb20838e4217d';

/// Контроллер-оркестратор реактивного состояния холста на базе Riverpod Generator.

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
