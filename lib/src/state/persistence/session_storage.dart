import 'workspace_snapshot.dart';

/// Абстрактный контракт адаптера постоянного хранилища сессии рабочего пространства.
abstract class SessionStorage {
  /// Сохраняет снимок состояния в хранилище.
  Future<void> saveSnapshot(WorkspaceSnapshot snapshot);

  /// Считывает сохраненный снимок либо возвращает `null`, если данные отсутствуют.
  Future<WorkspaceSnapshot?> loadSnapshot();

  /// Очищает сохраненные данные сессии.
  Future<void> clearSnapshot();
}

/// Реализация хранилища сессии в оперативной памяти для тестов и сценариев по умолчанию.
class InMemorySessionStorage implements SessionStorage {
  WorkspaceSnapshot? _storedSnapshot;

  /// Создает экземпляр [InMemorySessionStorage].
  InMemorySessionStorage([this._storedSnapshot]);

  @override
  Future<void> saveSnapshot(WorkspaceSnapshot snapshot) async {
    _storedSnapshot = snapshot;
  }

  @override
  Future<WorkspaceSnapshot?> loadSnapshot() async {
    return _storedSnapshot;
  }

  @override
  Future<void> clearSnapshot() async {
    _storedSnapshot = null;
  }
}