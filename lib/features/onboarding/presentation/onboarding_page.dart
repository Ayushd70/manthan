import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/app/router.dart';
import 'package:manthan/core/constants/app_info.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// First-run welcome flow: privacy pitch, how it works, starter model.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required String destination}) async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(destination);
  }

  void _next() {
    if (_page < _pageCount - 1) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      unawaited(_finish(destination: Routes.chat));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => unawaited(_finish(destination: Routes.chat)),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _page = index),
                children: const <Widget>[
                  _WelcomePage(),
                  _HowItWorksPage(),
                  _StarterModelPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_pageCount, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: active ? 24 : 8,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (isLast) ...<Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            unawaited(_finish(destination: Routes.chat)),
                        child: const Text('Start chatting'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            unawaited(_finish(destination: Routes.models)),
                        child: Text('Get ${ModelCatalog.starter.name}'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: const Text('Continue'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(flex: 2),
          Icon(Icons.lock_outline, size: 56, color: scheme.primary)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.86, 0.86),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
          Text(
            AppInfo.name,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.12, end: 0),
          const SizedBox(height: 12),
          Text(
            AppInfo.tagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 28),
          Text(
            'Prompts, chats, and documents stay on this device. Nothing is '
            'sent to a cloud API — even in airplane mode.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ).animate().fadeIn(delay: 200.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(),
          Text(
            'How it works',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Three steps to a private assistant.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          const _StepTile(
            index: 1,
            icon: Icons.dns_outlined,
            title: 'Download a model',
            body:
                'Pick a compact model that fits your device. Weights live '
                'locally after one download.',
          ),
          const SizedBox(height: 16),
          const _StepTile(
            index: 2,
            icon: Icons.chat_bubble_outline,
            title: 'Chat on-device',
            body:
                'Inference runs here. Streaming replies never leave the '
                'hardware in your hand.',
          ),
          const SizedBox(height: 16),
          const _StepTile(
            index: 3,
            icon: Icons.description_outlined,
            title: 'Add your documents',
            body:
                'Optional RAG indexes PDFs and notes locally so answers can '
                'cite your own files.',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _StarterModelPage extends StatelessWidget {
  const _StarterModelPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final starter = ModelCatalog.starter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(),
          Text(
            'Pick a starter',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can chat with the built-in demo engine right away, or download '
            'a real model when you are ready.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.auto_awesome, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          starter.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${starter.parameterLabel} · ${starter.quantization} · '
                    '${Formatters.bytes(starter.sizeBytes)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    starter.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  if (starter.requiresAuthToken) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      'Needs a free Hugging Face token in Settings before '
                      'download.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 22,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$index. $title',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.04, end: 0);
  }
}
