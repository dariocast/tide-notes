import 'package:flutter/material.dart';

import '../../design/design_tokens.dart';
import '../../design/tide_depth_fade.dart';
import '../../domain/entities/note.dart';
import 'note_card.dart';
import 'tide_empty_state.dart';

class NoteStream extends StatefulWidget {
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
  State<NoteStream> createState() => _NoteStreamState();
}

class _NoteStreamState extends State<NoteStream> {
  final Set<String> _editingIds = {};

  // TideDepthFade mounts/unmounts a ShaderMask around the stream as editing
  // starts or stops (and when high contrast is toggled). Without a stable
  // GlobalKey here, that structural change would make the framework treat
  // the underlying ListView.builder as a brand-new subtree each time,
  // discarding NoteCard editing state and scroll position. The GlobalKey
  // lets Flutter reparent the existing element instead of remounting it.
  final GlobalKey _streamContentKey = GlobalKey();

  @override
  void didUpdateWidget(covariant NoteStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editingIds.isEmpty) return;
    final presentIds = widget.notes.map((note) => note.id).toSet();
    _editingIds.removeWhere((id) => !presentIds.contains(id));
  }

  void _setEditing(String id, bool editing) {
    setState(() {
      if (editing) {
        _editingIds.add(id);
      } else {
        _editingIds.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget stream;
    if (widget.notes.isEmpty) {
      stream = const KeyedSubtree(
        key: ValueKey('note-list'),
        child: TideEmptyState(),
      );
    } else {
      stream = ListView.builder(
        key: const ValueKey('note-list'),
        padding: const EdgeInsets.only(bottom: GSpace.s5),
        itemCount: widget.notes.length,
        itemBuilder: (context, index) {
          final note = widget.notes[index];
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            index: index,
            busy: widget.busyNoteIds.contains(note.id),
            rescueEnabled: index > 0,
            onChanged: (content) =>
                widget.onChanged(NoteEdit(note.id, content)),
            onRescue: () => widget.onRescue(note.id),
            haptic: widget.haptic,
            now: widget.now,
            onEditingChanged: (editing) => _setEditing(note.id, editing),
          );
        },
      );
    }

    return TideDepthFade(
      enabled: _editingIds.isEmpty,
      child: KeyedSubtree(key: _streamContentKey, child: stream),
    );
  }
}

final class NoteEdit {
  const NoteEdit(this.id, this.content);

  final String id;
  final String content;
}
