import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/presentation/widgets/message_bubble.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('MessageBubble', () {
    testWidgets('renders user text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: ChatMessage(
              id: '1',
              role: ChatRole.user,
              text: 'Hello there',
              createdAt: DateTime(2026),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hello there'), findsOneWidget);
    });

    testWidgets('renders assistant markdown and tokens/sec footer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: ChatMessage(
              id: '2',
              role: ChatRole.assistant,
              text: 'A reply',
              createdAt: DateTime(2026),
              tokensPerSecond: 12.5,
              tokenCount: 7,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('12.5 tok/s'), findsOneWidget);
    });

    testWidgets('shows source citation chips', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MessageBubble(
            message: ChatMessage(
              id: '3',
              role: ChatRole.assistant,
              text: 'Grounded answer',
              createdAt: DateTime(2026),
              sources: const <String>['notes.md'],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('notes.md'), findsOneWidget);
    });
  });
}
