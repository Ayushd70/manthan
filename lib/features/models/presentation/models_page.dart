import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/models/application/models_controller.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_download.dart';
import 'package:manthan/features/models/domain/model_info.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// Catalog of on-device models with download and activation controls.
class ModelsPage extends ConsumerWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(modelsControllerProvider);
    final activeModelId = ref.watch(
      settingsProvider.select((s) => s.activeModelId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(modelsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: <Widget>[
          const _IntroCard(),
          const SizedBox(height: 8),
          for (final model in ModelCatalog.all)
            _ModelTile(
              model: model,
              download: downloads[model.id] ?? ModelDownload(modelId: model.id),
              isActive: activeModelId == model.id,
            ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Models download once and run entirely offline. Some weights '
                'are gated — add a Hugging Face token in Settings if a '
                'download is denied.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends ConsumerWidget {
  const _ModelTile({
    required this.model,
    required this.download,
    required this.isActive,
  });

  final ModelInfo model;
  final ModelDownload download;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(modelsControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(model.name, style: theme.textTheme.titleMedium),
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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _Tag(model.engineKind.label),
                if (model.parameterLabel.isNotEmpty) _Tag(model.parameterLabel),
                if (model.quantization.isNotEmpty) _Tag(model.quantization),
                if (model.supportsVision) const _Tag('Vision'),
                _Tag(Formatters.bytes(model.sizeBytes)),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            _buildAction(context, ref, controller, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    WidgetRef ref,
    ModelsController controller,
    ThemeData theme,
  ) {
    switch (download.status) {
      case ModelDownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(value: download.progress),
                ),
                const SizedBox(width: 12),
                Text(
                  download.progress != null
                      ? '${(download.progress! * 100).toStringAsFixed(0)}%'
                      : Formatters.bytes(download.receivedBytes),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => controller.cancel(model.id),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
          ],
        );
      case ModelDownloadStatus.downloaded:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton.icon(
              onPressed: () => _confirmDelete(context, controller),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isActive ? null : () => _activate(ref),
              icon: const Icon(Icons.bolt),
              label: Text(isActive ? 'In use' : 'Use'),
            ),
          ],
        );
      case ModelDownloadStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              download.error ?? 'Download failed',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => controller.download(model),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        );
      case ModelDownloadStatus.notDownloaded:
        return Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => controller.download(model),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        );
    }
  }

  Future<void> _activate(WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).setActiveModel(model.id);
    await ref.read(engineControllerProvider.notifier).activate(model.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ModelsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: const Text('The model file will be removed from this device.'),
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
    if (confirmed ?? false) await controller.delete(model);
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
