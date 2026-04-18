import 'dart:convert';

import '../../domain/entities/board_models.dart';

class SprintBoardToolkit {
  const SprintBoardToolkit();

  List<Map<String, dynamic>> get definitions => const <Map<String, dynamic>>[
        {
          'type': 'function',
          'function': {
            'name': 'create_task_board',
            'description': 'Break a hackathon goal into lanes, deliverables, and a crisp execution plan.',
            'parameters': {
              'type': 'object',
              'properties': {
                'goal': {
                  'type': 'string',
                  'description': 'One-sentence outcome the team is chasing.',
                },
                'deliverables': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Concrete things the team must ship.',
                },
                'days_left': {
                  'type': 'integer',
                  'description': 'Number of days left in the hackathon.',
                },
              },
              'required': ['goal'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'score_against_rubric',
            'description': 'Score an idea against hackathon judging criteria and highlight the gaps.',
            'parameters': {
              'type': 'object',
              'properties': {
                'summary': {
                  'type': 'string',
                  'description': 'Short description of the project.',
                },
                'category': {
                  'type': 'string',
                  'description': 'Category or lens such as useful, creative, weird, or polished.',
                },
              },
              'required': ['summary'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'generate_readme',
            'description': 'Generate a README draft with architecture, setup, and Backboard integration.',
            'parameters': {
              'type': 'object',
              'properties': {
                'project_name': {
                  'type': 'string',
                  'description': 'Public project name.',
                },
                'problem': {
                  'type': 'string',
                  'description': 'Problem being solved.',
                },
                'solution': {
                  'type': 'string',
                  'description': 'How the product solves it.',
                },
                'features': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Key features to highlight.',
                },
                'stack': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Technologies used.',
                },
              },
              'required': ['project_name'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'build_demo_script',
            'description': 'Create a demo script with pacing, talking points, and closing line.',
            'parameters': {
              'type': 'object',
              'properties': {
                'project_name': {
                  'type': 'string',
                  'description': 'Public project name.',
                },
                'core_flow': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Ordered list of scenes or product moments.',
                },
                'duration_seconds': {
                  'type': 'integer',
                  'description': 'Target demo duration.',
                },
              },
              'required': ['project_name'],
            },
          },
        },
      ];

  List<Map<String, String>> buildToolOutputs(List<ToolCallRequest> toolCalls) {
    return toolCalls
        .map(
          (toolCall) => <String, String>{
            'tool_call_id': toolCall.id,
            'output': _dispatch(toolCall.name, toolCall.arguments),
          },
        )
        .toList();
  }

  String _dispatch(String name, Map<String, dynamic> args) {
    switch (name) {
      case 'create_task_board':
        return jsonEncode(_createTaskBoard(args));
      case 'score_against_rubric':
        return jsonEncode(_scoreAgainstRubric(args));
      case 'generate_readme':
        return jsonEncode(_generateReadme(args));
      case 'build_demo_script':
        return jsonEncode(_buildDemoScript(args));
      default:
        return jsonEncode(<String, dynamic>{
          'error': 'Unsupported tool requested.',
          'tool': name,
        });
    }
  }

  Map<String, dynamic> _createTaskBoard(Map<String, dynamic> args) {
    final goal = (args['goal'] as String?)?.trim().isNotEmpty == true
        ? (args['goal'] as String).trim()
        : 'Ship a convincing hackathon prototype';
    final deliverables = _stringList(args['deliverables']);
    final daysLeft = (args['days_left'] as num?)?.toInt() ?? 7;
    final outputs = deliverables.isEmpty
        ? <String>[
            'working prototype',
            'demo-ready README',
            '2-3 minute recorded walkthrough',
          ]
        : deliverables;

    return <String, dynamic>{
      'goal': goal,
      'lanes': <Map<String, dynamic>>[
        {
          'lane': 'Today',
          'focus': 'Lock the highest-leverage version of the idea and cut anything ornamental.',
          'tasks': <String>[
            'Define what must be true for the demo to feel inevitable.',
            'Confirm the Backboard features being showcased.',
          ],
        },
        {
          'lane': 'Build',
          'focus': 'Turn the core flow into something demo-safe and repeatable.',
          'tasks': outputs.map((item) => 'Ship $item').toList(),
        },
        {
          'lane': 'Polish',
          'focus': 'Reduce friction, rehearse the flow, and tighten narrative clarity.',
          'tasks': <String>[
            'Dry-run the script twice.',
            'Check README against the recorded demo.',
            'Prepare fallback screenshots in case live data misbehaves.',
          ],
        },
      ],
      'timeline': 'Use $daysLeft days as a cap, not as permission to expand scope.',
      'red_flags': const <String>[
        'Too many user paths for a short demo.',
        'Critical dependencies with no fallback.',
        'README that promises features the product does not visibly prove.',
      ],
    };
  }

  Map<String, dynamic> _scoreAgainstRubric(Map<String, dynamic> args) {
    final summary = (args['summary'] as String?)?.trim() ?? '';
    final category = (args['category'] as String?)?.trim() ?? 'useful';
    final lengthSignal = summary.length;

    final functionality = lengthSignal > 140 ? 9 : 7;
    final backboard = summary.toLowerCase().contains('memory') ||
            summary.toLowerCase().contains('thread') ||
            summary.toLowerCase().contains('rag')
        ? 9
        : 6;
    final clarity = lengthSignal > 90 ? 8 : 6;
    final fit = category.toLowerCase().contains('creative') ? 8 : 9;

    return <String, dynamic>{
      'category': category,
      'scores': <Map<String, dynamic>>[
        {'criterion': 'Functionality', 'score': functionality, 'out_of': 10},
        {'criterion': 'Backboard integration', 'score': backboard, 'out_of': 10},
        {'criterion': 'Clarity', 'score': clarity, 'out_of': 10},
        {'criterion': 'Category fit', 'score': fit, 'out_of': 10},
      ],
      'verdict':
          'Strong submissions show a visible product loop, explicit Backboard statefulness, and a README/demo that match exactly.',
      'fix_next': const <String>[
        'Name the one moment where Backboard changes the product outcome.',
        'Show shared memory across threads instead of only one chat pane.',
        'Keep the demo short enough that every screen matters.',
      ],
    };
  }

  Map<String, dynamic> _generateReadme(Map<String, dynamic> args) {
    final name = (args['project_name'] as String?)?.trim().isNotEmpty == true
        ? (args['project_name'] as String).trim()
        : 'SprintBoard';
    final problem = (args['problem'] as String?)?.trim().isNotEmpty == true
        ? (args['problem'] as String).trim()
        : 'Hackathon teams lose context, docs, and execution focus under time pressure.';
    final solution = (args['solution'] as String?)?.trim().isNotEmpty == true
        ? (args['solution'] as String).trim()
        : 'A memory-first mobile copilot that turns conversations and uploaded docs into decisions, tasks, README material, and a demo script.';
    final features = _stringList(args['features']);
    final stack = _stringList(args['stack']);

    return <String, dynamic>{
      'title': name,
      'markdown': '''
# $name

## Why it exists
$problem

## What it does
$solution

## Core features
${features.isEmpty ? '- Persistent multi-thread planning\n- Shared project memory\n- Backboard document context\n- Built-in task, README, rubric, and demo helpers' : features.map((item) => '- $item').join('\n')}

## Built with
${stack.isEmpty ? '- Flutter\n- Backboard API\n- Hive\n- Riverpod' : stack.map((item) => '- $item').join('\n')}

## Why Backboard matters here
- Threads split the workstream into idea, frontend, backend, README, and demo lanes.
- Shared memory keeps the project thesis consistent across those lanes.
- Document uploads add fast RAG over briefs, specs, and notes.
- Tool calls turn the assistant into an execution copilot instead of a plain chatbot.

## Run
1. Add a Backboard API key.
2. Bootstrap the workspace.
3. Upload your challenge brief or notes.
4. Use each lane to shape the project and export the story.
''',
    };
  }

  Map<String, dynamic> _buildDemoScript(Map<String, dynamic> args) {
    final name = (args['project_name'] as String?)?.trim().isNotEmpty == true
        ? (args['project_name'] as String).trim()
        : 'SprintBoard';
    final duration = (args['duration_seconds'] as num?)?.toInt() ?? 150;
    final flow = _stringList(args['core_flow']);

    return <String, dynamic>{
      'project_name': name,
      'duration_seconds': duration,
      'beats': <Map<String, dynamic>>[
        {
          'label': 'Hook',
          'seconds': 20,
          'script': 'Hackathon teams drown in tabs, notes, and last-minute context switching. $name keeps the whole sprint in one memory-first board.',
        },
        {
          'label': 'Core flow',
          'seconds': 80,
          'script': flow.isEmpty
              ? 'Show uploading the brief, asking for the winning concept, switching threads, and proving that memory survives the transition.'
              : flow.join(' Then '),
        },
        {
          'label': 'Backboard proof',
          'seconds': 30,
          'script': 'Call out the exact Backboard primitives on screen: assistant, threads, memory, document retrieval, and tool-calls.',
        },
        {
          'label': 'Close',
          'seconds': 20,
          'script': '$name does not just chat. It turns a messy hackathon into a coherent shipping loop.',
        },
      ],
      'recording_notes': const <String>[
        'Keep the cursor moving with intent.',
        'Do not read the UI verbatim; narrate outcomes.',
        'End on the one sentence judges should remember.',
      ],
    };
  }

  List<String> _stringList(Object? raw) {
    if (raw is List) {
      return raw.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    return const <String>[];
  }
}
