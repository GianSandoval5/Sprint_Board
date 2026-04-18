import '../../domain/entities/board_models.dart';

class BoardState {
  const BoardState({
    required this.config,
    required this.snapshot,
    required this.isInitializing,
    required this.isSending,
    required this.isUploading,
    required this.errorMessage,
    required this.infoMessage,
    required this.hasLoadedOnce,
  });

  factory BoardState.initial() {
    return BoardState(
      config: WorkspaceConfig.empty(),
      snapshot: null,
      isInitializing: false,
      isSending: false,
      isUploading: false,
      errorMessage: null,
      infoMessage: null,
      hasLoadedOnce: false,
    );
  }

  final WorkspaceConfig config;
  final BoardWorkspaceSnapshot? snapshot;
  final bool isInitializing;
  final bool isSending;
  final bool isUploading;
  final String? errorMessage;
  final String? infoMessage;
  final bool hasLoadedOnce;

  BoardState copyWith({
    WorkspaceConfig? config,
    BoardWorkspaceSnapshot? snapshot,
    bool clearSnapshot = false,
    bool? isInitializing,
    bool? isSending,
    bool? isUploading,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    bool? hasLoadedOnce,
  }) {
    return BoardState(
      config: config ?? this.config,
      snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  bool get needsSetup => !config.isConfigured || snapshot == null;

  ConversationThread get activeThread =>
      snapshot?.activeThread ?? ConversationThread.placeholder(config.selectedSection);

  List<BackboardDocument> get documents => snapshot?.documents ?? const <BackboardDocument>[];
}
