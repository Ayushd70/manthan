import 'package:flutter_tts/flutter_tts.dart';
import 'package:manthan/features/voice/domain/speech_synthesizer.dart';

/// [SpeechSynthesizer] backed by the `flutter_tts` plugin (platform TTS).
class FlutterTtsSynthesizer implements SpeechSynthesizer {
  FlutterTtsSynthesizer() : _tts = FlutterTts() {
    _tts
      ..setCompletionHandler(() {
        _speaking = false;
        _onComplete?.call();
      })
      ..setCancelHandler(() {
        _speaking = false;
        _onComplete?.call();
      });
  }

  final FlutterTts _tts;
  bool _available = false;
  bool _speaking = false;
  void Function()? _onComplete;

  @override
  bool get isAvailable => _available;

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<bool> initialize() async {
    if (_available) return true;
    final languages = await _tts.getLanguages;
    if (languages is! List || languages.isEmpty) {
      return _available = false;
    }
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    return _available = true;
  }

  @override
  Future<void> speak(String text) async {
    if (!await initialize()) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _speaking = true;
    await _tts.speak(trimmed);
  }

  @override
  Future<void> stop() async {
    if (_speaking) {
      await _tts.stop();
    }
    _speaking = false;
  }

  @override
  void setCompletionHandler(void Function()? onComplete) {
    _onComplete = onComplete;
  }
}
