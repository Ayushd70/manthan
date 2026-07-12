import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/prompts/application/prompt_library_controller.dart';
import 'package:manthan/features/prompts/domain/saved_prompt.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// Manages reusable saved system prompts and lets the user apply one to the
/// active generation config.
class PromptLibraryPage extends ConsumerWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promptLibraryControllerProvider);
    final controller = ref.read(promptLibraryControllerProvider.notifier);
    final activePrompt = ref.watch(
      settingsProvider.select((s) => s.generationConfig.systemPrompt),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Prompt library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New prompt'),
      ),
      body: state.prompts.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: <Widget>[
                for (final prompt in state.prompts)
                  _PromptCard(
                    prompt: prompt,
                    isActive: activePrompt == prompt.content,
                    onUse: () => _apply(context, ref, prompt),
                    onEdit: () => _showEditor(context, ref, prompt: prompt),
                    onDelete: () => _confirmDelete(context, controller, prompt),
                  ),
              ],
            ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    SavedPrompt prompt,
  ) async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .setGenerationConfig(
          settings.generationConfig.copyWith(systemPrompt: prompt.content),
        );
    await ref.read(engineControllerProvider.notifier).reloadActive();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied "${prompt.title}"')),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    SavedPrompt? prompt,
  }) async {
    final titleController = TextEditingController(text: prompt?.title);
    final contentController = TextEditingController(text: prompt?.content);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prompt == null ? 'New prompt' : 'Edit prompt'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'System prompt',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved ?? false) {
      final controller = ref.read(promptLibraryControllerProvider.notifier);
      if (prompt == null) {
        controller.addPrompt(
          title: titleController.text,
          content: contentController.text,
        );
      } else {
        controller.updatePrompt(
          prompt,
          title: titleController.text,
          content: contentController.text,
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PromptLibraryController controller,
    SavedPrompt prompt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${prompt.title}"?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.deletePrompt(prompt.id);
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.isActive,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedPrompt prompt;
  final bool isActive;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(prompt.title, style: theme.textTheme.titleMedium),
                ),
                if (isActive)
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              prompt.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.relativeTime(prompt.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: isActive ? null : onUse,
                  icon: const Icon(Icons.bolt),
                  label: Text(isActive ? 'In use' : 'Use'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Save your favorite instructions',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create reusable system prompts — like "concise coding '
              'assistant" or "friendly tutor" — and apply them in one tap.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
