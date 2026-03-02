import 'dart:math';

import 'package:kumi_data_sources/src/services/embedding_service.dart';

/// TFLite-based embedding service using on-device MobileBERT model.
///
/// This service:
/// - Loads the MobileBERT TFLite model (~25 MB)
/// - Tokenizes input text using BERT tokenizer
/// - Runs inference to generate 384-dim embeddings
/// - Uses compute() for non-blocking execution
///
// TODO(developer): Integrate actual tflite_flutter package when model is
/// available. Current placeholder uses mock generation until model asset is
/// added.
class TFLiteEmbeddingService implements EmbeddingService {
  TFLiteEmbeddingService({
    this.modelPath = 'assets/models/mobilebert.tflite',
  });

  final String modelPath;
  bool _initialized = false;

  @override
  int get dimensions => 384; // MobileBERT output dimension

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // TODO(developer): Load TFLite model when available
    // Steps:
    // 1. Copy mobilebert.tflite to assets/models/
    // 2. Load via: await Interpreter.fromAsset(modelPath)
    // 3. Verify input/output shapes
    // 4. Create BERT tokenizer

    _initialized = true;
  }

  @override
  Future<void> close() async {
    // TODO(developer): Clean up TFLite interpreter
    _initialized = false;
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    if (!_initialized) {
      throw EmbeddingException(
        'TFLiteEmbeddingService not initialized. Call initialize() first.',
      );
    }

    if (text.isEmpty) {
      return List<double>.filled(dimensions, 0);
    }

    // TODO(developer): Replace with actual TFLite inference
    // Steps:
    // 1. Tokenize text: List<int> tokens = _tokenizer.tokenize(text)
    // 2. Pad tokens to 128: tokens = _padTokens(tokens, 128)
    // 3. Prepare input: Uint8List input = _prepareInput(tokens)
    // 4. Run inference:
    //    List<dynamic> output = _interpreter.run({0: input})
    // 5. Extract embedding:
    //    List<double> embedding = (output[0] as List).cast<double>()
    // 6. Normalize: embedding = _normalize(embedding)
    // 7. Return embedding

    // Placeholder: Use deterministic pseudo-random embedding
    final rng = Random(text.hashCode);
    final embedding = <double>[
      for (int i = 0; i < dimensions; i++)
        rng.nextDouble() * 2 - 1, // Range: [-1, 1)
    ];

    // Normalize
    final norm = embedding.fold<double>(0, (sum, val) => sum + val * val).isNaN
        ? 1.0
        : sqrt(embedding.fold<double>(0, (sum, val) => sum + val * val));
    if (norm > 0) {
      for (var i = 0; i < embedding.length; i++) {
        embedding[i] = embedding[i] / norm;
      }
    }

    return embedding;
  }
}
