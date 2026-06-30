import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:manthan/features/models/data/model_storage.dart';
import 'package:manthan/features/models/domain/model_download.dart';
import 'package:manthan/features/models/domain/model_info.dart';

/// Downloads model files with resume support and progress reporting.
///
/// Resumption is implemented with HTTP range requests against a `.part` file,
/// so an interrupted multi-gigabyte download continues instead of restarting.
class ModelDownloadService {
  ModelDownloadService({required ModelStorage storage, Dio? dio})
    : _storage = storage,
      _dio = dio ?? Dio();

  final ModelStorage _storage;
  final Dio _dio;

  final Map<String, CancelToken> _active = <String, CancelToken>{};

  /// Streams [ModelDownload] updates while fetching [model].
  ///
  /// Pass an optional Hugging Face [authToken] for gated weights.
  Stream<ModelDownload> download(ModelInfo model, {String? authToken}) {
    final controller = StreamController<ModelDownload>();
    final cancelToken = CancelToken();
    _active[model.id] = cancelToken;

    unawaited(
      _run(model, controller, cancelToken, authToken).whenComplete(() {
        _active.remove(model.id);
        if (!controller.isClosed) unawaited(controller.close());
      }),
    );

    return controller.stream;
  }

  /// Cancels an in-flight download for [modelId], if any.
  void cancel(String modelId) {
    _active.remove(modelId)?.cancel('Cancelled by user');
  }

  /// Whether a download is currently active for [modelId].
  bool isActive(String modelId) => _active.containsKey(modelId);

  Future<void> _run(
    ModelInfo model,
    StreamController<ModelDownload> controller,
    CancelToken cancelToken,
    String? authToken,
  ) async {
    final target = await _storage.pathFor(model);
    final partPath = await _storage.partPathFor(model);
    final partFile = File(partPath);

    var received = partFile.existsSync() ? await partFile.length() : 0;
    var total = model.sizeBytes;

    void emit(ModelDownloadStatus status, {String? error}) {
      if (controller.isClosed) return;
      controller.add(
        ModelDownload(
          modelId: model.id,
          status: status,
          receivedBytes: received,
          totalBytes: total,
          error: error,
        ),
      );
    }

    emit(ModelDownloadStatus.downloading);

    try {
      final headers = <String, dynamic>{
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
        if (received > 0) 'Range': 'bytes=$received-',
      };

      final response = await _dio.get<ResponseBody>(
        model.downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 400,
        ),
        cancelToken: cancelToken,
      );

      // If the server ignored our Range request, restart from scratch.
      final isPartial = response.statusCode == 206;
      if (received > 0 && !isPartial) {
        received = 0;
        if (partFile.existsSync()) await partFile.delete();
      }

      final contentLength = _contentLength(response.headers);
      if (contentLength != null) {
        total = received + contentLength;
      }

      final sink = partFile.openWrite(
        mode: received > 0 ? FileMode.append : FileMode.write,
      );

      try {
        await for (final chunk in response.data!.stream) {
          received += chunk.length;
          sink.add(chunk);
          emit(ModelDownloadStatus.downloading);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      await partFile.rename(target);

      if (!await _storage.verifyChecksum(model)) {
        await File(target).delete();
        emit(ModelDownloadStatus.failed, error: 'Checksum verification failed');
        return;
      }

      received = await File(target).length();
      total = received;
      emit(ModelDownloadStatus.downloaded);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        emit(ModelDownloadStatus.notDownloaded);
        return;
      }
      emit(ModelDownloadStatus.failed, error: _humanError(e));
    } on Object catch (e) {
      emit(ModelDownloadStatus.failed, error: e.toString());
    }
  }

  int? _contentLength(Headers headers) {
    final value = headers.value(Headers.contentLengthHeader);
    if (value == null) return null;
    return int.tryParse(value);
  }

  String _humanError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Access denied (HTTP $status). This model is gated — add a '
          'Hugging Face token in Settings.';
    }
    if (status == 404) return 'Model file not found (HTTP 404).';
    return e.message ?? 'Network error';
  }
}
