import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kumi_data_sources/kumi_data_sources.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/core/theme/kumi_text_styles.dart';
import 'package:kumi_note/journal/cubit/journal_cubit.dart';
import 'package:kumi_note/journal/view/note_detail_screen.dart';
import 'package:kumi_note/journal/view/widgets/bottom_input_bar.dart';
import 'package:kumi_note/journal/view/widgets/note_card.dart';
import 'package:kumi_note/kumi_chat/view/widgets/chat_overlay.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// HomeScreen - "Kumi Stage" 3-layer design per specification:
///
/// LAYER 1 (Top): Notes list with search filter
///   - CustomScrollView with SliverAppBar
///   - FilterBar for keyword search
///   - Notes displayed as NoteCard widgets
///   - Empty state when no notes
///
/// LAYER 2 (Center): KumiMascot (floating)
///   - Positioned center of screen
///   - State synced with ChatCubit (idle, listening, thinking, success, error)
///   - Scale animation on entry
///
/// LAYER 3 (Bottom): Input bar + Chat overlay
///   - BottomInputBar (always visible, "Ask Kumi..." placeholder)
///   - ChatOverlay (slides up conditionally)
///
/// Colors:
///   - Background: #FDFBF7 (cream)
///   - Accents: #E67E22 (orange)
///   - Text: #2C3E50 (charcoal)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  String _filterQuery = '';
  bool _isSearchActive = false;
  bool _isChatVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KumiColors.creamBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: Notes List (CustomScrollView)
          _buildLayer1NotesList(),

          // LAYER 3: BottomInputBar + ChatOverlay + FABs
          _buildLayer3InputArea(),
        ],
      ),
    );
  }

  // ====== LAYER 1: Notes List ======
  Widget _buildLayer1NotesList() {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        // Initial or Loading state
        if (state is JournalInitial || state is JournalLoading) {
          return const Center(
            child: CircularProgressIndicator(color: KumiColors.orangeAccent),
          );
        }

        // Error state
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
                Text('Error', style: KumiTextStyles.headlineS),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.message,
                    style: KumiTextStyles.bodyM,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Get notes and apply filter
        final notes = state is JournalLoaded ? state.notes : <NoteModel>[];
        final filteredNotes = _filterQuery.isEmpty
            ? notes
            : notes
                  .where(
                    (note) => note.content.toLowerCase().contains(
                      _filterQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        // Empty state
        if (filteredNotes.isEmpty && state is JournalLoaded) {
          return SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 64,
                    color: KumiColors.warmGray.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text('No Notes Yet', style: KumiTextStyles.headlineS),
                  const SizedBox(height: 8),
                  Text(
                    'Ask Kumi or create a note using the input below',
                    style: KumiTextStyles.bodyM,
                  ),
                ],
              ),
            ),
          );
        }

        // Main list view
        return CustomScrollView(
          slivers: [
            // AppBar - Discrete header with "Journal" and search icon
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: KumiColors.creamBackground,
              elevation: 0,
              title: Text('Journal', style: KumiTextStyles.headlineM),
              centerTitle: false,
              titleSpacing: 16,
              actions: [
                // Search icon - toggles filter bar
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _isSearchActive ? LucideIcons.x : LucideIcons.search,
                      color: KumiColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchActive = !_isSearchActive;
                        if (!_isSearchActive) {
                          _filterQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            // Search filter bar (appears when search is active)
            if (_isSearchActive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Filter notes...',
                      hintStyle: TextStyle(
                        color: KumiColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: KumiColors.orangeAccent,
                      ),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x),
                              onPressed: () {
                                setState(() {
                                  _filterQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: KumiColors.orangeAccent,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: KumiColors.orangeAccent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      setState(() => _filterQuery = query);
                    },
                  ),
                ),
              ),

            // Notes grid/list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = filteredNotes[index];
                    return Padding(
                      key: ValueKey('note-padding-${note.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteCard(
                        note: note,
                        onDelete: () {
                          unawaited(
                            context.read<JournalCubit>().deleteNote(note.id),
                          );
                        },
                        onArchive: () {
                          unawaited(
                            context.read<JournalCubit>().archiveNote(note.id),
                          );
                        },
                        onTap: () {
                          final journalCubit = context.read<JournalCubit>();
                          unawaited(
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: journalCubit,
                                  child: NoteDetailScreen(note: note),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: filteredNotes.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ====== LAYER 2: Removed (Mascot caused infinite loading) ======

  // ====== LAYER 3: Bottom Input Area ======
  Widget _buildLayer3InputArea() {
    return Stack(
      children: [
        // ChatOverlay (user-controlled)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ChatOverlay(
            key: const ValueKey('chat_overlay'),
            isVisible: _isChatVisible,
            onClose: _closeChat,
            onNoteTap: _openNote,
          ),
        ),

        // BottomInputBar (always visible)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomInputBar(
            onInputTap: () => setState(() => _isChatVisible = true),
            onSubmit: () => setState(() => _isChatVisible = true),
          ),
        ),

        // Chat toggle button
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'chat_toggle',
            onPressed: () => setState(() => _isChatVisible = !_isChatVisible),
            backgroundColor: KumiColors.orangeAccent,
            child: Icon(
              _isChatVisible
                  ? LucideIcons.chevronDown
                  : LucideIcons.messageCircle,
              color: Colors.white,
            ),
          ),
        ),

        // Add Note FAB
        Positioned(
          bottom: 80,
          right: 80,
          child: FloatingActionButton(
            heroTag: 'add_note',
            onPressed: _showAddNoteDialog,
            backgroundColor: KumiColors.orangeAccent,
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showAddNoteDialog() {
    final journalCubit = context.read<JournalCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => _AddNoteDialog(
          journalCubit: journalCubit,
          scaffoldMessenger: scaffoldMessenger,
        ),
      ),
    );
  }

  void _closeChat() {
    setState(() => _isChatVisible = false);
  }

  void _openNote(int noteId) async {
    final journalCubit = context.read<JournalCubit>();

    // Get the note from the cubit state
    final state = journalCubit.state;
    if (state is! JournalLoaded) return;

    final note = state.notes.where((n) => n.id == noteId).firstOrNull;
    if (note == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note not found')),
        );
      }
      return;
    }

    // Navigate to note detail
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => BlocProvider.value(
            value: journalCubit,
            child: NoteDetailScreen(note: note),
          ),
        ),
      );
    }
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog({
    required this.journalCubit,
    required this.scaffoldMessenger,
  });

  final JournalCubit journalCubit;
  final ScaffoldMessengerState scaffoldMessenger;

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.journalCubit.addNote(text);
    } on Exception catch (e) {
      if (widget.scaffoldMessenger.mounted) {
        widget.scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KumiColors.creamBackground,
      title: Text('Nouvelle note', style: KumiTextStyles.headlineS),
      content: TextField(
        controller: _textController,
        autofocus: true,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Écrivez votre note ici...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: KumiColors.warmGray,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: KumiColors.orangeAccent,
              width: 2,
            ),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: KumiColors.orangeAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
