import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/board_models.dart';

class BackboardRemoteDataSource {
  BackboardRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AssistantProfile> createAssistant({
    required String apiKey,
    required String name,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
  }) async {
    final response = await _sendJson(
      apiKey: apiKey,
      method: 'POST',
      path: '/assistants',
      body: <String, dynamic>{
        'name': name,
        'system_prompt': systemPrompt,
        'tools': tools,
        'tok_k': 12,
      },
    );

    return AssistantProfile.fromJson(_asMap(response));
  }

  Future<void> updateAssistant({
    required String apiKey,
    required String assistantId,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
  }) async {
    await _sendJson(
      apiKey: apiKey,
      method: 'PUT',
      path: '/assistants/$assistantId',
      body: <String, dynamic>{
        'system_prompt': systemPrompt,
        'tools': tools,
        'tok_k': 12,
      },
    );
  }

  Future<String> createThread({
    required String apiKey,
    required String assistantId,
  }) async {
    final response = await _sendJson(
      apiKey: apiKey,
      method: 'POST',
      path: '/assistants/$assistantId/threads',
      body: const <String, dynamic>{},
    );

    final json = _asMap(response);
    return (json['thread_id'] ?? '') as String;
  }

  Future<ConversationThread> getThread({
    required String apiKey,
    required String threadId,
    required BoardSection section,
  }) async {
    final response = await _sendJson(
      apiKey: apiKey,
      method: 'GET',
      path: '/threads/$threadId',
    );

    final json = _asMap(response);
    final messages = _asList(json['messages'])
        .map((item) => ChatMessage.fromJson(_asMap(item)))
        .where((item) => item.content.trim().isNotEmpty)
        .toList();

    return ConversationThread(
      id: threadId,
      section: section,
      title: section.label,
      subtitle: section.subtitle,
      messages: messages,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Future<_RunResponse> addMessage({
    required WorkspaceConfig config,
    required String threadId,
    required String content,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'stream': false,
      'web_search': config.webSearchEnabled ? 'Auto' : 'off',
      'llm_provider': config.provider,
      'model_name': config.model,
      config.memoryMode.apiField: config.memoryMode.apiValue,
    };

    final response = await _sendJson(
      apiKey: config.apiKey,
      method: 'POST',
      path: '/threads/$threadId/messages',
      body: body,
    );

    return _RunResponse.fromJson(_asMap(response));
  }

  Future<_RunResponse> submitToolOutputs({
    required String apiKey,
    required String threadId,
    required String runId,
    required List<Map<String, String>> toolOutputs,
  }) async {
    final response = await _sendJson(
      apiKey: apiKey,
      method: 'POST',
      path: '/threads/$threadId/runs/$runId/submit-tool-outputs',
      body: <String, dynamic>{'tool_outputs': toolOutputs},
    );

    return _RunResponse.fromJson(_asMap(response));
  }

  Future<BackboardDocument> uploadDocumentToAssistant({
    required String apiKey,
    required String assistantId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _buildUri('/assistants/$assistantId/documents'),
    )
      ..headers.addAll(_headers(apiKey))
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: path.basename(filename),
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);

    return BackboardDocument.fromJson(_asMap(decoded));
  }

  Future<List<BackboardDocument>> listAssistantDocuments({
    required String apiKey,
    required String assistantId,
  }) async {
    final response = await _sendJson(
      apiKey: apiKey,
      method: 'GET',
      path: '/assistants/$assistantId/documents',
    );

    final list = response is List ? response : _asMap(response)['documents'];
    return _asList(list).map((item) => BackboardDocument.fromJson(_asMap(item))).toList();
  }

  Future<BackboardDocument> getDocumentStatus({
    required String apiKey,
    required String documentId,
  }) async {
    dynamic response;
    try {
      response = await _sendJson(
        apiKey: apiKey,
        method: 'GET',
        path: '/documents/$documentId/status',
      );
    } on AppException {
      response = await _sendJson(
        apiKey: apiKey,
        method: 'GET',
        path: '/documents/$documentId',
      );
    }

    return BackboardDocument.fromJson(_asMap(response));
  }

  Future<dynamic> _sendJson({
    required String apiKey,
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, _buildUri(path))
      ..headers.addAll(_headers(apiKey, json: true));

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Uri _buildUri(String path) {
    return Uri.parse('${AppConfig.baseUrl}$path');
  }

  Map<String, String> _headers(String apiKey, {bool json = false}) {
    return <String, String>{
      'Accept': 'application/json',
      'X-API-Key': apiKey,
      if (json) 'Content-Type': 'application/json',
    };
  }

  dynamic _decode(http.Response response) {
    final text = response.body.trim();
    final decoded = text.isEmpty ? const <String, dynamic>{} : _tryDecodeJson(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(_extractError(decoded, response.statusCode));
    }

    return decoded;
  }

  dynamic _tryDecodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{'message': text};
    }
  }

  String _extractError(dynamic decoded, int statusCode) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      final detail = map['detail'] ?? map['message'] ?? map['error'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    }

    return 'Backboard request failed with status $statusCode.';
  }
}

class _RunResponse {
  const _RunResponse({
    required this.status,
    required this.toolCalls,
    this.runId,
  });

  factory _RunResponse.fromJson(Map<String, dynamic> json) {
    return _RunResponse(
      status: (json['status'] ?? 'COMPLETED') as String,
      runId: json['run_id'] as String?,
      toolCalls: _asList(json['tool_calls'])
          .map((item) => ToolCallRequest.fromJson(_asMap(item)))
          .toList(),
    );
  }

  final String status;
  final String? runId;
  final List<ToolCallRequest> toolCalls;
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw.cast<String, dynamic>());
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(Object? raw) {
  if (raw is List) {
    return raw;
  }
  return const <dynamic>[];
}

DateTime? _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal();
  }
  return null;
}
