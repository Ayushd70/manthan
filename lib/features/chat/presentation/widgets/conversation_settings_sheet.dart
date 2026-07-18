import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/features/chat/application/chat_controller.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/models/application/models_controller.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_download.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/shared/widgets/labeled_slider.dart';

/// Opens the per-conversation model pin + generation preset editor.
Future<void> showConversationSettingsSheet(
  BuildContext context, {
  required ChatSession session,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ConversationSettingsSheet(session: session),
  );
}

class _ConversationSettingsSheet extends ConsumerWidget {
  const _ConversationSettingsSheet({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(chatControllerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final downloads = ref.watch(modelsControllerProvider);
    final activeSession = ref.watch(chatControllerProvider).active;
    final active = (activeSession?.id == session.id) ? activeSession! : session;

    final downloadedModels = ModelCatalog.all
        .where((m) => downloads[m.id]?.status == ModelDownloadStatus.downloaded)
        .toList(growable: false);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              Text(
                'Conversation settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Overrides apply only to this chat.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Model'),
              RadioGroup<String?>(
                groupValue: active.modelId,
                onChanged: controller.pinModel,
                child: Column(
                  children: <Widget>[
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use default'),
                      subtitle: Text(
                        _defaultModelLabel(settings.activeModelId),
                      ),
                      value: null,
                    ),
                    for (final model in downloadedModels)
                      RadioListTile<String?>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(model.name),
                        subtitle: Text(
                          '${model.parameterLabel} · ${model.quantization}',
                        ),
                        value: model.id,
                      ),
                  ],
                ),
              ),
              if (downloadedModels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Download a model from the Models tab to pin one here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Divider(height: 32),
              const _SectionLabel('Generation preset'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Custom preset for this chat'),
                subtitle: const Text(
                  'Override temperature, sampling, and system prompt',
                ),
                value: active.generationOverrides != null,
                onChanged: (enabled) {
                  controller.setGenerationOverrides(
                    enabled
                        ? (active.generationOverrides ??
                              settings.generationConfig)
                        : null,
                  );
                },
              ),
              if (active.generationOverrides != null)
                _GenerationOverrideEditor(
                  config: active.generationOverrides!,
                  onChanged: controller.setGenerationOverrides,
                ),
            ],
          );
        },
      ),
    );
  }

  String _defaultModelLabel(String? activeModelId) {
    if (activeModelId == null) return 'Built-in demo model';
    return ModelCatalog.byId(activeModelId)?.name ?? 'Built-in demo model';
  }
}

class _GenerationOverrideEditor extends StatelessWidget {
  const _GenerationOverrideEditor({
    required this.config,
    required this.onChanged,
  });

  final GenerationConfig config;
  final ValueChanged<GenerationConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        LabeledSlider(
          label: 'Temperature',
          value: config.temperature,
          min: 0,
          max: 2,
          divisions: 40,
          display: config.temperature.toStringAsFixed(2),
          onChanged: (v) => onChanged(config.copyWith(temperature: v)),
        ),
        LabeledSlider(
          label: 'Top-K',
          value: config.topK.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          display: '${config.topK}',
          onChanged: (v) => onChanged(config.copyWith(topK: v.round())),
        ),
        LabeledSlider(
          label: 'Top-P',
          value: config.topP,
          min: 0,
          max: 1,
          divisions: 20,
          display: config.topP.toStringAsFixed(2),
          onChanged: (v) => onChanged(config.copyWith(topP: v)),
        ),
        LabeledSlider(
          label: 'Max tokens',
          value: config.maxTokens.toDouble(),
          min: 256,
          max: 8192,
          divisions: 31,
          display: '${config.maxTokens}',
          onChanged: (v) => onChanged(config.copyWith(maxTokens: v.round())),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: config.systemPrompt ?? '',
          decoration: const InputDecoration(
            labelText: 'System prompt (this chat only)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (v) {
            final trimmed = v.trim();
            onChanged(
              GenerationConfig(
                temperature: config.temperature,
                topK: config.topK,
                topP: config.topP,
                maxTokens: config.maxTokens,
                systemPrompt: trimmed.isEmpty ? null : trimmed,
                randomSeed: config.randomSeed,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
