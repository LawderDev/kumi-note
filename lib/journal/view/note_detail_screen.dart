import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/core/theme/kumi_text_styles.dart';
import 'package:kumi_note/journal/cubit/journal_cubit.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Detail screen for viewing and editing a single note
/// Accessed when tapping a NoteCard from HomeScreen
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({
    required this.note,
    super.key,
  });

  final NoteModel note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _contentController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KumiColors.creamBackground,
      appBar: AppBar(
        backgroundColor: KumiColors.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: KumiColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Note', style: KumiTextStyles.headlineM),
        actions: [
          // Delete button
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          // Archive button
          IconButton(
            icon: const Icon(
              LucideIcons.archive,
              color: KumiColors.orangeAccent,
            ),
            onPressed: () => _archiveNote(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note content (editable)
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: _contentController,
                focusNode: _focusNode,
                maxLines: null,
                style: KumiTextStyles.bodyL,
                decoration: InputDecoration(
                  hintText: 'Note content...',
                  hintStyle: KumiTextStyles.bodyL.copyWith(
                    color: KumiColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Metadata section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: KumiColors.orangeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Métadonnées', style: KumiTextStyles.labelM),
                  const SizedBox(height: 12),
                  _MetadataRow(
                    icon: LucideIcons.clock,
                    label: 'Créé le',
                    value: _formatDate(widget.note.createdAt),
                  ),
                  const SizedBox(height: 8),
                  if (widget.note.updatedAt != null)
                    _MetadataRow(
                      icon: LucideIcons.refreshCw,
                      label: 'Modifié le',
                      value: _formatDate(widget.note.updatedAt!),
                    ),
                  const SizedBox(height: 8),
                  _MetadataRow(
                    icon: LucideIcons.zap,
                    label: 'Embedding',
                    value: '${widget.note.embedding.length} dimensions',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KumiColors.orangeAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _saveNote(context),
                child: Text(
                  'Enregistrer',
                  style: KumiTextStyles.labelL.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote(BuildContext context) {
    final updatedNote = widget.note.copyWith(
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );
    unawaited(context.read<JournalCubit>().updateNote(updatedNote));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note enregistrée')),
    );
    Navigator.of(context).pop();
  }

  void _archiveNote(BuildContext context) {
    unawaited(
      context.read<JournalCubit>().archiveNote(widget.note.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note archivée')),
    );
    Navigator.of(context).pop();
  }

  void _showDeleteConfirmation(BuildContext context) {
    final journalCubit = context.read<JournalCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: KumiColors.creamBackground,
          title: const Text('Supprimer la note'),
          content: const Text(
            'Êtes-vous sûr ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(journalCubit.deleteNote(widget.note.id));
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Note supprimée')),
                );
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Metadata row widget
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KumiColors.orangeAccent),
        const SizedBox(width: 8),
        Text(label, style: KumiTextStyles.labelS),
        const Spacer(),
        Text(value, style: KumiTextStyles.bodyS),
      ],
    );
  }
}
