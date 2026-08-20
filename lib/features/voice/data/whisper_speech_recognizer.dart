import 'dart:async';

import 'package:manthan/features/voice/data/record_pcm_audio_source.dart';
import 'package:manthan/features/voice/data/whisper_ggml_transcriber.dart';
import 'package:manthan/features/voice/domain/pcm_audio_source.dart';
import 'package:manthan/features/voice/domain/speech_recognizer.dart';
import 'package:manthan/features/voice/domain/whisper_transcriber.dart';

/// Resolves the on-disk ggml path for the active Whisper model.
typedef WhisperModelPathResolver = Future<String?> Function();

/// Fully offline [SpeechRecognizer] backed by Whisper.cpp.
///
/// Records 16 kHz mono PCM from the microphone and streams partial transcripts
/// from a live whisper.cpp session. Returns unavailable when no model file is
/// on disk so the UI can fall back gracefully.
class WhisperSpeechRecognizer implements SpeechRecognizer {
  WhisperSpeechRecognizer({
    this._resolveModelPath,
    this._audioSource,
    this._transcriber,
  });

  final WhisperModelPathResolver? _resolveModelPath;
  PcmAudioSource? _audioSource;
  WhisperTranscriber? _transcriber;

  bool _available = false;
  bool _listening = false;
  String? _modelPath;
  WhisperLiveHandle? _handle;
  StreamSubscription<String>? _partialsSub;
  void Function(String text, {required bool isFinal})? _onResult;

  PcmAudioSource get _audio => _audioSource ??= RecordPcmAudioSource();

  WhisperTranscriber get _engine => _transcriber ??= WhisperGgmlTranscriber();

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async {
    final path = await _resolveModelPath?.call();
    if (path == null || path.isEmpty) {
      _available = false;
      _modelPath = null;
      return false;
    }
    _modelPath = path;
    _available = true;
    return true;
  }

  @override
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
  }) async {
    if (!_available || _modelPath == null) {
      throw StateError(
        'WhisperSpeechRecognizer is not available. '
        'Download a Whisper model on the Models tab first.',
      );
    }
    if (_listening) return;

    _listening = true;
    _onResult = onResult;
    try {
      final pcm = await _audio.start();
      _handle = await _engine.startLive(
        modelPath: _modelPath!,
        pcm16Stream: pcm,
      );
      _partialsSub = _handle!.partials.listen((text) {
        onResult(text, isFinal: false);
      });
    } on Object {
      _listening = false;
      _onResult = null;
      await _audio.stop();
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;

    await _partialsSub?.cancel();
    _partialsSub = null;
    await _audio.stop();

    final text = (await _handle?.stop() ?? '').trim();
    _handle = null;

    final callback = _onResult;
    _onResult = null;
    callback?.call(text, isFinal: true);
  }

  /// Stops listening and releases a parked native model.
  Future<void> dispose() async {
    await stopListening();
    await _transcriber?.releaseModel();
    final audio = _audioSource;
    if (audio is RecordPcmAudioSource) {
      await audio.dispose();
    }
  }
}
