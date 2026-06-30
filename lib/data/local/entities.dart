import 'package:objectbox/objectbox.dart';

/// Embedding dimensionality for the RAG vector index (EmbeddingGemma = 768).
const int kEmbeddingDimensions = 768;

/// Persisted conversation thread.
@Entity()
class ChatSessionEntity {
  ChatSessionEntity({
    required this.uid,
    required this.title,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.id = 0,
    this.modelId,
    this.documentScoped = false,
  });

  /// ObjectBox primary key.
  @Id()
  int id;

  /// Stable app-level id (uuid).
  @Index()
  @Unique()
  String uid;

  String title;
  int createdAtMs;
  int updatedAtMs;
  String? modelId;
  bool documentScoped;
}

/// Persisted chat message belonging to a [ChatSessionEntity].
@Entity()
class ChatMessageEntity {
  ChatMessageEntity({
    required this.uid,
    required this.sessionUid,
    required this.role,
    required this.text,
    required this.createdAtMs,
    this.id = 0,
    this.isError = false,
    this.tokensPerSecond,
    this.tokenCount,
    this.imageCount = 0,
  });

  @Id()
  int id;

  @Index()
  @Unique()
  String uid;

  /// Foreign key to the owning session's [ChatSessionEntity.uid].
  @Index()
  String sessionUid;

  /// 0 = user, 1 = assistant, 2 = system (see ChatRole.index).
  int role;

  String text;
  int createdAtMs;
  bool isError;
  double? tokensPerSecond;
  int? tokenCount;
  int imageCount;
}

/// A document imported for retrieval-augmented generation.
@Entity()
class DocumentEntity {
  DocumentEntity({
    required this.uid,
    required this.title,
    required this.addedAtMs,
    this.id = 0,
    this.chunkCount = 0,
    this.charCount = 0,
  });

  @Id()
  int id;

  @Index()
  @Unique()
  String uid;

  String title;
  int addedAtMs;
  int chunkCount;
  int charCount;
}

/// A chunk of a [DocumentEntity] with its embedding vector, indexed for ANN
/// search via ObjectBox's HNSW implementation.
@Entity()
class DocumentChunkEntity {
  DocumentChunkEntity({
    required this.documentUid,
    required this.documentTitle,
    required this.content,
    required this.ordinal,
    this.id = 0,
    this.embedding,
  });

  @Id()
  int id;

  @Index()
  String documentUid;

  String documentTitle;
  String content;
  int ordinal;

  /// Dense embedding; HNSW index enables O(log n) nearest-neighbour search.
  @HnswIndex(dimensions: kEmbeddingDimensions)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;
}
