import 'dart:async';

import 'package:kumi_data_sources/src/services/llm_service.dart';

/// Mock implementation of LLMService for testing and development.
/// Parses the RAG prompt to extract notes context and generates
/// a coherent response based on the provided notes.
class MockLLMService implements LLMService {
  @override
  Future<void> initialize() async {
    // No initialization needed for mock
  }

  @override
  Future<void> close() async {
    // No cleanup needed for mock
  }

  @override
  Stream<String> generateResponse(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 1000,
  }) {
    return _mockStream(prompt);
  }

  /// Generates a mock response stream that respects the RAG context.
  Stream<String> _mockStream(String prompt) async* {
    late String response;

    // Extract the question from the prompt
    final questionMatch = RegExp(r'Question:\s*(.+?)(?:\n|$)').firstMatch(
      prompt,
    );
    final question = questionMatch?.group(1)?.trim() ?? '';

    // Check if notes context was provided in the RAG prompt
    final hasNotesContext =
        prompt.contains(
          'Voici les informations pertinentes',
        ) &&
        !prompt.contains(
          "Je ne trouve pas d'informations pertinentes",
        );

    if (hasNotesContext) {
      // Extract individual notes from context
      final notesSection = RegExp(
        r'Voici les informations pertinentes de tes notes:\s*\n([\s\S]*?)\nQuestion:',
      ).firstMatch(prompt);

      final notesText = notesSection?.group(1)?.trim() ?? '';

      // Extract actual note IDs [123] from the prompt
      final noteIdMatches = RegExp(r'\[(\d+)\]').allMatches(notesText).toList();

      // Extract note contents
      final noteEntries = RegExp(
        r'\[(\d+)\]\s*(.+)',
      ).allMatches(notesText).toList();

      if (noteEntries.isNotEmpty) {
        // Build references using actual note IDs
        final refs = noteIdMatches.map((m) => '[${m.group(1)}]').join(', ');
        final firstNote = noteEntries.first.group(2)?.trim() ?? '';

        // Truncate the note content for display
        final preview = firstNote.length > 100
            ? '${firstNote.substring(0, 100)}...'
            : firstNote;

        response =
            "D'après tes notes, voici ce que j'ai trouvé: "
            '"$preview" $refs';
      } else {
        response =
            'Je ne trouve pas cette info dans tes notes. '
            'Essaie de reformuler ta question !';
      }
    } else if (question.isEmpty) {
      response =
          "Je n'ai pas compris ta question. "
          'Peux-tu reformuler ?';
    } else {
      response =
          "Je ne trouve pas d'informations pertinentes dans tes notes "
          "pour répondre à cette question. Essaie d'ajouter des notes "
          'sur ce sujet !';
    }

    // Stream tokens with simulated delays
    const tokenDelayMs = 30;
    final words = response.split(' ');

    for (var i = 0; i < words.length; i++) {
      if (i < words.length - 1) {
        yield '${words[i]} ';
      } else {
        yield words[i];
      }
      await Future<void>.delayed(const Duration(milliseconds: tokenDelayMs));
    }
  }
}
