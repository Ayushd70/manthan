import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/voice/data/stt_speech_recognizer.dart';
import 'package:manthan/features/voice/data/whisper_model_locator.dart';
import 'package:manthan/features/voice/data/whisper_speech_recognizer.dart';
import 'package:manthan/features/voice/domain/speech_recognizer.dart';
import 'package:manthan/features/voice/domain/stt_backend.dart';

/// Observable state of the voice input feature.
class VoiceState extends Equatable {
  const VoiceState({
    this.isListening = false,
    this.transcript = '',
    this.available = true,
    this.error,
  });

  /// Whether a listening session is active.
  final bool isListening;

  /// Latest (possibly partial) transcript.
  final String transcript;

  /// Whether speech input is available on this device.
  final bool available;

  /// User-facing reason when speech input cannot start.
  final String? error;

  VoiceState copyWith({
    bool? isListening,
    String? transcript,
    bool? available,
    String? Function()? error,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      available: available ?? this.available,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isListening,
    transcript,
    available,
    error,
  ];
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
      state = state.copyWith(
        available: false,
        error: _unavailableMessage,
      );
      return;
    }
    state = state.copyWith(
      isListening: true,
      transcript: '',
      available: true,
      error: () => null,
    );
    try {
      await _recognizer.startListening(
        onResult: (text, {required isFinal}) {
          state = state.copyWith(transcript: text);
          if (isFinal) {
            state = state.copyWith(isListening: false);
            if (text.trim().isNotEmpty) onFinal(text.trim());
          }
        },
      );
    } on Object catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString,
      );
    }
  }

  /// Stops listening, keeping the current transcript.
  Future<void> stop() async {
    await _recognizer.stopListening();
    state = state.copyWith(isListening: false);
  }

  String _unavailableMessage() {
    final backend = ref.read(settingsProvider).sttBackend;
    if (backend == SttBackend.whisper) {
      return 'Download a Whisper model on the Models tab to dictate offline.';
    }
    return 'Speech recognition is not available on this device.';
  }
}

/// Provides the speech recognizer implementation based on Settings.
final speechRecognizerProvider = Provider<SpeechRecognizer>((ref) {
  final backend = ref.watch(settingsProvider.select((s) => s.sttBackend));
  final recognizer = switch (backend) {
    SttBackend.platform => SttSpeechRecognizer(),
    SttBackend.whisper => WhisperSpeechRecognizer(
      resolveModelPath: () {
        final locator = WhisperModelLocator(ref.read(modelStorageProvider));
        return locator.pathFor(
          preferredId: ref.read(settingsProvider).whisperModelId,
        );
      },
    ),
  };
  ref.onDispose(() {
    final current = recognizer;
    if (current is WhisperSpeechRecognizer) {
      unawaited(current.dispose());
    }
  });
  return recognizer;
});

/// Global voice provider.
final voiceControllerProvider = NotifierProvider<VoiceController, VoiceState>(
  VoiceController.new,
);
