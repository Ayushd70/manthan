import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/prompts/application/prompt_library_controller.dart';
import 'package:manthan/features/prompts/data/prompt_repository.dart';
import 'package:manthan/features/prompts/domain/saved_prompt.dart';

class _FakePromptRepository implements PromptRepository {
  final Map<String, SavedPrompt> _byId = <String, SavedPrompt>{};

  @override
  List<SavedPrompt> list() =>
      _byId.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  void save(SavedPrompt prompt) => _byId[prompt.id] = prompt;

  @override
  void delete(String id) => _byId.remove(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PromptLibraryController', () {
    late ProviderContainer container;
    late _FakePromptRepository repo;

    setUp(() {
      repo = _FakePromptRepository();
      container = ProviderContainer(
        overrides: [promptRepositoryProvider.overrideWithValue(repo)],
      );
    });

    tearDown(() => container.dispose());

    PromptLibraryController controller() =>
        container.read(promptLibraryControllerProvider.notifier);

    PromptLibraryState state() =>
        container.read(promptLibraryControllerProvider);

    test('starts with an empty list', () {
      expect(state().prompts, isEmpty);
    });

    test('addPrompt saves and refreshes state', () {
      controller().addPrompt(title: 'Concise', content: 'Be brief.');

      final prompts = state().prompts;
      expect(prompts, hasLength(1));
      expect(prompts.single.title, 'Concise');
      expect(prompts.single.content, 'Be brief.');
    });

    test('addPrompt ignores blank title or content', () {
      controller()
        ..addPrompt(title: '   ', content: 'Be brief.')
        ..addPrompt(title: 'Title', content: '   ');

      expect(state().prompts, isEmpty);
    });

    test('updatePrompt keeps id and createdAt, replaces text', () {
      controller().addPrompt(title: 'Original', content: 'v1');
      final saved = state().prompts.single;

      controller().updatePrompt(saved, title: 'Renamed', content: 'v2');

      final updated = state().prompts.single;
      expect(updated.id, saved.id);
      expect(updated.createdAt, saved.createdAt);
      expect(updated.title, 'Renamed');
      expect(updated.content, 'v2');
    });

    test('deletePrompt removes it from state', () {
      controller().addPrompt(title: 'Temp', content: 'Delete me');
      final saved = state().prompts.single;

      controller().deletePrompt(saved.id);

      expect(state().prompts, isEmpty);
    });
  });
}
