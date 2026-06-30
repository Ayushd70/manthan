import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';

/// Renders a single chat message bubble (user or assistant).
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  /// The message to render.
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final scheme = theme.colorScheme;

    final bubbleColor = isUser
        ? scheme.primary
        : (message.isError
              ? scheme.errorContainer
              : scheme.surfaceContainerHighest);
    final textColor = isUser
        ? scheme.onPrimary
        : (message.isError ? scheme.onErrorContainer : scheme.onSurface);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: _animate(
        isUser: isUser,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (message.hasImages) _ImageStrip(message: message),
              if (isUser)
                SelectableText(
                  message.text,
                  style: TextStyle(color: textColor),
                )
              else if (message.text.isEmpty && message.isStreaming)
                _TypingIndicator(color: textColor)
              else
                DefaultTextStyle.merge(
                  style: TextStyle(color: textColor),
                  child: GptMarkdown(
                    message.text,
                    style: TextStyle(color: textColor),
                  ),
                ),
              if (message.sources.isNotEmpty)
                _Sources(sources: message.sources),
              if (message.tokensPerSecond != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${Formatters.tokensPerSecond(message.tokensPerSecond!)}'
                    '${message.tokenCount != null ? ' · ${message.tokenCount} tok' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animate({required bool isUser, required Widget child}) {
    return child
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.12, end: 0, duration: 220.ms, curve: Curves.easeOut)
        .slideX(begin: isUser ? 0.05 : -0.05, end: 0, duration: 220.ms);
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final bytes in message.images)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final source in sources)
            Chip(
              avatar: const Icon(Icons.description_outlined, size: 16),
              label: Text(source),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: theme.textTheme.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});
  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: _dotOpacity(i),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: widget.color,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _dotOpacity(int index) {
    final t = (_controller.value * 3 - index).clamp(0.0, 1.0);
    return 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }
}
