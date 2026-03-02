/// Abstract interface for language model services.
/// Implementations can use different backends (local, cloud, streaming, etc.)
abstract class LLMService {
  /// Generates a response to a prompt using the language model.
  ///
  /// The [prompt] should include any context and instructions.
  /// The returned Stream yields tokens incrementally for streaming UI updates.
  ///
  /// Throws [LLMException] if generation fails.
  Stream<String> generateResponse(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 1000,
  });

  /// Optional: Initialize the service before first use.
  /// Default implementation does nothing.
  Future<void> initialize() async {}

  /// Optional: Clean up resources.
  /// Default implementation does nothing.
  Future<void> close() async {}
}

/// Exception thrown when LLM generation fails.
class LLMException implements Exception {
  LLMException(this.message);
  final String message;

  @override
  String toString() => 'LLMException: $message';
}
