import 'package:flutter/material.dart';

import '../../design/design_tokens.dart';
import '../../domain/entities/note.dart';
import 'note_card.dart';
import 'tide_empty_state.dart';

class NoteStream extends StatelessWidget {
  const NoteStream({
    super.key,
    required this.notes,
    required this.busyNoteIds,
    required this.onChanged,
    required this.onRescue,
    this.onArchive,
    this.onDelete,
    this.onShare,
    this.onCopy,
    this.undoNoteId,
    this.onUndo,
    this.showNoSearchResults = false,
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
    this.highlightQuery,
  });

  final List<Note> notes;
  final Set<String> busyNoteIds;
  final ValueChanged<NoteEdit> onChanged;
  final ValueChanged<String> onRescue;
  final ValueChanged<String>? onArchive;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onShare;
  final ValueChanged<String>? onCopy;
  final String? undoNoteId;
  final VoidCallback? onUndo;
  final bool showNoSearchResults;
  final VoidCallback haptic;
  final DateTime Function() now;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final Widget stream;
    if (notes.isEmpty) {
      stream = KeyedSubtree(
        key: const ValueKey('note-list'),
        child: showNoSearchResults
            ? const TideNoSearchResults()
            : const TideEmptyState(),
      );
    } else {
      stream = ListView.builder(
        key: const ValueKey('note-list'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: GSpace.s5),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            index: index,
            busy: busyNoteIds.contains(note.id),
            rescueEnabled: index > 0,
            onChanged: (content) => onChanged(NoteEdit(note.id, content)),
            onRescue: () => onRescue(note.id),
            onArchive: onArchive == null ? null : () => onArchive!(note.id),
            onDelete: onDelete == null ? null : () => onDelete!(note.id),
            onShare: onShare == null ? null : () => onShare!(note.id),
            onCopy: onCopy == null ? null : () => onCopy!(note.id),
            onUndo: note.id == undoNoteId ? onUndo : null,
            haptic: haptic,
            now: now,
            highlightQuery: highlightQuery,
          );
        },
      );
    }

    return stream;
  }
}

final class NoteEdit {
  const NoteEdit(this.id, this.content);

  final String id;
  final String content;
}
