import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_board/src/features/board/data/services/sprint_board_toolkit.dart';
import 'package:sprint_board/src/features/board/domain/entities/board_models.dart';

void main() {
  group('SprintBoardToolkit', () {
    const toolkit = SprintBoardToolkit();

    test('returns README markdown when generate_readme is requested', () {
      final outputs = toolkit.buildToolOutputs(
        const <ToolCallRequest>[
          ToolCallRequest(
            id: 'tool-1',
            name: 'generate_readme',
            arguments: <String, dynamic>{
              'project_name': 'SprintBoard',
              'features': <String>['shared memory', 'tool calls'],
            },
          ),
        ],
      );

      expect(outputs, hasLength(1));
      expect(outputs.first['tool_call_id'], 'tool-1');

      final payload = jsonDecode(outputs.first['output']!) as Map<String, dynamic>;
      expect(payload['title'], 'SprintBoard');
      expect((payload['markdown'] as String), contains('# SprintBoard'));
      expect((payload['markdown'] as String), contains('shared memory'));
    });

    test('returns rubric scores when score_against_rubric is requested', () {
      final outputs = toolkit.buildToolOutputs(
        const <ToolCallRequest>[
          ToolCallRequest(
            id: 'tool-2',
            name: 'score_against_rubric',
            arguments: <String, dynamic>{
              'summary':
                  'Memory-first hackathon board with shared threads, RAG and tool calls.',
              'category': 'useful',
            },
          ),
        ],
      );

      final payload = jsonDecode(outputs.first['output']!) as Map<String, dynamic>;
      final scores = payload['scores'] as List<dynamic>;

      expect(scores, isNotEmpty);
      expect(
        scores.any((entry) => (entry as Map<String, dynamic>)['criterion'] == 'Backboard integration'),
        isTrue,
      );
    });
  });
}
