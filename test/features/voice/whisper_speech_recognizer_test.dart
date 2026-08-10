import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/voice/data/whisper_speech_recognizer.dart';

void main() {
  test('WhisperSpeechRecognizer reports unavailable until wired', () async {
    final recognizer = WhisperSpeechRecognizer();
    expect(await recognizer.initialize(), isFalse);
    expect(recognizer.isAvailable, isFalse);
    expect(recognizer.isListening, isFalse);
  });
}
