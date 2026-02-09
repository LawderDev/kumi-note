import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumi_data_sources/src/config/ollama_config.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/core/theme/kumi_text_styles.dart';
import 'package:kumi_repository/kumi_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Page shown when Ollama server is not available
/// Provides instructions for setting up Ollama
class OllamaCheckPage extends StatefulWidget {
  const OllamaCheckPage({
    required this.repository,
    required this.onSuccess,
    super.key,
  });

  final KumiRepository repository;
  final VoidCallback onSuccess;

  @override
  State<OllamaCheckPage> createState() => _OllamaCheckPageState();
}

class _OllamaCheckPageState extends State<OllamaCheckPage> {
  bool _isChecking = false;
  String? _errorMessage;
  List<String>? _availableModels;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _availableModels = null;
    });

    try {
      final health = await widget.repository.getHealth();

      if (health['isAvailable'] as bool) {
        final models = (health['models'] as List).cast<String>();

        // Check if required models are present (flexible version matching)
        final hasEmbedding = models.any(
          (m) => m.startsWith('nomic-embed-text'),
        );
        final hasChat = models.any(
          (m) => m.startsWith('llama3.2'),
        );

        if (hasEmbedding && hasChat) {
          // All good, proceed to app
          if (mounted) {
            widget.onSuccess();
          }
        } else {
          setState(() {
            _availableModels = models;
            _errorMessage =
                'Modèles manquants.\n'
                '${hasEmbedding ? "" : "❌ ${OllamaConfig.embeddingModel}\n"}'
                '${hasChat ? "" : "❌ ${OllamaConfig.chatModel}"}';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Serveur Ollama non accessible à ${OllamaConfig.baseUrl}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KumiColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mascot
              Text(
                '🐕',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),

              Text(
                'Configuration Ollama',
                style: KumiTextStyles.headlineL,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              if (_isChecking) ...[
                const CircularProgressIndicator(color: KumiColors.orangeAccent),
                const SizedBox(height: 16),
                Text(
                  'Connexion en cours...',
                  style: KumiTextStyles.bodyL,
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KumiColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KumiColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KumiColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: KumiTextStyles.bodyM.copyWith(
                            color: KumiColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Setup instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: KumiColors.warmGray.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.terminal,
                            color: KumiColors.orangeAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: KumiTextStyles.headlineS,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InstructionStep(
                        number: '1',
                        title: 'Installer Ollama',
                        command:
                            'curl -fsSL https://ollama.com/install.sh | sh',
                        description: 'ou visitez ollama.com',
                      ),
                      const SizedBox(height: 12),
                      _InstructionStep(
                        number: '2',
                        title: 'Démarrer le serveur',
                        command: 'ollama serve',
                        description: 'Gardez ce terminal ouvert',
                      ),
                      const SizedBox(height: 12),
                      _InstructionStep(
                        number: '3',
                        title: 'Télécharger les modèles',
                        command:
                            'ollama pull ${OllamaConfig.embeddingModel}\n'
                            'ollama pull ${OllamaConfig.chatModel}',
                        description: 'Dans un nouveau terminal',
                      ),
                    ],
                  ),
                ),

                if (_availableModels != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KumiColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modèles disponibles:',
                          style: KumiTextStyles.bodyS.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(_availableModels!.isEmpty
                            ? [Text('Aucun', style: KumiTextStyles.caption)]
                            : _availableModels!.map(
                                (m) =>
                                    Text('• $m', style: KumiTextStyles.caption),
                              )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _checkHealth,
                  icon: const Icon(LucideIcons.refreshCw, size: 20),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KumiColors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.title,
    required this.command,
    required this.description,
  });

  final String number;
  final String title;
  final String command;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: KumiColors.orangeAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: KumiTextStyles.bodyS.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: KumiTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: command));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Commande copiée !'),
                backgroundColor: KumiColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KumiColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KumiColors.warmGray.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    command,
                    style: KumiTextStyles.bodyS.copyWith(
                      fontFamily: 'monospace',
                      color: KumiColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.copy,
                  size: 16,
                  color: KumiColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            description,
            style: KumiTextStyles.caption.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
