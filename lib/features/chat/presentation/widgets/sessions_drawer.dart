import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/chat/application/chat_controller.dart';

/// Drawer listing saved conversations with create / delete actions.
class SessionsDrawer extends ConsumerWidget {
  const SessionsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  Icon(Icons.blur_on, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Conversations', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  controller.newSession();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: state.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.sessions.length,
                      itemBuilder: (context, i) {
                        final session = state.sessions[i];
                        final selected = session.id == state.active?.id;
                        return ListTile(
                          selected: selected,
                          leading: Icon(
                            session.documentScoped
                                ? Icons.description_outlined
                                : Icons.chat_bubble_outline,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Formatters.relativeTime(
                              session.updatedAt,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                controller.deleteSession(session.id),
                          ),
                          onTap: () {
                            controller.selectSession(session.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
