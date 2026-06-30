import 'package:manthan/features/voice/domain/speech_recognizer.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// [SpeechRecognizer] backed by the `speech_to_text` plugin, which uses the
/// platform's on-device recognizer (Android `SpeechRecognizer`, iOS `Speech`).
class SttSpeechRecognizer implements SpeechRecognizer {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_available) return true;
    return _available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
  }

  @override
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
  }) async {
    if (!await initialize()) return;
    await _speech.listen(
      onResult: (result) => onResult(
        result.recognizedWords,
        isFinal: result.finalResult,
      ),
      listenOptions: SpeechListenOptions(cancelOnError: true),
    );
  }

  @override
  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
  }
}
