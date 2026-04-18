import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/board/presentation/pages/board_shell_page.dart';

class SprintBoardApp extends StatelessWidget {
  const SprintBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SprintBoard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const BoardShellPage(),
    );
  }
}
