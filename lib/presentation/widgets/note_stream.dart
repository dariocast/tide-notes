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
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
  });

  final List<Note> notes;
  final Set<String> busyNoteIds;
  final ValueChanged<NoteEdit> onChanged;
  final ValueChanged<String> onRescue;
  final VoidCallback haptic;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const KeyedSubtree(
        key: ValueKey('note-list'),
        child: TideEmptyState(),
      );
    }

    return ListView.builder(
      key: const ValueKey('note-list'),
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
          haptic: haptic,
          now: now,
        );
      },
    );
  }
}

final class NoteEdit {
  const NoteEdit(this.id, this.content);

  final String id;
  final String content;
}
