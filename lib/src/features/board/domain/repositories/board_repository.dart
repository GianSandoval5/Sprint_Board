import 'dart:typed_data';

import '../entities/board_models.dart';

abstract class BoardRepository {
  Future<WorkspaceConfig> loadLocalConfig();
  Future<BoardWorkspaceSnapshot?> tryRestoreWorkspace();
  Future<BoardWorkspaceSnapshot> bootstrapWorkspace(
    String apiKey, {
    bool reset,
  });
  Future<BoardWorkspaceSnapshot> selectSection(BoardSection section);
  Future<BoardWorkspaceSnapshot> updateSettings({
    MemoryMode? memoryMode,
    bool? webSearchEnabled,
    String? provider,
    String? model,
  });
  Future<BoardWorkspaceSnapshot> sendMessage(String content);
  Future<BoardWorkspaceSnapshot> uploadAssistantDocument(
    Uint8List bytes,
    String filename,
  );
  Future<void> clearLocalWorkspace();
}
