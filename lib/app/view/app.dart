import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_note/app/view/app_shell.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/journal/cubit/journal_cubit.dart';
import 'package:kumi_note/kumi_chat/kumi_chat.dart';
import 'package:kumi_note/l10n/l10n.dart';
import 'package:kumi_repository/kumi_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Future<void> _initializationFuture;
  late SQLiteDatabase _database;
  late SqliteNoteDataSource _noteDataSource;
  late SqliteChatDataSource _chatDataSource;
  late EmbeddingService _embeddingService;
  late LLMService _llmService;
  late KumiRepository _repository;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeServices();
  }

  /// Initializes all required services for the Kumi Note V2 architecture
  Future<void> _initializeServices() async {
    try {
      // Initialize SQLite database (singleton)
      _database = SQLiteDatabase.instance;
      await _database.initialize();

      // Initialize data sources
      _noteDataSource = SqliteNoteDataSource(database: _database);
      await _noteDataSource.initialize();

      _chatDataSource = SqliteChatDataSource(database: _database);
      await _chatDataSource.initialize();

      // Initialize AI services
      // Use MockEmbeddingService for testing;
      // switch to TFLiteEmbeddingService for production
      _embeddingService = MockEmbeddingService();
      _llmService = MockLLMService();

      // Create repository with all services
      _repository = KumiRepository(
        noteDataSource: _noteDataSource,
        chatDataSource: _chatDataSource,
        embeddingService: _embeddingService,
        llmService: _llmService,
      );
    } on Object catch (e) {
      debugPrint('Error initializing services: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    unawaited(_repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: KumiColors.orangeAccent,
          surface: KumiColors.creamBackground,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          if (snapshot.hasError) {
            return _ErrorScreen(error: snapshot.error!);
          }

          return RepositoryProvider.value(
            value: _repository,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) {
                    final cubit = ChatCubit(
                      kumiRepository: _repository,
                    );
                    unawaited(cubit.initialize());
                    return cubit;
                  },
                ),
                BlocProvider(
                  create: (_) {
                    final cubit = JournalCubit(
                      repository: _repository,
                    );
                    unawaited(cubit.initialize());
                    return cubit;
                  },
                ),
              ],
              child: const AppShell(),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KumiColors.creamBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🐶',
              style: TextStyle(fontSize: 80),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: KumiColors.orangeAccent,
            ),
            SizedBox(height: 16),
            Text('Initialisation de Kumi...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KumiColors.creamBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: KumiColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                "Erreur d'initialisation",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: KumiColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
