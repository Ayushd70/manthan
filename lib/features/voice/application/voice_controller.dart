import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/features/voice/data/stt_speech_recognizer.dart';
import 'package:manthan/features/voice/domain/speech_recognizer.dart';

/// Observable state of the voice input feature.
class VoiceState extends Equatable {
  const VoiceState({
    this.isListening = false,
    this.transcript = '',
    this.available = true,
  });

  /// Whether a listening session is active.
  final bool isListening;

  /// Latest (possibly partial) transcript.
  final String transcript;

  /// Whether speech input is available on this device.
  final bool available;

  VoiceState copyWith({
    bool? isListening,
    String? transcript,
    bool? available,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      available: available ?? this.available,
    );
  }

  @override
  List<Object?> get props => <Object?>[isListening, transcript, available];
}

/// Coordinates on-device speech-to-text for the chat composer.
class VoiceController extends Notifier<VoiceState> {
  late final SpeechRecognizer _recognizer;

  @override
  VoiceState build() {
    _recognizer = ref.watch(speechRecognizerProvider);
    return const VoiceState();
  }

  /// Starts listening; transcripts are pushed into [VoiceState.transcript] and
  /// the final transcript is delivered via [onFinal].
  Future<void> start({required void Function(String text) onFinal}) async {
    final ok = await _recognizer.initialize();
    if (!ok) {
      state = state.copyWith(available: false);
      return;
    }
    state = state.copyWith(isListening: true, transcript: '');
    await _recognizer.startListening(
      onResult: (text, {required isFinal}) {
        state = state.copyWith(transcript: text);
        if (isFinal) {
          state = state.copyWith(isListening: false);
          if (text.trim().isNotEmpty) onFinal(text.trim());
        }
      },
    );
  }

  /// Stops listening, keeping the current transcript.
  Future<void> stop() async {
    await _recognizer.stopListening();
    state = state.copyWith(isListening: false);
  }
}

/// Provides the speech recognizer implementation (swap to Whisper here).
final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => SttSpeechRecognizer(),
);

/// Global voice provider.
final voiceControllerProvider = NotifierProvider<VoiceController, VoiceState>(
  VoiceController.new,
);
