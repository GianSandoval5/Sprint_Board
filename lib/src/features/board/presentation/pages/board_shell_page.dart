import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/board_models.dart';
import '../controllers/board_controller.dart';
import '../controllers/board_state.dart';

class BoardShellPage extends ConsumerStatefulWidget {
  const BoardShellPage({super.key});

  @override
  ConsumerState<BoardShellPage> createState() => _BoardShellPageState();
}

class _BoardShellPageState extends ConsumerState<BoardShellPage> {
  final _apiKeyController = TextEditingController();
  final _messageController = TextEditingController();
  final _providerController = TextEditingController();
  final _modelController = TextEditingController();

  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(boardControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _messageController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boardControllerProvider);
    final controller = ref.read(boardControllerProvider.notifier);
    _syncControllers(state);

    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.scaffoldBackgroundColor,
              palette.surfaceAlt.withOpacity(0.74),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -70,
                left: -30,
                child: _GlowOrb(
                  color: palette.accent.withOpacity(0.18),
                  size: 220,
                ),
              ),
              Positioned(
                right: -60,
                top: 90,
                child: _GlowOrb(
                  color: palette.accentWarm.withOpacity(0.18),
                  size: 240,
                ),
              ),
              Positioned(
                bottom: -120,
                right: 120,
                child: _GlowOrb(
                  color: palette.shell.withOpacity(0.1),
                  size: 300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (!state.hasLoadedOnce && state.isInitializing) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final isWide = constraints.maxWidth >= 1120;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: state.needsSetup
                          ? _SetupView(
                              key: const ValueKey('setup'),
                              state: state,
                              apiKeyController: _apiKeyController,
                              obscureApiKey: _obscureApiKey,
                              onToggleObscure: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                              onBootstrap: () => controller.bootstrapWorkspace(
                                _apiKeyController.text,
                              ),
                              onRebuild: () => controller.bootstrapWorkspace(
                                _apiKeyController.text,
                                reset: true,
                              ),
                            )
                          : _buildBoardView(
                              context: context,
                              state: state,
                              controller: controller,
                              isWide: isWide,
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardView({
    required BuildContext context,
    required BoardState state,
    required BoardController controller,
    required bool isWide,
  }) {
    final thread = state.activeThread;
    final activeSection = state.config.selectedSection;

    final content = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 316,
                child: _BoardSidebar(
                  state: state,
                  onSectionSelected: controller.selectSection,
                  onResetWorkspace: () => controller.bootstrapWorkspace(
                    state.config.apiKey,
                    reset: true,
                  ),
                  onClearLocal: controller.clearLocalWorkspace,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _StatusStack(
                      errorMessage: state.errorMessage,
                      infoMessage: state.infoMessage,
                      onDismissError: controller.dismissError,
                      onDismissInfo: controller.dismissInfo,
                    ),
                    if (state.errorMessage != null || state.infoMessage != null)
                      const SizedBox(height: 16),
                    _SectionHero(
                      thread: thread,
                      documentsCount: state.documents.length,
                      onQuickPrompt: _insertPrompt,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _ConversationPanel(
                              state: state,
                              onPromptTap: _insertPrompt,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 330,
                            child: _ControlRail(
                              state: state,
                              providerController: _providerController,
                              modelController: _modelController,
                              onMemoryChanged: controller.updateMemoryMode,
                              onWebSearchChanged: controller.updateWebSearch,
                              onSaveModel: () => controller.updateModel(
                                provider: _providerController.text,
                                model: _modelController.text,
                              ),
                              onUpload: _pickAndUploadDocument,
                              onRefresh: () =>
                                  controller.selectSection(activeSection),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: <Widget>[
                _TopBar(
                  state: state,
                  onOpenControls: () => _openControlsSheet(context, state),
                  onReset: () => controller.bootstrapWorkspace(
                    state.config.apiKey,
                    reset: true,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusStack(
                  errorMessage: state.errorMessage,
                  infoMessage: state.infoMessage,
                  onDismissError: controller.dismissError,
                  onDismissInfo: controller.dismissInfo,
                ),
                if (state.errorMessage != null || state.infoMessage != null)
                  const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final section = BoardSection.values[index];
                      return _SectionTile(
                        section: section,
                        selected: section == activeSection,
                        compact: true,
                        messageCount: section == activeSection
                            ? thread.messages.length
                            : null,
                        onTap: () => controller.selectSection(section),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemCount: BoardSection.values.length,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHero(
                  thread: thread,
                  documentsCount: state.documents.length,
                  onQuickPrompt: _insertPrompt,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 420,
                  child: _ConversationPanel(
                    state: state,
                    onPromptTap: _insertPrompt,
                  ),
                ),
              ],
            ),
          );

    return Column(
      children: <Widget>[
        Expanded(child: content),
        const SizedBox(height: 16),
        _ComposerBar(
          controller: _messageController,
          isSending: state.isSending,
          isBusy: state.isInitializing || state.isUploading,
          onSend: _sendCurrentMessage,
        ),
      ],
    );
  }

  void _syncControllers(BoardState state) {
    if (_apiKeyController.text != state.config.apiKey) {
      _apiKeyController.text = state.config.apiKey;
    }
    if (_providerController.text != state.config.provider) {
      _providerController.text = state.config.provider;
    }
    if (_modelController.text != state.config.model) {
      _modelController.text = state.config.model;
    }
  }

  Future<void> _sendCurrentMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _messageController.clear();
    await ref.read(boardControllerProvider.notifier).sendMessage(text);
  }

  void _insertPrompt(String prompt) {
    _messageController
      ..text = prompt
      ..selection = TextSelection.collapsed(offset: prompt.length);
  }

  Future<void> _pickAndUploadDocument() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }

    await ref
        .read(boardControllerProvider.notifier)
        .uploadDocument(bytes, file.name);
  }

  Future<void> _openControlsSheet(BuildContext context, BoardState state) {
    final controller = ref.read(boardControllerProvider.notifier);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _ControlRail(
              state: state,
              providerController: _providerController,
              modelController: _modelController,
              onMemoryChanged: controller.updateMemoryMode,
              onWebSearchChanged: controller.updateWebSearch,
              onSaveModel: () => controller.updateModel(
                provider: _providerController.text,
                model: _modelController.text,
              ),
              onUpload: _pickAndUploadDocument,
              onRefresh: () =>
                  controller.selectSection(state.config.selectedSection),
              showAsSheet: true,
            ),
          ),
        );
      },
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    super.key,
    required this.state,
    required this.apiKeyController,
    required this.obscureApiKey,
    required this.onToggleObscure,
    required this.onBootstrap,
    required this.onRebuild,
  });

  final BoardState state;
  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscure;
  final VoidCallback onBootstrap;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        final hero = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'SprintBoard',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: isWide ? 68 : 52,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.shell,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Flutter x Backboard x hackathon execution',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Un board conversacional con memoria persistente, documentos RAG y tools para idea, frontend, backend, README y demo.',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: isWide ? 36 : 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'La app crea un assistant real en Backboard, levanta threads separados por carril y guarda el contexto local en Hive para reanudar rapido.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const <Widget>[
                _FeaturePill(
                  title: 'Shared memory',
                  caption: 'misma tesis en varios threads',
                ),
                _FeaturePill(
                  title: 'Document RAG',
                  caption: 'briefs, PDFs y notas',
                ),
                _FeaturePill(
                  title: 'Tool calls',
                  caption: 'task board, README, demo y rubric',
                ),
              ],
            ),
          ],
        );

        final form = Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Bootstrap', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'La key no se hardcodea. Se guarda solo en Hive local para esta instalacion y puedes reemplazarla despues.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: apiKeyController,
                  obscureText: obscureApiKey,
                  decoration: InputDecoration(
                    labelText: 'Backboard API key',
                    hintText: 'espr_...',
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscureApiKey
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _InlineChecklist(
                  items: const <String>[
                    'Crea un assistant con tools registradas.',
                    'Levanta 5 threads persistentes.',
                    'Activa memoria, web search y RAG de documentos.',
                  ],
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _Banner(
                    title: 'Error',
                    message: state.errorMessage!,
                    tone: BannerTone.error,
                  ),
                ],
                if (state.infoMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _Banner(
                    title: 'Info',
                    message: state.infoMessage!,
                    tone: BannerTone.info,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isInitializing ? null : onBootstrap,
                    icon: state.isInitializing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch_rounded),
                    label: const Text('Crear workspace'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isInitializing ? null : onRebuild,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reconstruir desde cero'),
                  ),
                ),
              ],
            ),
          ),
        );

        final child = isWide
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: hero,
                    ),
                  ),
                  Expanded(child: form),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[hero, const SizedBox(height: 20), form],
                ),
              );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        );
      },
    );
  }
}

class _BoardSidebar extends StatelessWidget {
  const _BoardSidebar({
    required this.state,
    required this.onSectionSelected,
    required this.onResetWorkspace,
    required this.onClearLocal,
  });

  final BoardState state;
  final ValueChanged<BoardSection> onSectionSelected;
  final VoidCallback onResetWorkspace;
  final VoidCallback onClearLocal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.shell,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SprintBoard',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Una sola app para pensar, decidir, documentar y grabar la demo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricCard(
                      label: 'Threads',
                      value: '${state.snapshot?.threadIds.length ?? 0}',
                      accent: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Docs',
                      value: '${state.documents.length}',
                      accent: palette.accentWarm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Carriles', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        final section = BoardSection.values[index];
                        return _SectionTile(
                          section: section,
                          selected: state.config.selectedSection == section,
                          messageCount: state.config.selectedSection == section
                              ? state.activeThread.messages.length
                              : null,
                          onTap: () => onSectionSelected(section),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemCount: BoardSection.values.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onResetWorkspace,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recrear workspace'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onClearLocal,
                    icon: const Icon(Icons.layers_clear_rounded),
                    label: const Text('Limpiar solo local'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHero extends StatelessWidget {
  const _SectionHero({
    required this.thread,
    required this.documentsCount,
    required this.onQuickPrompt,
  });

  final ConversationThread thread;
  final int documentsCount;
  final ValueChanged<String> onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    final shortId = thread.id.isEmpty ? 'new' : thread.id.substring(0, 8);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;

            final header = isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeroHeading(thread: thread),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ThreadBadge(shortId: shortId),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _SectionHeroHeading(thread: thread)),
                      const SizedBox(width: 18),
                      _ThreadBadge(shortId: shortId),
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                header,
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _ChipBadge(
                        icon: Icons.forum_rounded,
                        label: '${thread.messages.length} mensajes',
                      ),
                      _ChipBadge(
                        icon: Icons.description_rounded,
                        label: '$documentsCount documentos',
                      ),
                      const _ChipBadge(
                        icon: Icons.memory_rounded,
                        label: 'shared memory active',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Quick prompts',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.shellMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: thread.section.quickPrompts().map((prompt) {
                    final cardWidth = isCompact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3;
                    return SizedBox(
                      width: cardWidth.clamp(220.0, 320.0),
                      child: _PromptCard(
                        prompt: prompt,
                        compact: isCompact,
                        onTap: () => onQuickPrompt(prompt),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeroHeading extends StatelessWidget {
  const _SectionHeroHeading({required this.thread});

  final ConversationThread thread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${thread.section.label} lane',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.accentWarm,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          thread.section.label,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(thread.subtitle, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _ThreadBadge extends StatelessWidget {
  const _ThreadBadge({required this.shortId});

  final String shortId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text('thread', style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text('#$shortId', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.onTap,
    required this.compact,
  });

  final String prompt;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.surfaceAlt),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: palette.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Use prompt',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.accent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              prompt,
              maxLines: compact ? 6 : 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  'Insert into composer',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.shellMuted,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: palette.shell,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.state, required this.onPromptTap});

  final BoardState state;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    final messages = state.activeThread.messages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: messages.isEmpty
            ? _EmptyThread(
                section: state.config.selectedSection,
                onPromptTap: onPromptTap,
              )
            : ListView.separated(
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessageBubble(message: message);
                },
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemCount: messages.length,
              ),
      ),
    );
  }
}

class _ControlRail extends StatelessWidget {
  const _ControlRail({
    required this.state,
    required this.providerController,
    required this.modelController,
    required this.onMemoryChanged,
    required this.onWebSearchChanged,
    required this.onSaveModel,
    required this.onUpload,
    required this.onRefresh,
    this.showAsSheet = false,
  });

  final BoardState state;
  final TextEditingController providerController;
  final TextEditingController modelController;
  final ValueChanged<MemoryMode> onMemoryChanged;
  final ValueChanged<bool> onWebSearchChanged;
  final VoidCallback onSaveModel;
  final Future<void> Function() onUpload;
  final VoidCallback onRefresh;
  final bool showAsSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _RailCard(
            title: 'Runtime',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Memoria', style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                SegmentedButton<MemoryMode>(
                  multiSelectionEnabled: false,
                  showSelectedIcon: false,
                  segments: MemoryMode.values
                      .map(
                        (mode) => ButtonSegment<MemoryMode>(
                          value: mode,
                          label: Text(mode.label.replaceFirst('Memory ', '')),
                        ),
                      )
                      .toList(),
                  selected: <MemoryMode>{state.config.memoryMode},
                  onSelectionChanged: (selection) =>
                      onMemoryChanged(selection.first),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Web search'),
                  subtitle: const Text(
                    'Activa busqueda actual cuando el mensaje lo amerite.',
                  ),
                  value: state.config.webSearchEnabled,
                  onChanged: onWebSearchChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RailCard(
            title: 'Model routing',
            child: Column(
              children: <Widget>[
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(labelText: 'Provider'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSaveModel,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Guardar runtime'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RailCard(
            title: 'Documents',
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isUploading ? null : () => onUpload(),
                    icon: state.isUploading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: const Text('Subir contexto'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Actualizar'),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.documents.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Todavia no hay documentos compartidos en el assistant.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  Column(
                    children: state.documents
                        .map((document) => _DocumentTile(document: document))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (showAsSheet) {
      return Card(
        child: Padding(padding: const EdgeInsets.all(20), child: content),
      );
    }

    return content;
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.isSending,
    required this.isBusy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isBusy;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText:
                      'Pide una estrategia, resume un doc o haz que el assistant use una tool...',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onSend,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onOpenControls,
    required this.onReset,
  });

  final BoardState state;
  final VoidCallback onOpenControls;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.shell,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            'SprintBoard',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.24)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Recrear'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onOpenControls,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: palette.shell,
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Controles'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '${state.documents.length} docs • ${state.activeThread.messages.length} messages',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStack extends StatelessWidget {
  const _StatusStack({
    required this.errorMessage,
    required this.infoMessage,
    required this.onDismissError,
    required this.onDismissInfo,
  });

  final String? errorMessage;
  final String? infoMessage;
  final VoidCallback onDismissError;
  final VoidCallback onDismissInfo;

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null && infoMessage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        if (errorMessage != null)
          _Banner(
            title: 'Error',
            message: errorMessage!,
            tone: BannerTone.error,
            onDismiss: onDismissError,
          ),
        if (errorMessage != null && infoMessage != null)
          const SizedBox(height: 12),
        if (infoMessage != null)
          _Banner(
            title: 'Info',
            message: infoMessage!,
            tone: BannerTone.info,
            onDismiss: onDismissInfo,
          ),
      ],
    );
  }
}

enum BannerTone { error, info }

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.message,
    required this.tone,
    this.onDismiss,
  });

  final String title;
  final String message;
  final BannerTone tone;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    final background = tone == BannerTone.error
        ? const Color(0xFFFFE3E0)
        : palette.accent.withOpacity(0.12);
    final foreground = tone == BannerTone.error
        ? const Color(0xFF8A1C14)
        : palette.shell;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            tone == BannerTone.error
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: foreground),
            ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.messageCount,
  });

  final BoardSection section;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final int? messageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    final icon = switch (section) {
      BoardSection.idea => Icons.lightbulb_rounded,
      BoardSection.frontend => Icons.palette_rounded,
      BoardSection.backend => Icons.memory_rounded,
      BoardSection.readme => Icons.notes_rounded,
      BoardSection.demo => Icons.videocam_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: compact ? 180 : double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? palette.shell : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? palette.shell : palette.surfaceAlt,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: selected ? Colors.white : palette.shell),
                const Spacer(),
                if (messageCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.12)
                          : palette.surfaceAlt.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$messageCount',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? Colors.white : palette.shell,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              section.label,
              style: theme.textTheme.titleLarge?.copyWith(
                color: selected ? Colors.white : palette.shell,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.subtitle,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected
                    ? Colors.white.withOpacity(0.78)
                    : palette.shellMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final BackboardDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    final color = switch (document.status) {
      'indexed' => palette.success,
      'error' => const Color(0xFFB42318),
      _ => palette.accentWarm,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  document.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  document.status,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
            ],
          ),
          if ((document.summary ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              document.summary!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if ((document.statusMessage ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(document.statusMessage!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    final isUser = message.isUser;
    final isTool = message.isTool;
    final background = isUser
        ? palette.shell
        : isTool
        ? palette.accent.withOpacity(0.08)
        : Colors.white;
    final foreground = isUser ? Colors.white : palette.shell;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUser ? palette.shell : palette.surfaceAlt,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    isUser
                        ? 'You'
                        : isTool
                        ? 'Tool'
                        : 'SprintBoard',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const Spacer(),
                  if (message.timestamp != null)
                    Text(
                      DateFormat.Hm().format(message.timestamp!),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground.withOpacity(0.72),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message.content,
                style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
              ),
              if ((message.modelName ?? '').isNotEmpty ||
                  message.retrievedFilesCount > 0) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if ((message.modelName ?? '').isNotEmpty)
                      _InlineTag(
                        label:
                            '${message.modelProvider ?? ''} ${message.modelName ?? ''}'
                                .trim(),
                        foreground: foreground,
                        filled: isUser,
                      ),
                    if (message.retrievedFilesCount > 0)
                      _InlineTag(
                        label: '${message.retrievedFilesCount} docs',
                        foreground: foreground,
                        filled: isUser,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.section, required this.onPromptTap});

  final BoardSection section;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Este thread todavia no arranca.',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Empieza con una instruccion concreta o usa uno de estos disparadores.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: section
                  .quickPrompts()
                  .map(
                    (prompt) => ActionChip(
                      onPressed: () => onPromptTap(prompt),
                      label: Text(prompt),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(caption, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InlineChecklist extends StatelessWidget {
  const _InlineChecklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SprintBoardPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({
    required this.label,
    required this.foreground,
    required this.filled,
  });

  final String label;
  final Color foreground;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withOpacity(0.12)
            : foreground.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
