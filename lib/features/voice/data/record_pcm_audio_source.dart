import 'dart:typed_data';

import 'package:manthan/features/voice/domain/pcm_audio_source.dart';
import 'package:record/record.dart';

/// [PcmAudioSource] backed by the `record` plugin.
class RecordPcmAudioSource implements PcmAudioSource {
  RecordPcmAudioSource({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  bool _recording = false;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  @override
  bool get isRecording => _recording;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() async {
    if (!await hasPermission()) {
      throw StateError('Microphone permission denied.');
    }
    final stream = await _recorder.startStream(_config);
    _recording = true;
    return stream;
  }

  @override
  Future<void> stop() async {
    if (!_recording) return;
    await _recorder.stop();
    _recording = false;
  }

  /// Releases the native recorder.
  Future<void> dispose() => _recorder.dispose();
}
