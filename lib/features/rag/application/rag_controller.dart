import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/demo/demo_seed.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/inference/domain/embedding_engine.dart';
import 'package:manthan/features/rag/data/document_repository.dart';
import 'package:manthan/features/rag/data/mock_embedding_engine.dart';
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
  });

  /// Imported documents.
  final List<DocumentInfo> documents;

  /// True while a document is being chunked + embedded.
  final bool isIndexing;

  /// Human-readable progress label during indexing.
  final String indexingLabel;

  /// Total indexed chunks across all documents.
  final int chunkCount;

  RagState copyWith({
    List<DocumentInfo>? documents,
    bool? isIndexing,
    String? indexingLabel,
    int? chunkCount,
  }) {
    return RagState(
      documents: documents ?? this.documents,
      isIndexing: isIndexing ?? this.isIndexing,
      indexingLabel: indexingLabel ?? this.indexingLabel,
      chunkCount: chunkCount ?? this.chunkCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    documents,
    isIndexing,
    indexingLabel,
    chunkCount,
  ];
}

/// Manages document import, embedding, indexing, and retrieval.
class RagController extends Notifier<RagState> {
  static const _uuid = Uuid();
  static const _chunker = TextChunker();

  late final DocumentRepository _repo;
  late final EmbeddingEngine _embedder;

  @override
  RagState build() {
    _repo = ref.read(documentRepositoryProvider);
    // The mock embedder runs fully offline with zero downloads. The real
    // EmbeddingGemma engine implements the same interface and can be swapped in.
    _embedder = MockEmbeddingEngine();
    unawaited(_embedder.load(modelPath: ''));
    if (DemoSeed.enabled) {
      return RagState(
        documents: DemoSeed.documents(),
        chunkCount: DemoSeed.chunkCount,
      );
    }
    return RagState(
      documents: _repo.listDocuments(),
      chunkCount: _repo.chunkCount,
    );
  }

  /// Imports [text] as a document titled [title], chunking and embedding it.
  Future<void> importText({required String title, required String text}) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isIndexing: true, indexingLabel: 'Chunking…');

    final chunks = _chunker.chunk(text);
    final embedded = <EmbeddedChunk>[];
    for (var i = 0; i < chunks.length; i++) {
      state = state.copyWith(
        indexingLabel: 'Embedding ${i + 1}/${chunks.length}…',
      );
      final vector = await _embedder.embedDocument(chunks[i]);
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
