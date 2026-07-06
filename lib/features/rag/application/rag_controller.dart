import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/demo/demo_seed.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/inference/application/embedding_controller.dart';
import 'package:manthan/features/inference/domain/embedding_engine.dart';
import 'package:manthan/features/rag/data/document_repository.dart';
import 'package:manthan/features/rag/data/text_chunker.dart';
import 'package:manthan/features/rag/domain/document.dart';
import 'package:uuid/uuid.dart';

/// Result of a retrieval call: the joined context plus cited source titles.
class RetrievalResult {
  const RetrievalResult({required this.context, required this.sources});

  /// Empty retrieval result.
  static const RetrievalResult empty = RetrievalResult(
    context: '',
    sources: <String>[],
  );

  /// Concatenated chunk text to inject into the prompt.
  final String context;

  /// Distinct document titles that contributed context.
  final List<String> sources;
}

/// Observable state of the RAG feature.
class RagState extends Equatable {
  const RagState({
    this.documents = const <DocumentInfo>[],
    this.isIndexing = false,
    this.indexingLabel = '',
    this.chunkCount = 0,
    this.isUsingMockEmbedder = true,
  });

  /// Imported documents.
  final List<DocumentInfo> documents;

  /// True while a document is being chunked + embedded.
  final bool isIndexing;

  /// Human-readable progress label during indexing.
  final String indexingLabel;

  /// Total indexed chunks across all documents.
  final int chunkCount;

  /// Whether search uses the mock embedder (vs EmbeddingGemma).
  final bool isUsingMockEmbedder;

  RagState copyWith({
    List<DocumentInfo>? documents,
    bool? isIndexing,
    String? indexingLabel,
    int? chunkCount,
    bool? isUsingMockEmbedder,
  }) {
    return RagState(
      documents: documents ?? this.documents,
      isIndexing: isIndexing ?? this.isIndexing,
      indexingLabel: indexingLabel ?? this.indexingLabel,
      chunkCount: chunkCount ?? this.chunkCount,
      isUsingMockEmbedder: isUsingMockEmbedder ?? this.isUsingMockEmbedder,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    documents,
    isIndexing,
    indexingLabel,
    chunkCount,
    isUsingMockEmbedder,
  ];
}

/// Manages document import, embedding, indexing, and retrieval.
class RagController extends Notifier<RagState> {
  static const _uuid = Uuid();
  static const _chunker = TextChunker();

  late final DocumentRepository _repo;
  bool? _lastEmbedderWasMock;

  @override
  RagState build() {
    _repo = ref.read(documentRepositoryProvider);

    ref.listen(embeddingControllerProvider, (prev, next) {
      final wasMock = prev?.isUsingMock ?? true;
      final isMock = next.isUsingMock;
      if (wasMock && !isMock && next.isReady && _repo.chunkCount > 0) {
        unawaited(reindexAll());
      }
      if (_lastEmbedderWasMock != isMock) {
        _lastEmbedderWasMock = isMock;
        state = state.copyWith(isUsingMockEmbedder: isMock);
      }
    });

    final embedding = ref.read(embeddingControllerProvider);
    _lastEmbedderWasMock = embedding.isUsingMock;

    if (DemoSeed.enabled) {
      return RagState(
        documents: DemoSeed.documents(),
        chunkCount: DemoSeed.chunkCount,
        isUsingMockEmbedder: embedding.isUsingMock,
      );
    }
    return RagState(
      documents: _repo.listDocuments(),
      chunkCount: _repo.chunkCount,
      isUsingMockEmbedder: embedding.isUsingMock,
    );
  }

  EmbeddingEngine get _embedder {
    final runtime = ref.read(embeddingControllerProvider);
    final engine = runtime.engine;
    if (engine == null || !runtime.isReady) {
      throw StateError('Embedding engine is not ready');
    }
    return engine;
  }

  /// Imports [text] as a document titled [title], chunking and embedding it.
  Future<void> importText({required String title, required String text}) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isIndexing: true, indexingLabel: 'Preparing…');

    await ref.read(embeddingControllerProvider.notifier).ensureReady();
    final embedder = _embedder;

    state = state.copyWith(indexingLabel: 'Chunking…');
    final chunks = _chunker.chunk(text);
    final embedded = <EmbeddedChunk>[];
    for (var i = 0; i < chunks.length; i++) {
      state = state.copyWith(
        indexingLabel: 'Embedding ${i + 1}/${chunks.length}…',
      );
      final vector = await embedder.embedDocument(chunks[i]);
      embedded.add(EmbeddedChunk(content: chunks[i], embedding: vector));
    }

    _repo.addDocument(
      uid: _uuid.v4(),
      title: title,
      chunks: embedded,
      charCount: text.length,
    );

    state = state.copyWith(
      documents: _repo.listDocuments(),
      chunkCount: _repo.chunkCount,
      isIndexing: false,
      indexingLabel: '',
    );
  }

  /// Re-embeds all indexed chunks (e.g. after switching to EmbeddingGemma).
  Future<void> reindexAll() async {
    final chunks = _repo.allChunks();
    if (chunks.isEmpty) return;

    await ref.read(embeddingControllerProvider.notifier).ensureReady();
    final embedder = _embedder;

    state = state.copyWith(isIndexing: true, indexingLabel: 'Re-indexing…');
    final updates = <int, List<double>>{};

    for (var i = 0; i < chunks.length; i++) {
      state = state.copyWith(
        indexingLabel: 'Re-indexing ${i + 1}/${chunks.length}…',
      );
      final chunk = chunks[i];
      updates[chunk.id] = await embedder.embedDocument(chunk.content);
    }

    _repo.updateEmbeddings(updates);
    state = state.copyWith(
      chunkCount: _repo.chunkCount,
      isIndexing: false,
      indexingLabel: '',
    );
  }

  /// Removes a document and its chunks.
  void removeDocument(String id) {
    _repo.deleteDocument(id);
    state = state.copyWith(
      documents: _repo.listDocuments(),
      chunkCount: _repo.chunkCount,
    );
  }

  /// Clears all imported documents.
  void clearAll() {
    _repo.clear();
    state = state.copyWith(
      documents: _repo.listDocuments(),
      chunkCount: _repo.chunkCount,
    );
  }

  /// Retrieves the most relevant context for [query].
  Future<RetrievalResult> retrieve(String query, {int topK = 4}) async {
    if (_repo.chunkCount == 0 || query.trim().isEmpty) {
      return RetrievalResult.empty;
    }
    try {
      final queryVector = await _embedder.embedQuery(query);
      final chunks = _repo.search(queryVector, topK: topK);
      if (chunks.isEmpty) return RetrievalResult.empty;

      final context = chunks
          .map((c) => '[${c.documentTitle}] ${c.content}')
          .join('\n\n');
      final sources = <String>{
        for (final c in chunks) c.documentTitle,
      }.toList();
      return RetrievalResult(context: context, sources: sources);
    } on Object catch (e) {
      debugPrint('Retrieval failed: $e');
      return RetrievalResult.empty;
    }
  }
}

/// Global RAG provider.
final ragControllerProvider = NotifierProvider<RagController, RagState>(
  RagController.new,
);
