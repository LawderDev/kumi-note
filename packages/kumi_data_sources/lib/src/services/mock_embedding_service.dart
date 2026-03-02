import 'dart:math' as math;

import 'package:kumi_data_sources/src/services/embedding_service.dart';

/// Mock implementation of EmbeddingService for testing and development.
///
/// Uses a bag-of-words approach: each word is hashed to a stable set of
/// dimensions, so texts sharing words produce similar embeddings.
/// This enables meaningful cosine similarity for keyword-overlapping texts.
class MockEmbeddingService implements EmbeddingService {
  MockEmbeddingService({this.embeddingDimensions = 384});

  final int embeddingDimensions;
  final Map<String, List<double>> _cache = {};

  @override
  int get dimensions => embeddingDimensions;

  @override
  Future<void> initialize() async {
    // No initialization needed for mock
  }

  @override
  Future<void> close() async {
    _cache.clear();
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    // Return cached embedding if available
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    final embedding = List<double>.filled(embeddingDimensions, 0);

    // Tokenize: lowercase, split on non-alphanumeric, remove short words
    final words = text
        .toLowerCase()
        .replaceAll(RegExp('[^a-zà-ÿ0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    if (words.isEmpty) {
      _cache[text] = embedding;
      return embedding;
    }

    // Each word contributes to multiple dimensions using a stable hash.
    // Words that appear in both the query and a note will activate the
    // same dimensions, producing high cosine similarity.
    for (final word in words) {
      final hash = _stableHash(word);
      final rng = math.Random(hash);

      // Each word activates ~10% of dimensions with stable values
      final activations = embeddingDimensions ~/ 10;
      for (var i = 0; i < activations; i++) {
        final dim = rng.nextInt(embeddingDimensions);
        final value = rng.nextDouble() * 2 - 1;
        embedding[dim] += value;
      }
    }

    // Normalize to unit vector for cosine similarity
    final norm = math.sqrt(
      embedding.fold<double>(0, (sum, val) => sum + val * val),
    );
    if (norm > 0) {
      for (var i = 0; i < embedding.length; i++) {
        embedding[i] = embedding[i] / norm;
      }
    }

    _cache[text] = embedding;
    return embedding;
  }

  /// Stable hash for a word that doesn't depend on Dart's hashCode
  /// (which can vary between runs in some contexts).
  int _stableHash(String word) {
    var hash = 0x811c9dc5; // FNV-1a offset basis
    for (var i = 0; i < word.length; i++) {
      hash ^= word.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF; // FNV prime, keep positive
    }
    return hash;
  }
}
