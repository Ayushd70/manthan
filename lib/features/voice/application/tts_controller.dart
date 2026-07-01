import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/utils/markdown_to_speech.dart';
import 'package:manthan/features/voice/data/flutter_tts_synthesizer.dart';
import 'package:manthan/features/voice/domain/speech_synthesizer.dart';

/// Observable state of text-to-speech playback.
class TtsState extends Equatable {
  const TtsState({
    this.isSpeaking = false,
    this.activeMessageId,
    this.available = true,
  });

  /// Whether an utterance is playing.
  final bool isSpeaking;

  /// Id of the message currently being read aloud, if any.
  final String? activeMessageId;

  /// Whether TTS is available on this device.
  final bool available;

  TtsState copyWith({
    bool? isSpeaking,
    String? Function()? activeMessageId,
    bool? available,
  }) {
    return TtsState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      activeMessageId: activeMessageId != null
          ? activeMessageId()
          : this.activeMessageId,
      available: available ?? this.available,
    );
  }

  @override
  List<Object?> get props => <Object?>[isSpeaking, activeMessageId, available];
}

/// Coordinates on-device text-to-speech for assistant replies.
class TtsController extends Notifier<TtsState> {
  late final SpeechSynthesizer _synthesizer;

  @override
  TtsState build() {
    _synthesizer = ref.watch(speechSynthesizerProvider);
    _synthesizer.setCompletionHandler(_onPlaybackComplete);
    ref.onDispose(() => unawaited(_synthesizer.stop()));
    return const TtsState();
  }

  void _onPlaybackComplete() {
    state = state.copyWith(isSpeaking: false, activeMessageId: () => null);
  }

  /// Speaks [markdownText] for [messageId], stripping Markdown first.
  ///
  /// Tapping the same message again stops playback.
  Future<void> speakMessage({
    required String messageId,
    required String markdownText,
  }) async {
    if (state.isSpeaking && state.activeMessageId == messageId) {
      await stop();
      return;
    }

    final plain = MarkdownToSpeech.plainText(markdownText);
    if (plain.isEmpty) return;

    final ok = await _synthesizer.initialize();
    if (!ok) {
      state = state.copyWith(available: false);
      return;
    }

    await _synthesizer.stop();
    state = state.copyWith(
      isSpeaking: true,
      activeMessageId: () => messageId,
      available: true,
    );
    await _synthesizer.speak(plain);
  }

  /// Stops any in-flight speech.
  Future<void> stop() async {
    await _synthesizer.stop();
    state = state.copyWith(isSpeaking: false, activeMessageId: () => null);
  }
}

/// Provides the speech synthesizer implementation.
final speechSynthesizerProvider = Provider<SpeechSynthesizer>(
  (ref) => FlutterTtsSynthesizer(),
);

/// Global TTS provider.
final ttsControllerProvider = NotifierProvider<TtsController, TtsState>(
  TtsController.new,
);
