import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/app/router.dart';
import 'package:manthan/core/constants/app_info.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/shared/widgets/labeled_slider.dart';

/// App configuration: appearance, generation parameters, tokens, and about.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final engine = ref.watch(engineControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.auto_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (s) => controller.setThemeMode(s.first),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Dynamic color'),
            subtitle: const Text('Match the system color palette'),
            value: settings.useDynamicColor,
            onChanged: (v) => controller.setDynamicColor(enabled: v),
          ),
          const Divider(),
          const _SectionHeader('Voice'),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: const Text('Auto-speak replies'),
            subtitle: const Text(
              'Read assistant answers aloud when generation finishes',
            ),
            value: settings.autoSpeakReplies,
            onChanged: (v) => controller.setAutoSpeakReplies(enabled: v),
          ),
          const Divider(),
          const _SectionHeader('Engine'),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Active model'),
            subtitle: Text(engine.displayName),
            trailing: engine.status == EngineStatus.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.models),
          ),
          _GenerationControls(
            config: settings.generationConfig,
            onChanged: (config) async {
              await controller.setGenerationConfig(config);
            },
            onApply: () =>
                ref.read(engineControllerProvider.notifier).reloadActive(),
          ),
          const Divider(),
          const _SectionHeader('Prompts'),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Prompt library'),
            subtitle: const Text('Save and apply reusable system prompts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.prompts),
          ),
          const Divider(),
          const _SectionHeader('Downloads'),
          _HuggingFaceTokenTile(
            token: settings.huggingFaceToken,
            onSave: controller.setHuggingFaceToken,
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('100% on-device'),
            subtitle: Text(AppInfo.description),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text(AppInfo.version),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Source'),
            subtitle: Text(AppInfo.repositoryUrl),
          ),
        ],
      ),
    );
  }
}

class _GenerationControls extends StatelessWidget {
  const _GenerationControls({
    required this.config,
    required this.onChanged,
    required this.onApply,
  });

  final GenerationConfig config;
  final ValueChanged<GenerationConfig> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.tune),
      title: const Text('Generation parameters'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
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
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: onApply,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Apply (reload model)'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _HuggingFaceTokenTile extends StatefulWidget {
  const _HuggingFaceTokenTile({required this.token, required this.onSave});

  final String? token;
  final ValueChanged<String?> onSave;

  @override
  State<_HuggingFaceTokenTile> createState() => _HuggingFaceTokenTileState();
}

class _HuggingFaceTokenTileState extends State<_HuggingFaceTokenTile> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.token,
  );
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hugging Face token',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'hf_…',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () {
                      widget.onSave(_controller.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token saved')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
