import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:manthan/features/models/domain/model_info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the on-disk location of downloaded model files and integrity checks.
class ModelStorage {
  ModelStorage({Directory? overrideDir}) : _overrideDir = overrideDir;

  final Directory? _overrideDir;
  Directory? _cached;

  /// Returns (creating if needed) the directory that holds model files.
  Future<Directory> directory() async {
    if (_cached != null) return _cached!;
    final base = _overrideDir ?? await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'models'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return _cached = dir;
  }

  /// Absolute path where [model] is (or will be) stored.
  Future<String> pathFor(ModelInfo model) async {
    final dir = await directory();
    return p.join(dir.path, model.fileName);
  }

  /// Absolute path for a [sidecar] companion file.
  Future<String> sidecarPathFor(ModelSidecar sidecar) async {
    final dir = await directory();
    return p.join(dir.path, sidecar.fileName);
  }

  /// Partial-download path used while a download is in flight.
  Future<String> partPathFor(String targetPath) async => '$targetPath.part';

  /// Whether [model] has been fully downloaded, including required sidecars.
  ///
  /// Considers a file present and (when known) at least 95% of the expected
  /// size, to tolerate small discrepancies between catalog estimates and the
  /// actual artifact while still rejecting truncated downloads.
  Future<bool> isDownloaded(ModelInfo model) async {
    if (!await _fileReady(await pathFor(model), model.sizeBytes)) return false;
    for (final sidecar in model.requiredSidecars(isIos: Platform.isIOS)) {
      if (!await _fileReady(
        await sidecarPathFor(sidecar),
        sidecar.sizeBytes,
      )) {
        return false;
      }
    }
    return true;
  }

  /// Size on disk of [model] and its sidecars, or 0 if absent.
  Future<int> sizeOnDisk(ModelInfo model) async {
    var total = 0;
    final main = File(await pathFor(model));
    if (main.existsSync()) total += await main.length();
    for (final sidecar in model.sidecars) {
      final file = File(await sidecarPathFor(sidecar));
      if (file.existsSync()) total += await file.length();
    }
    return total;
  }

  /// Deletes the model file, sidecars, and any leftover partial downloads.
  Future<void> delete(ModelInfo model) async {
    await _deletePath(await pathFor(model));
    for (final sidecar in model.sidecars) {
      await _deletePath(await sidecarPathFor(sidecar));
    }
  }

  /// Sum of all model file sizes in the models directory.
  Future<int> totalBytesUsed() async {
    final dir = await directory();
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Verifies the SHA-256 of [model] against its catalog hash.
  ///
  /// Returns true when no hash is configured (nothing to verify against).
  Future<bool> verifyChecksum(ModelInfo model) async {
    final expected = model.sha256;
    if (expected == null || expected.isEmpty) return true;
    final file = File(await pathFor(model));
    if (!file.existsSync()) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }

  /// Paths needed to load [model] as an embedding engine on this device.
  Future<({String modelPath, String? tokenizerPath, String? iosTokenizerPath})>
  embeddingPathsFor(ModelInfo model) async {
    String? tokenizerPath;
    String? iosTokenizerPath;
    for (final sidecar in model.sidecars) {
      if (sidecar.scope == ModelSidecarScope.nonIos && !Platform.isIOS) {
        tokenizerPath = await sidecarPathFor(sidecar);
      }
      if (sidecar.scope == ModelSidecarScope.ios && Platform.isIOS) {
        iosTokenizerPath = await sidecarPathFor(sidecar);
      }
    }
    return (
      modelPath: await pathFor(model),
      tokenizerPath: tokenizerPath,
      iosTokenizerPath: iosTokenizerPath,
    );
  }

  Future<bool> _fileReady(String path, int expectedBytes) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    if (expectedBytes <= 0) return true;
    final len = await file.length();
    return len >= (expectedBytes * 0.95).floor();
  }

  Future<void> _deletePath(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
    final part = File('$path.part');
    if (part.existsSync()) await part.delete();
  }
}
