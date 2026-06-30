import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/rag/domain/document.dart';
import 'package:manthan/objectbox.g.dart';

/// A chunk plus its embedding, produced by the chunk+embed pipeline.
class EmbeddedChunk {
  const EmbeddedChunk({required this.content, required this.embedding});

  /// Chunk text.
  final String content;

  /// Embedding vector for the chunk.
  final List<double> embedding;
}

/// Stores document chunks and performs nearest-neighbour retrieval using
/// ObjectBox's native HNSW vector index.
class DocumentRepository {
  DocumentRepository(Store store)
    : _documents = store.box<DocumentEntity>(),
      _chunks = store.box<DocumentChunkEntity>();

  final Box<DocumentEntity> _documents;
  final Box<DocumentChunkEntity> _chunks;

  /// Persists a document and its embedded [chunks].
  void addDocument({
    required String uid,
    required String title,
    required List<EmbeddedChunk> chunks,
    required int charCount,
  }) {
    _documents.put(
      DocumentEntity(
        uid: uid,
        title: title,
        addedAtMs: DateTime.now().millisecondsSinceEpoch,
        chunkCount: chunks.length,
        charCount: charCount,
      ),
    );
    _chunks.putMany(<DocumentChunkEntity>[
      for (var i = 0; i < chunks.length; i++)
        DocumentChunkEntity(
          documentUid: uid,
          documentTitle: title,
          content: chunks[i].content,
          ordinal: i,
          embedding: chunks[i].embedding,
        ),
    ]);
  }

  /// Returns the [topK] chunks most similar to [queryEmbedding].
  List<RetrievedChunk> search(List<double> queryEmbedding, {int topK = 5}) {
    final query = _chunks
        .query(
          DocumentChunkEntity_.embedding.nearestNeighborsF32(
            queryEmbedding,
            topK,
          ),
        )
        .build();
    try {
      final results = query.findWithScores();
      return results
          .map(
            (r) => RetrievedChunk(
              documentId: r.object.documentUid,
              documentTitle: r.object.documentTitle,
              content: r.object.content,
              // ObjectBox returns distance; convert to a "higher is better"
              // score so the UI can rank intuitively.
              score: 1 / (1 + r.score),
            ),
          )
          .toList();
    } finally {
      query.close();
    }
  }

  /// Lists all imported documents, newest first.
  List<DocumentInfo> listDocuments() {
    final query =
        (_documents.query()
              ..order(DocumentEntity_.addedAtMs, flags: Order.descending))
            .build();
    try {
      return query
          .find()
          .map(
            (e) => DocumentInfo(
              id: e.uid,
              title: e.title,
              addedAt: DateTime.fromMillisecondsSinceEpoch(e.addedAtMs),
              chunkCount: e.chunkCount,
              charCount: e.charCount,
            ),
          )
          .toList();
    } finally {
      query.close();
    }
  }

  /// Deletes a document and its chunks.
  void deleteDocument(String uid) {
    final docQuery = _documents.query(DocumentEntity_.uid.equals(uid)).build();
    try {
      _documents.removeMany(docQuery.findIds());
    } finally {
      docQuery.close();
    }
    final chunkQuery = _chunks
        .query(DocumentChunkEntity_.documentUid.equals(uid))
        .build();
    try {
      _chunks.removeMany(chunkQuery.findIds());
    } finally {
      chunkQuery.close();
    }
  }

  /// Total number of indexed chunks.
  int get chunkCount => _chunks.count();

  /// Total number of documents.
  int get documentCount => _documents.count();

  /// Removes all documents and chunks.
  void clear() {
    _documents.removeAll();
    _chunks.removeAll();
  }
}
