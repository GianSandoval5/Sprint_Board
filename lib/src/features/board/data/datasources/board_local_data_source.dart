import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/board_models.dart';

class BoardLocalDataSource {
  BoardLocalDataSource({
    Box<dynamic>? settingsBox,
    Box<dynamic>? workspaceBox,
  })  : _settingsBox = settingsBox ?? Hive.box<dynamic>(HiveBoxes.settings),
        _workspaceBox = workspaceBox ?? Hive.box<dynamic>(HiveBoxes.workspace);

  final Box<dynamic> _settingsBox;
  final Box<dynamic> _workspaceBox;

  Future<WorkspaceConfig> loadConfig() async {
    final raw = _settingsBox.get(HiveKeys.config);
    if (raw is Map) {
      return WorkspaceConfig.fromMap(Map<String, dynamic>.from(raw.cast<String, dynamic>()));
    }
    return WorkspaceConfig.empty();
  }

  Future<void> saveConfig(WorkspaceConfig config) async {
    await _settingsBox.put(HiveKeys.config, config.toMap());
  }

  Future<Map<BoardSection, String>> loadThreadIds() async {
    final result = <BoardSection, String>{};
    for (final section in BoardSection.values) {
      final value = _workspaceBox.get(section.key);
      if (value is String && value.isNotEmpty) {
        result[section] = value;
      }
    }
    return result;
  }

  Future<void> saveThreadId(BoardSection section, String threadId) async {
    await _workspaceBox.put(section.key, threadId);
  }

  Future<void> clearWorkspace() async {
    await _settingsBox.clear();
    await _workspaceBox.clear();
  }
}
