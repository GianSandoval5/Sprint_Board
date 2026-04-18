import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/board_models.dart';
import '../../domain/repositories/board_repository.dart';
import '../datasources/backboard_remote_data_source.dart';
import '../datasources/board_local_data_source.dart';
import '../services/sprint_board_toolkit.dart';

class BoardRepositoryImpl implements BoardRepository {
  BoardRepositoryImpl({
    required BoardLocalDataSource localDataSource,
    required BackboardRemoteDataSource remoteDataSource,
    required SprintBoardToolkit toolkit,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _toolkit = toolkit;

  final BoardLocalDataSource _localDataSource;
  final BackboardRemoteDataSource _remoteDataSource;
  final SprintBoardToolkit _toolkit;

  static const _assistantName = 'SprintBoard Orchestrator';
  static const _systemPrompt = '''
You are SprintBoard, a hackathon copilot for a Flutter team building with Backboard.

Rules:
- Think like a senior builder and keep answers practical.
- Reuse shared memory across threads so the product thesis stays consistent.
- When helpful, call tools to create a task board, score the rubric fit, draft README content, or build a demo script.
- Prefer concise output with clear next actions.
- Assume the five thread lanes are Idea, Frontend, Backend, README, and Demo.
- When documents are available, use them as source context instead of hallucinating specifics.
''';

  @override
  Future<WorkspaceConfig> loadLocalConfig() {
    return _localDataSource.loadConfig();
  }

  @override
  Future<BoardWorkspaceSnapshot?> tryRestoreWorkspace() async {
    final config = await _localDataSource.loadConfig();
    if (!config.isConfigured) {
      return null;
    }
    return _buildSnapshot(config.selectedSection);
  }

  @override
  Future<BoardWorkspaceSnapshot> bootstrapWorkspace(
    String apiKey, {
    bool reset = false,
  }) async {
    var config = await _localDataSource.loadConfig();
    final incomingApiKey = apiKey.trim();
    final shouldResetForNewKey =
        config.apiKey.isNotEmpty && incomingApiKey.isNotEmpty && config.apiKey != incomingApiKey;
    final effectiveReset = reset || shouldResetForNewKey;
    config = config.copyWith(apiKey: incomingApiKey);

    if (!config.hasApiKey) {
      throw const AppException('Ingresa una API key de Backboard antes de continuar.');
    }

    final threadIds =
        effectiveReset ? <BoardSection, String>{} : await _localDataSource.loadThreadIds();

    String? assistantId = effectiveReset ? null : config.assistantId;
    if (assistantId == null || assistantId.isEmpty) {
      final assistant = await _remoteDataSource.createAssistant(
        apiKey: config.apiKey,
        name: _assistantName,
        systemPrompt: _systemPrompt,
        tools: _toolkit.definitions,
      );
      assistantId = assistant.id;
    } else {
      await _remoteDataSource.updateAssistant(
        apiKey: config.apiKey,
        assistantId: assistantId,
        systemPrompt: _systemPrompt,
        tools: _toolkit.definitions,
      );
    }

    final freshThreadIds = <BoardSection, String>{...threadIds};
    for (final section in BoardSection.values) {
      if ((freshThreadIds[section] ?? '').isEmpty) {
        freshThreadIds[section] = await _remoteDataSource.createThread(
          apiKey: config.apiKey,
          assistantId: assistantId,
        );
      }
      await _localDataSource.saveThreadId(section, freshThreadIds[section]!);
    }

    config = config.copyWith(assistantId: assistantId);
    await _localDataSource.saveConfig(config);

    return _buildSnapshot(config.selectedSection);
  }

  @override
  Future<BoardWorkspaceSnapshot> selectSection(BoardSection section) async {
    final config = await _localDataSource.loadConfig();
    final updatedConfig = config.copyWith(selectedSection: section);
    await _localDataSource.saveConfig(updatedConfig);
    return _buildSnapshot(section);
  }

  @override
  Future<BoardWorkspaceSnapshot> updateSettings({
    MemoryMode? memoryMode,
    bool? webSearchEnabled,
    String? provider,
    String? model,
  }) async {
    final config = await _localDataSource.loadConfig();
    final updatedConfig = config.copyWith(
      memoryMode: memoryMode,
      webSearchEnabled: webSearchEnabled,
      provider: provider,
      model: model,
    );
    await _localDataSource.saveConfig(updatedConfig);
    return _buildSnapshot(updatedConfig.selectedSection);
  }

  @override
  Future<BoardWorkspaceSnapshot> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const AppException('Escribe algo antes de enviar.');
    }

    final config = await _localDataSource.loadConfig();
    if (!config.isConfigured) {
      throw const AppException('Primero crea o restaura un workspace.');
    }

    final threadIds = await _localDataSource.loadThreadIds();
    final threadId = threadIds[config.selectedSection];
    if (threadId == null || threadId.isEmpty) {
      throw const AppException('No existe thread para esta sección. Reconstruye el workspace.');
    }

    var response = await _remoteDataSource.addMessage(
      config: config,
      threadId: threadId,
      content: trimmed,
    );

    while (response.status == 'REQUIRES_ACTION' &&
        response.runId != null &&
        response.toolCalls.isNotEmpty) {
      final outputs = _toolkit.buildToolOutputs(response.toolCalls);
      response = await _remoteDataSource.submitToolOutputs(
        apiKey: config.apiKey,
        threadId: threadId,
        runId: response.runId!,
        toolOutputs: outputs,
      );
    }

    return _buildSnapshot(config.selectedSection);
  }

  @override
  Future<BoardWorkspaceSnapshot> uploadAssistantDocument(
    Uint8List bytes,
    String filename,
  ) async {
    final config = await _localDataSource.loadConfig();
    final assistantId = config.assistantId;

    if (!config.isConfigured || assistantId == null || assistantId.isEmpty) {
      throw const AppException('Crea el workspace antes de subir documentos.');
    }

    await _remoteDataSource.uploadDocumentToAssistant(
      apiKey: config.apiKey,
      assistantId: assistantId,
      bytes: bytes,
      filename: filename,
    );

    return _buildSnapshot(config.selectedSection);
  }

  @override
  Future<void> clearLocalWorkspace() {
    return _localDataSource.clearWorkspace();
  }

  Future<BoardWorkspaceSnapshot> _buildSnapshot(BoardSection activeSection) async {
    final config = await _localDataSource.loadConfig();
    if (!config.isConfigured) {
      return BoardWorkspaceSnapshot.empty(config.copyWith(selectedSection: activeSection));
    }

    final threadIds = await _localDataSource.loadThreadIds();
    final resolvedConfig = config.copyWith(selectedSection: activeSection);
    final activeThreadId = threadIds[activeSection];

    if (activeThreadId == null || activeThreadId.isEmpty) {
      throw const AppException('Falta el thread activo. Reconstruye el workspace.');
    }

    final activeThread = await _remoteDataSource.getThread(
      apiKey: resolvedConfig.apiKey,
      threadId: activeThreadId,
      section: activeSection,
    );

    final assistantId = resolvedConfig.assistantId!;
    final documents = await _loadDocuments(
      apiKey: resolvedConfig.apiKey,
      assistantId: assistantId,
    );

    await _localDataSource.saveConfig(resolvedConfig);

    return BoardWorkspaceSnapshot(
      config: resolvedConfig,
      threadIds: threadIds,
      activeThread: activeThread,
      documents: documents,
    );
  }

  Future<List<BackboardDocument>> _loadDocuments({
    required String apiKey,
    required String assistantId,
  }) async {
    final documents = await _remoteDataSource.listAssistantDocuments(
      apiKey: apiKey,
      assistantId: assistantId,
    );

    final refreshed = <BackboardDocument>[];
    for (final document in documents) {
      if (document.isReady || document.id.isEmpty) {
        refreshed.add(document);
        continue;
      }

      try {
        refreshed.add(
          await _remoteDataSource.getDocumentStatus(
            apiKey: apiKey,
            documentId: document.id,
          ),
        );
      } catch (_) {
        refreshed.add(document);
      }
    }

    refreshed.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return refreshed;
  }
}
