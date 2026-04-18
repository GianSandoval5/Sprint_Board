import 'dart:convert';

import '../../../../core/config/app_config.dart';

enum BoardSection {
  idea(
    key: 'idea',
    label: 'Idea',
    subtitle: 'Aterriza la tesis, el wow factor y el fit con la categoría.',
  ),
  frontend(
    key: 'frontend',
    label: 'Frontend',
    subtitle: 'Pulir UX, pantallas clave y el diseño de la demo.',
  ),
  backend(
    key: 'backend',
    label: 'Backend',
    subtitle: 'Resolver integraciones, datos y arquitectura técnica.',
  ),
  readme(
    key: 'readme',
    label: 'README',
    subtitle: 'Transformar el trabajo en una historia clara y publicable.',
  ),
  demo(
    key: 'demo',
    label: 'Demo',
    subtitle: 'Preparar narrativa, pacing y la grabación final.',
  );

  const BoardSection({
    required this.key,
    required this.label,
    required this.subtitle,
  });

  final String key;
  final String label;
  final String subtitle;

  static BoardSection fromKey(String? value) {
    return BoardSection.values.firstWhere(
      (section) => section.key == value,
      orElse: () => BoardSection.idea,
    );
  }

  List<String> quickPrompts() {
    switch (this) {
      case BoardSection.idea:
        return const [
          'Resume el challenge, propón 3 ideas y recomienda una.',
          'Usa la tool create_task_board para convertir la idea elegida en entregables.',
          'Usa la tool score_against_rubric para evaluar si esta idea puede ganar.',
        ];
      case BoardSection.frontend:
        return const [
          'Define la experiencia mobile-first y el flujo crítico de la app.',
          'Desglosa la pantalla principal en componentes con prioridades.',
          'Propón mejoras visuales para que la demo se vea premium.',
        ];
      case BoardSection.backend:
        return const [
          'Explica cómo usar Backboard aquí con threads, memoria, RAG y tools.',
          'Enumera riesgos técnicos y mitigaciones para una hackathon de una semana.',
          'Diseña el contrato de datos entre UI, almacenamiento local y API.',
        ];
      case BoardSection.readme:
        return const [
          'Usa la tool generate_readme para armar un README profesional.',
          'Escribe la sección de arquitectura y por qué Backboard fue clave.',
          'Redacta instrucciones high-level para correr el proyecto.',
        ];
      case BoardSection.demo:
        return const [
          'Usa la tool build_demo_script para un guion de 150 segundos.',
          'Crea una checklist final para grabar la demo sin huecos.',
          'Resume el pitch en 5 frases contundentes.',
        ];
    }
  }
}

enum MemoryMode {
  off(label: 'Memory Off'),
  lite(label: 'Memory Lite'),
  pro(label: 'Memory Pro');

  const MemoryMode({required this.label});

  final String label;

  String get apiField => this == MemoryMode.pro ? 'memory_pro' : 'memory';

  String get apiValue => switch (this) {
        MemoryMode.off => 'off',
        MemoryMode.lite => 'Auto',
        MemoryMode.pro => 'Auto',
      };

  static MemoryMode fromStorage(String? value) {
    return MemoryMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => MemoryMode.lite,
    );
  }
}

class WorkspaceConfig {
  const WorkspaceConfig({
    required this.apiKey,
    required this.selectedSection,
    required this.memoryMode,
    required this.webSearchEnabled,
    required this.provider,
    required this.model,
    this.assistantId,
  });

  factory WorkspaceConfig.empty() {
    return WorkspaceConfig(
      apiKey: AppConfig.preloadedApiKey,
      selectedSection: BoardSection.idea,
      memoryMode: MemoryMode.lite,
      webSearchEnabled: true,
      provider: AppConfig.defaultProvider,
      model: AppConfig.defaultModel,
    );
  }

  factory WorkspaceConfig.fromMap(Map<String, dynamic> map) {
    final fallback = WorkspaceConfig.empty();
    return WorkspaceConfig(
      apiKey: (map['apiKey'] as String?)?.trim().isNotEmpty == true
          ? (map['apiKey'] as String).trim()
          : fallback.apiKey,
      assistantId: (map['assistantId'] as String?)?.trim(),
      selectedSection: BoardSection.fromKey(map['selectedSection'] as String?),
      memoryMode: MemoryMode.fromStorage(map['memoryMode'] as String?),
      webSearchEnabled: map['webSearchEnabled'] as bool? ?? true,
      provider: (map['provider'] as String?)?.trim().isNotEmpty == true
          ? (map['provider'] as String).trim()
          : AppConfig.defaultProvider,
      model: (map['model'] as String?)?.trim().isNotEmpty == true
          ? (map['model'] as String).trim()
          : AppConfig.defaultModel,
    );
  }

  final String apiKey;
  final String? assistantId;
  final BoardSection selectedSection;
  final MemoryMode memoryMode;
  final bool webSearchEnabled;
  final String provider;
  final String model;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'assistantId': assistantId,
      'selectedSection': selectedSection.key,
      'memoryMode': memoryMode.name,
      'webSearchEnabled': webSearchEnabled,
      'provider': provider,
      'model': model,
    };
  }

  WorkspaceConfig copyWith({
    String? apiKey,
    String? assistantId,
    bool clearAssistantId = false,
    BoardSection? selectedSection,
    MemoryMode? memoryMode,
    bool? webSearchEnabled,
    String? provider,
    String? model,
  }) {
    return WorkspaceConfig(
      apiKey: apiKey ?? this.apiKey,
      assistantId: clearAssistantId ? null : assistantId ?? this.assistantId,
      selectedSection: selectedSection ?? this.selectedSection,
      memoryMode: memoryMode ?? this.memoryMode,
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      provider: provider ?? this.provider,
      model: model ?? this.model,
    );
  }

  bool get hasApiKey => apiKey.trim().isNotEmpty;
  bool get isConfigured => hasApiKey && (assistantId?.isNotEmpty ?? false);
}

class AssistantProfile {
  const AssistantProfile({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? systemPrompt;
  final DateTime? createdAt;

  factory AssistantProfile.fromJson(Map<String, dynamic> json) {
    return AssistantProfile(
      id: (json['assistant_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? 'SprintBoard') as String,
      systemPrompt: json['system_prompt'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.messages,
    this.createdAt,
  });

  factory ConversationThread.placeholder(BoardSection section) {
    return ConversationThread(
      id: '',
      section: section,
      title: section.label,
      subtitle: section.subtitle,
      messages: const <ChatMessage>[],
    );
  }

  final String id;
  final BoardSection section;
  final String title;
  final String subtitle;
  final List<ChatMessage> messages;
  final DateTime? createdAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.status,
    this.timestamp,
    this.modelProvider,
    this.modelName,
    this.retrievedFilesCount = 0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['message_id'] ?? json['id'] ?? '') as String,
      role: (json['role'] ?? 'assistant') as String,
      content: _extractContent(json['content']),
      status: (json['status'] ?? 'COMPLETED') as String,
      timestamp: _parseDate(json['timestamp'] ?? json['created_at']),
      modelProvider: json['model_provider'] as String?,
      modelName: json['model_name'] as String?,
      retrievedFilesCount: (json['retrieved_files_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String role;
  final String content;
  final String status;
  final DateTime? timestamp;
  final String? modelProvider;
  final String? modelName;
  final int retrievedFilesCount;

  bool get isUser => role == 'user';
  bool get isTool => role == 'tool';
}

class ToolCallRequest {
  const ToolCallRequest({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCallRequest.fromJson(Map<String, dynamic> json) {
    final function = Map<String, dynamic>.from(
      (json['function'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    );
    final rawArguments = function['arguments'];

    return ToolCallRequest(
      id: (json['id'] ?? json['tool_call_id'] ?? '') as String,
      name: (function['name'] ?? 'unknown_tool') as String,
      arguments: _parseArguments(rawArguments),
    );
  }

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class BackboardDocument {
  const BackboardDocument({
    required this.id,
    required this.filename,
    required this.status,
    this.summary,
    this.statusMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory BackboardDocument.fromJson(Map<String, dynamic> json) {
    return BackboardDocument(
      id: (json['document_id'] ?? json['id'] ?? '') as String,
      filename: (json['filename'] ?? 'document') as String,
      status: (json['status'] ?? 'pending') as String,
      summary: json['summary'] as String?,
      statusMessage: json['status_message'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  final String id;
  final String filename;
  final String status;
  final String? summary;
  final String? statusMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReady => status == 'indexed';
}

class BoardWorkspaceSnapshot {
  const BoardWorkspaceSnapshot({
    required this.config,
    required this.threadIds,
    required this.activeThread,
    required this.documents,
  });

  factory BoardWorkspaceSnapshot.empty(WorkspaceConfig config) {
    return BoardWorkspaceSnapshot(
      config: config,
      threadIds: const <BoardSection, String>{},
      activeThread: ConversationThread.placeholder(config.selectedSection),
      documents: const <BackboardDocument>[],
    );
  }

  final WorkspaceConfig config;
  final Map<BoardSection, String> threadIds;
  final ConversationThread activeThread;
  final List<BackboardDocument> documents;
}

DateTime? _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal();
  }
  return null;
}

String _extractContent(Object? raw) {
  if (raw == null) {
    return '';
  }

  if (raw is String) {
    return raw;
  }

  if (raw is List) {
    return raw.map(_extractContent).where((value) => value.isNotEmpty).join('\n');
  }

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    final direct = map['text'] ?? map['content'] ?? map['value'];
    if (direct != null) {
      return _extractContent(direct);
    }
    return jsonEncode(map);
  }

  return raw.toString();
}

Map<String, dynamic> _parseArguments(Object? rawArguments) {
  if (rawArguments is Map) {
    return Map<String, dynamic>.from(rawArguments.cast<String, dynamic>());
  }

  if (rawArguments is String && rawArguments.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawArguments);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  return const <String, dynamic>{};
}
