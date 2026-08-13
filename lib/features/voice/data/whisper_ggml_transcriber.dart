import 'dart:async';
import 'dart:typed_data';

import 'package:manthan/features/voice/domain/whisper_transcriber.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// [WhisperTranscriber] backed by `whisper_ggml` / whisper.cpp.
class WhisperGgmlTranscriber implements WhisperTranscriber {
  StreamSubscription<Uint8List>? _audioSub;
  WhisperLiveSession? _session;

  @override
  Future<WhisperLiveHandle> startLive({
    required String modelPath,
    required Stream<Uint8List> pcm16Stream,
  }) async {
    await _audioSub?.cancel();
    if (_session != null) {
      await _session!.stop();
      _session = null;
    }

    final session = await startWhisperLiveSession(
      modelPath: modelPath,
      lang: 'auto',
      suppressNonSpeechTokens: true,
      keepModelLoaded: true,
    );
    _session = session;
    _audioSub = pcm16Stream.listen(session.feed);

    return _GgmlLiveHandle(
      session: session,
      onStop: () async {
        await _audioSub?.cancel();
        _audioSub = null;
        _session = null;
        return session.stop();
      },
    );
  }

  @override
  Future<void> releaseModel() => WhisperController().releaseModel();
}

class _GgmlLiveHandle implements WhisperLiveHandle {
  _GgmlLiveHandle({required this.session, required this.onStop});

  final WhisperLiveSession session;
  final Future<String> Function() onStop;

  @override
  Stream<String> get partials => session.partials;

  @override
  Future<String> stop() => onStop();
}
