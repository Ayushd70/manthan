import 'package:equatable/equatable.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';

/// Model architecture family, used to pick the correct chat template on the
/// `flutter_gemma` side. Mirrors the plugin's `ModelType` without leaking the
/// dependency into the domain layer.
enum GemmaModelFamily { gemmaIt, deepSeek, qwen, qwen3, llama, phi, general }

/// On-disk model container format.
enum ModelFileFormat { task, litertlm, binary, gguf }

/// A model that the user can download and run on-device.
class ModelInfo extends Equatable {
  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.fileName,
    required this.engineKind,
    required this.fileFormat,
    this.family = GemmaModelFamily.general,
    this.parameterLabel = '',
    this.quantization = '',
    this.supportsVision = false,
    this.isThinkingModel = false,
    this.requiresAuthToken = false,
    this.license = '',
    this.sha256,
  });

  /// Stable unique key (used for persistence and routing).
  final String id;

  /// Display name, e.g. `Gemma 3 1B (INT4)`.
  final String name;

  /// One-line description shown in the catalog.
  final String description;

  /// Approximate download size in bytes.
  final int sizeBytes;

  /// HTTPS download URL.
  final String downloadUrl;

  /// Target filename on disk (must match the URL's extension semantics).
  final String fileName;

  /// Which runtime executes this model.
  final EngineKind engineKind;

  /// Container format.
  final ModelFileFormat fileFormat;

  /// Architecture family for chat templating (Gemma engine).
  final GemmaModelFamily family;

  /// e.g. `1B`, `3n E2B`.
  final String parameterLabel;

  /// e.g. `INT4`, `Q4_K_M`.
  final String quantization;

  /// Whether the model accepts image inputs.
  final bool supportsVision;

  /// Whether the model exposes a separate reasoning ("thinking") stream.
  final bool isThinkingModel;

  /// Whether a Hugging Face token is needed (gated weights).
  final bool requiresAuthToken;

  /// Short license label (e.g. `Gemma`, `Apache-2.0`).
  final String license;

  /// Optional SHA-256 of the file for integrity verification.
  final String? sha256;

  @override
  List<Object?> get props => <Object?>[id];
}
