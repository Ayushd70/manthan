import 'package:equatable/equatable.dart';

/// Metadata about an imported document available for retrieval.
class DocumentInfo extends Equatable {
  const DocumentInfo({
    required this.id,
    required this.title,
    required this.addedAt,
    required this.chunkCount,
    required this.charCount,
  });

  /// Stable id (uuid).
  final String id;

  /// File name / display title.
  final String title;

  /// When the document was imported.
  final DateTime addedAt;

  /// Number of indexed chunks.
  final int chunkCount;

  /// Total character count of the source text.
  final int charCount;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    addedAt,
    chunkCount,
    charCount,
  ];
}

/// A chunk retrieved from the vector store for a query, with similarity score.
class RetrievedChunk extends Equatable {
  const RetrievedChunk({
    required this.documentId,
    required this.documentTitle,
    required this.content,
    required this.score,
  });

  /// Owning document id.
  final String documentId;

  /// Owning document title (for citations).
  final String documentTitle;

  /// The chunk text.
  final String content;

  /// Similarity score (higher is closer; derived from ObjectBox distance).
  final double score;

  @override
  List<Object?> get props => <Object?>[
    documentId,
    documentTitle,
    content,
    score,
  ];
}
