import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kumi_app/core/config/ollama_config.dart';

/// AI Service for managing language models and embeddings via Ollama.
///
/// This service handles:
/// - Communication with local Ollama server
/// - Embedding generation via nomic-embed-text
/// - Streaming text generation via llama3.2:1b
/// - Health checks and error handling with retries
class AiService {
  AiService._internal() : _modelLoaded = false, _httpClient = http.Client();

  static final AiService _instance = AiService._internal();

  factory AiService() {
    return _instance;
  }

  bool _modelLoaded;
  final http.Client _httpClient;

  /// Initializes the AI service by checking Ollama server health.
  Future<void> initialize() async {
    if (_modelLoaded) return;

    try {
      final health = await checkHealth();
      if (!(health['isAvailable'] as bool)) {
        throw AiServiceException(
          'Ollama server is not available at ${OllamaConfig.baseUrl}',
        );
      }

      // Verify required models are available (flexible version matching)
      final models = (health['models'] as List).cast<String>();
      if (!models.any((m) => m.startsWith('nomic-embed-text'))) {
        throw AiServiceException(
          'Required embedding model not found. '
          'Run: ollama pull nomic-embed-text',
        );
      }
      if (!models.any((m) => m.startsWith('llama3.2'))) {
        throw AiServiceException(
          'Required chat model not found. '
          'Run: ollama pull llama3.2:1b',
        );
      }

      _modelLoaded = true;
    } catch (e) {
      throw AiServiceException('Failed to initialize Ollama: $e');
    }
  }

  /// Generates an embedding vector for the given text using Ollama.
  ///
  /// Calls the Ollama embeddings API with nomic-embed-text model.
  /// Returns a 768-dimensional vector representing semantic meaning.
  Future<List<double>> embedText(String text) async {
    if (!_modelLoaded) {
      throw AiServiceException(
        'AI service not initialized. Call initialize() first.',
      );
    }

    if (text.isEmpty) {
      return [];
    }

    return await _retryOperation(
      () async {
        final response = await _httpClient
            .post(
              Uri.parse('${OllamaConfig.baseUrl}/api/embeddings'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': OllamaConfig.embeddingModel,
                'prompt': text,
              }),
            )
            .timeout(OllamaConfig.embeddingTimeout);

        if (response.statusCode != 200) {
          throw AiServiceException(
            'Ollama embeddings failed: ${response.statusCode} ${response.body}',
          );
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final embedding = (data['embedding'] as List).cast<double>();

        if (embedding.length != OllamaConfig.embeddingDimension) {
          throw AiServiceException(
            'Unexpected embedding dimension: ${embedding.length}, '
            'expected ${OllamaConfig.embeddingDimension}',
          );
        }

        return embedding;
      },
      operationName: 'embedText',
    );
  }

  /// Streams a text response from Ollama's chat API token by token.
  ///
  /// Accepts structured messages (system + user) and streams the response
  /// as it's generated. Yields individual content chunks from the stream.
  Stream<String> streamResponse(List<Map<String, String>> messages) async* {
    if (!_modelLoaded) {
      throw AiServiceException(
        'AI service not initialized. Call initialize() first.',
      );
    }

    if (messages.isEmpty) {
      yield '';
      return;
    }

    try {
      final request =
          http.Request(
              'POST',
              Uri.parse('${OllamaConfig.baseUrl}/api/chat'),
            )
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'model': OllamaConfig.chatModel,
              'messages': messages,
              'stream': true,
            });

      final response = await _httpClient
          .send(request)
          .timeout(OllamaConfig.chatTimeout);

      if (response.statusCode != 200) {
        throw AiServiceException(
          'Ollama chat failed: ${response.statusCode}',
        );
      }

      // Parse JSONL stream (newline-delimited JSON)
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final content = json['message']?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }

            // Check if stream is done
            if (json['done'] == true) {
              return;
            }
          } catch (e) {
            // Skip malformed JSON lines
            continue;
          }
        }
      }
    } on SocketException {
      throw AiServiceException(
        'Cannot connect to Ollama server. '
        'Make sure it is running with: ollama serve',
      );
    } on TimeoutException {
      throw AiServiceException(
        'Ollama request timed out. The model might be loading.',
      );
    } catch (e) {
      throw AiServiceException('Failed to stream response: $e');
    }
  }

  /// Checks if Ollama server is available and returns available models.
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('${OllamaConfig.baseUrl}/api/tags'))
          .timeout(OllamaConfig.healthCheckTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = (data['models'] as List? ?? [])
            .map((m) => m['name'] as String)
            .toList();

        return {
          'isAvailable': true,
          'models': models,
        };
      }

      return {'isAvailable': false, 'models': <String>[]};
    } on SocketException {
      return {'isAvailable': false, 'models': <String>[]};
    } on TimeoutException {
      return {'isAvailable': false, 'models': <String>[]};
    } catch (e) {
      return {'isAvailable': false, 'models': <String>[]};
    }
  }

  /// Retries an operation with exponential backoff.
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    for (int attempt = 0; attempt <= OllamaConfig.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == OllamaConfig.maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future<void>.delayed(OllamaConfig.retryDelay(attempt));
      }
    }

    throw AiServiceException('$operationName failed after max retries');
  }

  /// Closes and cleans up AI resources.
  Future<void> close() async {
    _httpClient.close();
    _modelLoaded = false;
  }
}

/// Exception thrown by AI service operations.
class AiServiceException implements Exception {
  AiServiceException(this.message);

  final String message;

  @override
  String toString() => 'AiServiceException: $message';
}
