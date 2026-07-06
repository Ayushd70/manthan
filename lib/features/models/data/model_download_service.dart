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
    final totalBytes = model.estimatedTotalBytes(isIos: Platform.isIOS);
    var completedBytes = 0;

    void emit(ModelDownloadStatus status, {String? error}) {
      if (controller.isClosed) return;
      controller.add(
        ModelDownload(
          modelId: model.id,
          status: status,
          receivedBytes: completedBytes,
          totalBytes: totalBytes,
          error: error,
        ),
      );
    }

    emit(ModelDownloadStatus.downloading);

    try {
      final mainTarget = await _storage.pathFor(model);
      completedBytes = await _downloadOne(
        url: model.downloadUrl,
        targetPath: mainTarget,
        expectedBytes: model.sizeBytes,
        cancelToken: cancelToken,
        authToken: authToken,
        onProgress: (received) {
          emit(ModelDownloadStatus.downloading);
        },
        baseCompleted: completedBytes,
        totalBytes: totalBytes,
        controller: controller,
        modelId: model.id,
      );

      for (final sidecar in model.requiredSidecars(isIos: Platform.isIOS)) {
        final sidecarTarget = await _storage.sidecarPathFor(sidecar);
        completedBytes = await _downloadOne(
          url: sidecar.downloadUrl,
          targetPath: sidecarTarget,
          expectedBytes: sidecar.sizeBytes,
          cancelToken: cancelToken,
          authToken: sidecar.scope == ModelSidecarScope.ios ? null : authToken,
          onProgress: (_) => emit(ModelDownloadStatus.downloading),
          baseCompleted: completedBytes,
          totalBytes: totalBytes,
          controller: controller,
          modelId: model.id,
        );
      }

      if (!await _storage.verifyChecksum(model)) {
        await File(mainTarget).delete();
        emit(ModelDownloadStatus.failed, error: 'Checksum verification failed');
        return;
      }

      completedBytes = await _storage.sizeOnDisk(model);
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

  Future<int> _downloadOne({
    required String url,
    required String targetPath,
    required int expectedBytes,
    required CancelToken cancelToken,
    required String? authToken,
    required void Function(int receivedInFile) onProgress,
    required int baseCompleted,
    required int totalBytes,
    required StreamController<ModelDownload> controller,
    required String modelId,
  }) async {
    final partPath = await _storage.partPathFor(targetPath);
    final partFile = File(partPath);

    var received = partFile.existsSync() ? await partFile.length() : 0;
    var fileTotal = expectedBytes;

    void emitProgress() {
      if (controller.isClosed) return;
      controller.add(
        ModelDownload(
          modelId: modelId,
          status: ModelDownloadStatus.downloading,
          receivedBytes: baseCompleted + received,
          totalBytes: totalBytes,
        ),
      );
    }

    emitProgress();

    final headers = <String, dynamic>{
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
      if (received > 0) 'Range': 'bytes=$received-',
    };

    final response = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
        followRedirects: true,
        validateStatus: (s) => s != null && s < 400,
      ),
      cancelToken: cancelToken,
    );

    final isPartial = response.statusCode == 206;
    if (received > 0 && !isPartial) {
      received = 0;
      if (partFile.existsSync()) await partFile.delete();
    }

    final contentLength = _contentLength(response.headers);
    if (contentLength != null) {
      fileTotal = received + contentLength;
    }

    final sink = partFile.openWrite(
      mode: received > 0 ? FileMode.append : FileMode.write,
    );

    try {
      await for (final chunk in response.data!.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress(received);
        emitProgress();
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    await partFile.rename(targetPath);
    return baseCompleted + (fileTotal > 0 ? fileTotal : received);
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
