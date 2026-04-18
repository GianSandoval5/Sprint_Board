import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/backboard_remote_data_source.dart';
import '../../data/datasources/board_local_data_source.dart';
import '../../data/repositories/board_repository_impl.dart';
import '../../data/services/sprint_board_toolkit.dart';
import '../../domain/entities/board_models.dart';
import '../../domain/repositories/board_repository.dart';
import 'board_state.dart';

final boardLocalDataSourceProvider = Provider<BoardLocalDataSource>(
  (ref) => BoardLocalDataSource(),
);

final backboardRemoteDataSourceProvider = Provider<BackboardRemoteDataSource>(
  (ref) => BackboardRemoteDataSource(),
);

final sprintBoardToolkitProvider = Provider<SprintBoardToolkit>(
  (ref) => const SprintBoardToolkit(),
);

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepositoryImpl(
    localDataSource: ref.read(boardLocalDataSourceProvider),
    remoteDataSource: ref.read(backboardRemoteDataSourceProvider),
    toolkit: ref.read(sprintBoardToolkitProvider),
  );
});

final boardControllerProvider = NotifierProvider<BoardController, BoardState>(
  BoardController.new,
);

class BoardController extends Notifier<BoardState> {
  BoardRepository get _repository => ref.read(boardRepositoryProvider);

  @override
  BoardState build() => BoardState.initial();

  Future<void> initialize() async {
    if (state.isInitializing) {
      return;
    }

    state = state.copyWith(
      isInitializing: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      final config = await _repository.loadLocalConfig();
      final snapshot = await _repository.tryRestoreWorkspace();
      state = state.copyWith(
        config: snapshot?.config ?? config,
        snapshot: snapshot,
        clearSnapshot: snapshot == null,
        isInitializing: false,
        hasLoadedOnce: true,
      );
    } catch (error) {
      final config = await _repository.loadLocalConfig();
      state = state.copyWith(
        config: config,
        clearSnapshot: true,
        isInitializing: false,
        errorMessage: error.toString(),
        hasLoadedOnce: true,
      );
    }
  }

  Future<void> bootstrapWorkspace(
    String apiKey, {
    bool reset = false,
  }) async {
    state = state.copyWith(
      isInitializing: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      final snapshot = await _repository.bootstrapWorkspace(
        apiKey,
        reset: reset,
      );
      state = state.copyWith(
        config: snapshot.config,
        snapshot: snapshot,
        isInitializing: false,
        infoMessage: reset
            ? 'Workspace reconstruido. Los recursos remotos anteriores no se borraron.'
            : 'Workspace listo. Ya puedes empezar a cargar docs y conversar.',
      );
    } catch (error) {
      final config = await _repository.loadLocalConfig();
      state = state.copyWith(
        config: config.copyWith(apiKey: apiKey.trim()),
        isInitializing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> selectSection(BoardSection section) async {
    if (state.isInitializing) {
      return;
    }

    state = state.copyWith(isInitializing: true, clearError: true, clearInfo: true);
    try {
      final snapshot = await _repository.selectSection(section);
      state = state.copyWith(
        config: snapshot.config,
        snapshot: snapshot,
        isInitializing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (state.isSending) {
      return;
    }

    state = state.copyWith(isSending: true, clearError: true, clearInfo: true);
    try {
      final snapshot = await _repository.sendMessage(content);
      state = state.copyWith(
        config: snapshot.config,
        snapshot: snapshot,
        isSending: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> uploadDocument(Uint8List bytes, String filename) async {
    if (state.isUploading) {
      return;
    }

    state = state.copyWith(isUploading: true, clearError: true, clearInfo: true);
    try {
      final snapshot = await _repository.uploadAssistantDocument(bytes, filename);
      state = state.copyWith(
        config: snapshot.config,
        snapshot: snapshot,
        isUploading: false,
        infoMessage: 'Documento subido. Si sigue procesando, actualiza en unos segundos.',
      );
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> updateMemoryMode(MemoryMode mode) async {
    await _updateSettings(memoryMode: mode);
  }

  Future<void> updateWebSearch(bool enabled) async {
    await _updateSettings(webSearchEnabled: enabled);
  }

  Future<void> updateModel({
    required String provider,
    required String model,
  }) async {
    await _updateSettings(provider: provider.trim(), model: model.trim());
  }

  Future<void> clearLocalWorkspace() async {
    await _repository.clearLocalWorkspace();
    state = state.copyWith(
      config: WorkspaceConfig.empty(),
      clearSnapshot: true,
      clearError: true,
      infoMessage: 'Workspace local limpiado. Los assistants y threads remotos permanecen en Backboard.',
    );
  }

  void dismissError() {
    state = state.copyWith(clearError: true);
  }

  void dismissInfo() {
    state = state.copyWith(clearInfo: true);
  }

  Future<void> _updateSettings({
    MemoryMode? memoryMode,
    bool? webSearchEnabled,
    String? provider,
    String? model,
  }) async {
    state = state.copyWith(isInitializing: true, clearError: true, clearInfo: true);
    try {
      final snapshot = await _repository.updateSettings(
        memoryMode: memoryMode,
        webSearchEnabled: webSearchEnabled,
        provider: provider,
        model: model,
      );
      state = state.copyWith(
        config: snapshot.config,
        snapshot: snapshot,
        isInitializing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: error.toString(),
      );
    }
  }
}
