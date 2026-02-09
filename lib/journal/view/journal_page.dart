import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';
import 'package:kumi_app/core/theme/kumi_text_styles.dart';
import 'package:kumi_app/journal/cubit/journal_cubit.dart';
import 'package:kumi_app/journal/view/widgets/note_card.dart';
import 'package:kumi_app/journal/view/widgets/quick_capture_bar.dart';
import 'package:kumi_repository/kumi_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Journal page - where users write notes that will be embedded and stored
class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalCubit(
        repository: context.read<KumiRepository>(),
      )..loadNotes(),
      child: Scaffold(
        backgroundColor: KumiColors.creamBackground,
        appBar: AppBar(
          title: Text('Ma Mémoire', style: KumiTextStyles.headlineM),
          backgroundColor: KumiColors.creamBackground,
          elevation: 0,
          centerTitle: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<JournalCubit, JournalState>(
                builder: (context, state) {
                  if (state is JournalLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: KumiColors.orangeAccent,
                      ),
                    );
                  }

                  if (state is JournalError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 48,
                            color: KumiColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${state.message}',
                            style: KumiTextStyles.bodyL,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<JournalCubit>().loadNotes(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KumiColors.orangeAccent,
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is JournalLoaded) {
                    if (state.notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bookOpen,
                              size: 64,
                              color: KumiColors.textDisabled,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune note pour le moment',
                              style: KumiTextStyles.headlineS.copyWith(
                                color: KumiColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Écris ta première note ci-dessous ↓',
                              style: KumiTextStyles.bodyM.copyWith(
                                color: KumiColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: state.notes.length,
                      itemBuilder: (context, index) {
                        return NoteCard(note: state.notes[index]);
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
            const QuickCaptureBar(),
          ],
        ),
      ),
    );
  }
}
