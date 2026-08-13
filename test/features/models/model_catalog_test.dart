import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_download.dart';

void main() {
  group('ModelCatalog', () {
    test('exposes a non-empty catalog with unique ids', () {
      expect(ModelCatalog.all, isNotEmpty);
      final ids = ModelCatalog.all.map((m) => m.id).toSet();
      expect(ids.length, ModelCatalog.all.length);
    });

    test('covers both real engine kinds', () {
      final kinds = ModelCatalog.all.map((m) => m.engineKind).toSet();
      expect(kinds, contains(EngineKind.gemma));
      expect(kinds, contains(EngineKind.llamaCpp));
    });

    test('embedding model includes tokenizer sidecars', () {
      expect(ModelCatalog.embedding.sidecars, isNotEmpty);
      expect(ModelCatalog.managed, contains(ModelCatalog.embedding));
    });

    test('byId resolves catalog, embedding, and whisper models', () {
      final first = ModelCatalog.all.first;
      expect(ModelCatalog.byId(first.id), first);
      expect(
        ModelCatalog.byId(ModelCatalog.embedding.id),
        ModelCatalog.embedding,
      );
      expect(
        ModelCatalog.byId(ModelCatalog.whisperTiny.id),
        ModelCatalog.whisperTiny,
      );
      expect(ModelCatalog.byId('does-not-exist'), isNull);
    });

    test('managed includes embedding and whisper models', () {
      expect(ModelCatalog.managed, contains(ModelCatalog.embedding));
      expect(ModelCatalog.managed, contains(ModelCatalog.whisperTiny));
      expect(ModelCatalog.managed, contains(ModelCatalog.whisperBase));
      expect(ModelCatalog.isWhisper(ModelCatalog.whisperTiny.id), isTrue);
      expect(ModelCatalog.isWhisper(ModelCatalog.all.first.id), isFalse);
      expect(ModelCatalog.all, isNot(contains(ModelCatalog.whisperTiny)));
      final managedIds = ModelCatalog.managed.map((m) => m.id).toSet();
      expect(managedIds.length, ModelCatalog.managed.length);
    });

    test('starter model resolves from the chat catalog', () {
      expect(ModelCatalog.starter.id, ModelCatalog.starterModelId);
      expect(ModelCatalog.all, contains(ModelCatalog.starter));
    });

    test('at least one vision-capable model exists', () {
      expect(ModelCatalog.all.any((m) => m.supportsVision), isTrue);
    });
  });

  group('ModelDownload', () {
    test('computes progress only when total is known', () {
      const unknown = ModelDownload(modelId: 'x', receivedBytes: 50);
      expect(unknown.progress, isNull);
      const known = ModelDownload(
        modelId: 'x',
        receivedBytes: 50,
        totalBytes: 100,
      );
      expect(known.progress, 0.5);
    });

    test('isReady reflects downloaded status', () {
      const ready = ModelDownload(
        modelId: 'x',
        status: ModelDownloadStatus.downloaded,
      );
      expect(ready.isReady, isTrue);
    });
  });
}
