import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/voice/data/whisper_speech_recognizer.dart';
import 'package:manthan/features/voice/domain/pcm_audio_source.dart';
import 'package:manthan/features/voice/domain/whisper_transcriber.dart';

class _FakeAudio implements PcmAudioSource {
  final StreamController<Uint8List> controller =
      StreamController<Uint8List>.broadcast();
  bool recording = false;

  @override
  bool get isRecording => recording;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Stream<Uint8List>> start() async {
    recording = true;
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    recording = false;
  }
}

class _FakeHandle implements WhisperLiveHandle {
  _FakeHandle(this._partials, this._finalText);

  final StreamController<String> _partials;
  final String _finalText;

  @override
  Stream<String> get partials => _partials.stream;

  @override
  Future<String> stop() async {
    await _partials.close();
    return _finalText;
  }
}

class _FakeTranscriber implements WhisperTranscriber {
  String? lastPath;
  final StreamController<String> partials =
      StreamController<String>.broadcast();
  String finalText = 'hello from whisper';

  @override
  Future<WhisperLiveHandle> startLive({
    required String modelPath,
    required Stream<Uint8List> pcm16Stream,
  }) async {
    lastPath = modelPath;
    pcm16Stream.listen((_) {});
    return _FakeHandle(partials, finalText);
  }

  @override
  Future<void> releaseModel() async {}
}

void main() {
  test('WhisperSpeechRecognizer reports unavailable without a model', () async {
    final recognizer = WhisperSpeechRecognizer();
    expect(await recognizer.initialize(), isFalse);
    expect(recognizer.isAvailable, isFalse);
    expect(recognizer.isListening, isFalse);
  });

  test('initialize succeeds when a model path is resolved', () async {
    final recognizer = WhisperSpeechRecognizer(
      resolveModelPath: () async => '/tmp/ggml-tiny.bin',
      audioSource: _FakeAudio(),
      transcriber: _FakeTranscriber(),
    );
    expect(await recognizer.initialize(), isTrue);
    expect(recognizer.isAvailable, isTrue);
  });

  test(
    'startListening streams partials and stopListening emits final',
    () async {
      final audio = _FakeAudio();
      final transcriber = _FakeTranscriber();
      final recognizer = WhisperSpeechRecognizer(
        resolveModelPath: () async => '/models/ggml-tiny.bin',
        audioSource: audio,
        transcriber: transcriber,
      );
      await recognizer.initialize();

      final events = <({String text, bool isFinal})>[];
      await recognizer.startListening(
        onResult: (text, {required isFinal}) {
          events.add((text: text, isFinal: isFinal));
        },
      );
      expect(recognizer.isListening, isTrue);
      expect(transcriber.lastPath, '/models/ggml-tiny.bin');

      transcriber.partials.add('hel');
      transcriber.partials.add('hello');
      await Future<void>.delayed(Duration.zero);

      await recognizer.stopListening();
      expect(recognizer.isListening, isFalse);
      expect(audio.recording, isFalse);

      expect(events.where((e) => !e.isFinal).map((e) => e.text), <String>[
        'hel',
        'hello',
      ]);
      expect(events.last, (text: 'hello from whisper', isFinal: true));
    },
  );
}
