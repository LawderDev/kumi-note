import 'dart:io' show Platform;

/// Configuration for Ollama local server
class OllamaConfig {
  OllamaConfig._();

  /// Base URL for Ollama API
  /// Uses 10.0.2.2 for Android emulator, localhost for other platforms
  static String get baseUrl {
    // Check if running on Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:11434';
    }
    return 'http://localhost:11434';
  }

  /// Embedding model name
  static const String embeddingModel = 'nomic-embed-text';

  /// Chat/LLM model name
  static const String chatModel = 'llama3.2:3b';

  /// Expected embedding dimension for nomic-embed-text
  static const int embeddingDimension = 768;

  /// Timeout for embedding requests (30 seconds)
  static const Duration embeddingTimeout = Duration(seconds: 30);

  /// Timeout for chat requests (60 seconds for streaming)
  static const Duration chatTimeout = Duration(seconds: 60);

  /// Timeout for health check (5 seconds)
  static const Duration healthCheckTimeout = Duration(seconds: 5);

  /// Number of retry attempts for failed requests
  static const int maxRetries = 2;

  /// Delay between retries (exponential backoff)
  static Duration retryDelay(int attempt) =>
      Duration(milliseconds: 500 * (1 << attempt));
}
