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

  /// Partial-download path used while a download is in flight.
  Future<String> partPathFor(ModelInfo model) async =>
      '${await pathFor(model)}.part';

  /// Whether [model] has been fully downloaded.
  ///
  /// Considers a file present and (when known) at least 95% of the expected
  /// size, to tolerate small discrepancies between catalog estimates and the
  /// actual artifact while still rejecting truncated downloads.
  Future<bool> isDownloaded(ModelInfo model) async {
    final file = File(await pathFor(model));
    if (!file.existsSync()) return false;
    if (model.sizeBytes <= 0) return true;
    final len = await file.length();
    return len >= (model.sizeBytes * 0.95).floor();
  }

  /// Size on disk of [model], or 0 if absent.
  Future<int> sizeOnDisk(ModelInfo model) async {
    final file = File(await pathFor(model));
    return file.existsSync() ? file.length() : 0;
  }

  /// Deletes the model file (and any leftover partial download).
  Future<void> delete(ModelInfo model) async {
    final file = File(await pathFor(model));
    if (file.existsSync()) await file.delete();
    final part = File(await partPathFor(model));
    if (part.existsSync()) await part.delete();
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
}
