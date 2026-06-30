import 'package:equatable/equatable.dart';

/// Lifecycle of a model on the device.
enum ModelDownloadStatus { notDownloaded, downloading, downloaded, failed }

/// Observable state for a single model's download / availability.
class ModelDownload extends Equatable {
  const ModelDownload({
    required this.modelId,
    this.status = ModelDownloadStatus.notDownloaded,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  /// Catalog id this state refers to.
  final String modelId;

  /// Current status.
  final ModelDownloadStatus status;

  /// Bytes downloaded so far.
  final int receivedBytes;

  /// Total expected bytes (0 if unknown).
  final int totalBytes;

  /// Error message if [status] is [ModelDownloadStatus.failed].
  final String? error;

  /// Download progress in `[0, 1]`, or null when total is unknown.
  double? get progress {
    if (totalBytes <= 0) return null;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// Whether the model is ready to load.
  bool get isReady => status == ModelDownloadStatus.downloaded;

  ModelDownload copyWith({
    ModelDownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    String? error,
  }) {
    return ModelDownload(
      modelId: modelId,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    modelId,
    status,
    receivedBytes,
    totalBytes,
    error,
  ];
}
