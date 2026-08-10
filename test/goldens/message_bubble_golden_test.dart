@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/presentation/widgets/message_bubble.dart';

import '../support/golden_harness.dart';

void main() {
  testWidgets('user message bubble', (tester) async {
    await setGoldenSurface(tester, size: const Size(420, 160));
    await tester.pumpWidget(
      goldenHarness(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MessageBubble(
            message: ChatMessage(
              id: 'u1',
              role: ChatRole.user,
              text: 'Explain on-device privacy',
              createdAt: DateTime(2026, 8, 10),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(MessageBubble),
      matchesGoldenFile('goldens/message_bubble_user.png'),
    );
  });

  testWidgets('assistant message bubble with metrics and citation', (
    tester,
  ) async {
    await setGoldenSurface(tester, size: const Size(420, 280));
    await tester.pumpWidget(
      goldenHarness(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MessageBubble(
            message: ChatMessage(
              id: 'a1',
              role: ChatRole.assistant,
              text:
                  'On-device AI keeps prompts local.\n\n'
                  'Nothing leaves the device during inference.',
              createdAt: DateTime(2026, 8, 10),
              tokensPerSecond: 42.3,
              tokenCount: 64,
              sources: const <String>['privacy.md'],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(MessageBubble),
      matchesGoldenFile('goldens/message_bubble_assistant.png'),
    );
  });
}
