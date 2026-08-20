import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/models/domain/model_info.dart';

/// Curated set of small, capable on-device models.
///
/// URLs point at publicly hosted weights. Sizes are approximate. The user can
/// also add any local GGUF via the file picker (see model manager).
abstract final class ModelCatalog {
  /// All chat/inference catalog entries.
  static const List<ModelInfo> all = <ModelInfo>[
    ModelInfo(
      id: 'gemma3-1b-it-int4',
      name: 'Gemma 3 1B',
      description:
          "Google's compact instruction-tuned model. A great default: "
          'fast, multilingual, and runs comfortably on most phones.',
      sizeBytes: 555 * 1024 * 1024,
      downloadUrl: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
      fileName: 'gemma3-1b-it-int4.task',
      engineKind: EngineKind.gemma,
      fileFormat: ModelFileFormat.task,
      family: GemmaModelFamily.gemmaIt,
      parameterLabel: '1B',
      quantization: 'INT4',
      requiresAuthToken: true,
      license: 'Gemma',
    ),
    ModelInfo(
      id: 'gemma3n-e2b-it',
      name: 'Gemma 3n E2B (Vision)',
      description:
          'Multimodal model that understands both text and images. Pick this '
          'to ask questions about photos, screenshots, and documents.',
      sizeBytes: 3136 * 1024 * 1024,
      downloadUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
      fileName: 'gemma-3n-e2b-it-int4.task',
      engineKind: EngineKind.gemma,
      fileFormat: ModelFileFormat.task,
      family: GemmaModelFamily.gemmaIt,
      parameterLabel: '3n E2B',
      quantization: 'INT4',
      supportsVision: true,
      requiresAuthToken: true,
      license: 'Gemma',
    ),
    ModelInfo(
      id: 'qwen2.5-1.5b-instruct-q4km',
      name: 'Qwen2.5 1.5B Instruct',
      description:
          "Alibaba's strong small model in GGUF, executed by the llama.cpp "
          'engine. Excellent for coding and reasoning at a tiny footprint.',
      sizeBytes: 1120 * 1024 * 1024,
      downloadUrl: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      engineKind: EngineKind.llamaCpp,
      fileFormat: ModelFileFormat.gguf,
      family: GemmaModelFamily.qwen,
      parameterLabel: '1.5B',
      quantization: 'Q4_K_M',
      license: 'Apache-2.0',
    ),
    ModelInfo(
      id: 'smollm2-360m-instruct-q8',
      name: 'SmolLM2 360M Instruct',
      description:
          'Ultra-light GGUF model that runs on almost anything. Ideal for '
          'quick tests and low-end devices.',
      sizeBytes: 386 * 1024 * 1024,
      downloadUrl: 'https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q8_0.gguf',
      fileName: 'smollm2-360m-instruct-q8_0.gguf',
      engineKind: EngineKind.llamaCpp,
      fileFormat: ModelFileFormat.gguf,
      parameterLabel: '360M',
      quantization: 'Q8_0',
      license: 'Apache-2.0',
    ),
  ];

  /// Embedding model used by the RAG pipeline (EmbeddingGemma).
  static const ModelInfo embedding = ModelInfo(
    id: 'embeddinggemma-300m',
    name: 'EmbeddingGemma 300M',
    description:
        'On-device semantic embeddings for document search. Download this '
        'to upgrade RAG from keyword-style mock vectors to true meaning-based '
        'retrieval.',
    sizeBytes: 179 * 1024 * 1024,
    downloadUrl: 'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/embeddinggemma-300M_seq256_mixed-precision.tflite',
    fileName: 'embeddinggemma-300M_seq256_mixed-precision.tflite',
    engineKind: EngineKind.gemma,
    fileFormat: ModelFileFormat.binary,
    parameterLabel: '300M',
    quantization: 'Mixed',
    requiresAuthToken: true,
    license: 'Gemma',
    sidecars: <ModelSidecar>[
      ModelSidecar(
        downloadUrl: 'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/sentencepiece.model',
        fileName: 'embeddinggemma-sentencepiece.model',
        sizeBytes: 4 * 1024 * 1024,
        scope: ModelSidecarScope.nonIos,
      ),
      ModelSidecar(
        downloadUrl: 'https://github.com/DenisovAV/flutter_gemma/releases/download/v0.12.5/embeddinggemma_tokenizer.json',
        fileName: 'embeddinggemma_tokenizer.json',
        scope: ModelSidecarScope.ios,
      ),
    ],
  );

  /// Default Whisper.cpp model for fully offline dictation (tiny, multilingual).
  static const ModelInfo whisperTiny = ModelInfo(
    id: 'whisper-tiny',
    name: 'Whisper Tiny',
    description:
        'Fully offline speech-to-text. Tiny is fast enough for live dictation '
        'on phones and understands 99 languages.',
    sizeBytes: 75 * 1024 * 1024,
    downloadUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
    fileName: 'ggml-tiny.bin',
    engineKind: EngineKind.whisper,
    fileFormat: ModelFileFormat.ggml,
    parameterLabel: 'Tiny',
    quantization: 'GGML',
    license: 'MIT',
  );

  /// Higher-quality Whisper.cpp model for more accurate dictation.
  static const ModelInfo whisperBase = ModelInfo(
    id: 'whisper-base',
    name: 'Whisper Base',
    description:
        'More accurate offline speech-to-text than Tiny, still small enough '
        'for on-device live dictation.',
    sizeBytes: 142 * 1024 * 1024,
    downloadUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
    fileName: 'ggml-base.bin',
    engineKind: EngineKind.whisper,
    fileFormat: ModelFileFormat.ggml,
    parameterLabel: 'Base',
    quantization: 'GGML',
    license: 'MIT',
  );

  /// Stronger accuracy for dictation; still practical on modern phones.
  static const ModelInfo whisperSmall = ModelInfo(
    id: 'whisper-small',
    name: 'Whisper Small',
    description:
        'Noticeably more accurate than Base. Best accuracy/size tradeoff for '
        'offline dictation (~466 MB).',
    sizeBytes: 466 * 1024 * 1024,
    downloadUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
    fileName: 'ggml-small.bin',
    engineKind: EngineKind.whisper,
    fileFormat: ModelFileFormat.ggml,
    parameterLabel: 'Small',
    quantization: 'GGML',
    license: 'MIT',
  );

  /// Highest-accuracy catalog Whisper model. Heavy for live phone dictation.
  static const ModelInfo whisperMedium = ModelInfo(
    id: 'whisper-medium',
    name: 'Whisper Medium',
    description:
        'Most accurate on-device option here (~1.5 GB). Expect more RAM and '
        'latency — better on desktop than live phone dictation.',
    sizeBytes: 1536 * 1024 * 1024,
    downloadUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin',
    fileName: 'ggml-medium.bin',
    engineKind: EngineKind.whisper,
    fileFormat: ModelFileFormat.ggml,
    parameterLabel: 'Medium',
    quantization: 'GGML',
    license: 'MIT',
  );

  /// Whisper.cpp models the download manager tracks for speech-to-text.
  ///
  /// Ordered smallest-first so locators fall back to the lightest downloaded
  /// file when nothing is pinned.
  static const List<ModelInfo> whisper = <ModelInfo>[
    whisperTiny,
    whisperBase,
    whisperSmall,
    whisperMedium,
  ];

  /// Every model the download manager tracks (chat + embedding + STT).
  static List<ModelInfo> get managed => <ModelInfo>[
    ...all,
    embedding,
    ...whisper,
  ];

  /// Suggested starter chat model for first-run onboarding.
  static const String starterModelId = 'gemma3-1b-it-int4';

  /// Catalog entry for [starterModelId].
  static ModelInfo get starter => byId(starterModelId)!;

  /// Looks up a catalog entry by [id], or null if unknown.
  static ModelInfo? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    if (embedding.id == id) return embedding;
    for (final m in whisper) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Whether [id] is a Whisper.cpp speech-to-text catalog entry.
  static bool isWhisper(String id) => whisper.any((m) => m.id == id);
}
