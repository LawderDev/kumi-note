import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_app/app/view/app_shell.dart';
import 'package:kumi_app/app/view/ollama_check_page.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';
import 'package:kumi_app/kumi_chat/kumi_chat.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_repository/kumi_repository.dart';
import 'package:kumi_app/l10n/l10n.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<void> _initializationFuture;
  bool _ollamaReady = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeServices();
  }

  /// Initializes all required services for the Kumi Chat feature
  Future<void> _initializeServices() async {
    // Initialize database service
    await DatabaseService().initialize();

    // Initialize AI service
    await AiService().initialize();
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
            return Scaffold(
              backgroundColor: KumiColors.creamBackground,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🐶',
                      style: TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: KumiColors.orangeAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text('Initialisation de Kumi...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
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
                      Text(
                        'Erreur d\'initialisation',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: KumiColors.error),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Create repository with initialized services
          final database = DatabaseService();
          final aiService = AiService();
          final repository = KumiRepository(
            databaseService: database,
            aiService: aiService,
          );

          return RepositoryProvider.value(
            value: repository,
            child: !_ollamaReady
                ? OllamaCheckPage(
                    repository: repository,
                    onSuccess: () => setState(() => _ollamaReady = true),
                  )
                : MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => ChatCubit(kumiRepository: repository),
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
