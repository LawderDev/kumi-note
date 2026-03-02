/// Abstract interface for generating text embeddings.
/// Implementations can use different backends (TFLite, HTTP-based, etc.)
abstract class EmbeddingService {
  /// Generates an embedding vector for the given text.
  ///
  /// Returns a list of floats (typically 384 for MobileBERT).
  /// Throws [EmbeddingException] if generation fails.
  Future<List<double>> generateEmbedding(String text);

  /// Returns the dimensionality of the embeddings this service produces.
  int get dimensions;

  /// Optional: Initialize the service before first use.
  /// Default implementation does nothing.
  Future<void> initialize() async {}

  /// Optional: Clean up resources.
  /// Default implementation does nothing.
  Future<void> close() async {}
}

/// Exception thrown when embedding generation fails.
class EmbeddingException implements Exception {
  EmbeddingException(this.message);
  final String message;

  @override
  String toString() => 'EmbeddingException: $message';
}
