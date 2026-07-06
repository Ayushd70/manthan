import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/rag/application/rag_controller.dart';

/// Manages documents imported for retrieval-augmented generation.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ragControllerProvider);
    final controller = ref.read(ragControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: <Widget>[
          if (state.documents.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: controller.clearAll,
            ),
        ],
      ),
      floatingActionButton: state.isIndexing
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showImportSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add document'),
            ),
      body: Column(
        children: <Widget>[
          if (state.isIndexing) _IndexingBar(label: state.indexingLabel),
          Expanded(
            child: state.documents.isEmpty
                ? const _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                    children: <Widget>[
                      Card(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.hub_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${state.documents.length} documents · '
                                  '${state.chunkCount} indexed chunks · '
                                  '${state.isUsingMockEmbedder ? 'mock' : 'semantic'} '
                                  'search. Toggle document grounding in a chat '
                                  'to ask questions about them.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final doc in state.documents)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(doc.title),
                            subtitle: Text(
                              '${doc.chunkCount} chunks · '
                              '${Formatters.bytes(doc.charCount)} · '
                              '${Formatters.relativeTime(doc.addedAt)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  controller.removeDocument(doc.id),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import text file'),
              subtitle: const Text('.txt or .md'),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(_importFile(context, ref));
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Paste text'),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(_pasteText(context, ref));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['txt', 'md', 'markdown', 'text'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    await ref
        .read(ragControllerProvider.notifier)
        .importText(title: file.name, text: text);
  }

  Future<void> _pasteText(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste document'),
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
                controller: bodyController,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Content',
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (submitted ?? false) {
      final title = titleController.text.trim().isEmpty
          ? 'Pasted note'
          : titleController.text.trim();
      await ref
          .read(ragControllerProvider.notifier)
          .importText(title: title, text: bodyController.text);
    }
  }
}

class _IndexingBar extends StatelessWidget {
  const _IndexingBar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              label.isEmpty ? 'Indexing…' : label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
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
              Icons.hub_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with your documents',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Import notes or text files. Manthan splits, embeds, and indexes '
              'them on-device so you can ask grounded questions — all offline.',
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
