import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/models/data/model_storage.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/voice/data/whisper_model_locator.dart';

void main() {
  late Directory dir;
  late ModelStorage storage;
  late WhisperModelLocator locator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('manthan-whisper-');
    storage = ModelStorage(overrideDir: dir);
    locator = WhisperModelLocator(storage);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> plant(String fileName, int bytes) async {
    final modelsDir = await storage.directory();
    final file = File('${modelsDir.path}/$fileName');
    await file.writeAsBytes(List<int>.filled(bytes, 1));
  }

  test('returns null when no Whisper model is downloaded', () async {
    expect(await locator.pathFor(), isNull);
    expect(await locator.resolve(), isNull);
  });

  test('prefers the requested model when it is on disk', () async {
    await plant(
      ModelCatalog.whisperTiny.fileName,
      ModelCatalog.whisperTiny.sizeBytes,
    );
    await plant(
      ModelCatalog.whisperBase.fileName,
      ModelCatalog.whisperBase.sizeBytes,
    );

    final resolved = await locator.resolve(
      preferredId: ModelCatalog.whisperBase.id,
    );
    expect(resolved, ModelCatalog.whisperBase);
  });

  test('falls back to Tiny when preferred is missing', () async {
    await plant(
      ModelCatalog.whisperTiny.fileName,
      ModelCatalog.whisperTiny.sizeBytes,
    );

    final resolved = await locator.resolve(
      preferredId: ModelCatalog.whisperBase.id,
    );
    expect(resolved, ModelCatalog.whisperTiny);
  });
}
