import 'package:flutter/material.dart';

import '../../design/design_tokens.dart';
import '../../domain/entities/note.dart';
import '../../l10n/tide_localizations.dart';
import '../widgets/note_card.dart';

/// A static, self-contained walkthrough of Tide's gestures.
///
/// Every note shown here is in-memory demo content created in [initState]
/// and mutated only via local `setState` calls in this widget. The page
/// never reads [TideBloc] or the repository, and none of the callbacks
/// passed to [NoteCard] below reach outside this file: swiping,
/// long-pressing, or editing a demo note can never touch the user's real
/// data.
class TideTutorialPage extends StatefulWidget {
  const TideTutorialPage({super.key});

  @override
  State<TideTutorialPage> createState() => _TideTutorialPageState();
}

class _TideTutorialPageState extends State<TideTutorialPage> {
  late List<Note> _demoNotes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _demoNotes = [
      Note(
        id: 'tutorial-swipe-right',
        content:
            'tip: Swipe right to rescue a note — it floats back to the top.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
      Note(
        id: 'tutorial-swipe-left',
        content: 'tip: Swipe left to reveal Archive, Delete, Share, and Copy.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
      Note(
        id: 'tutorial-long-press',
        content: 'tip: Long-press any note to open full-screen editing.',
        createdAt: now,
        updatedAt: now,
        surfacedAt: now,
        rescueCount: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorialTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(GSpace.s4),
        itemCount: _demoNotes.length,
        itemBuilder: (context, index) => KeyedSubtree(
          key: ValueKey('tutorial-note-$index'),
          child: NoteCard(
            note: _demoNotes[index],
            // Never 0: keeps `rescueEnabled` demonstrable for every row
            // without relying on the real stream's "index 0 can't rescue"
            // rule, which doesn't apply to this static demo list.
            index: index + 1,
            rescueEnabled: true,
            onArchive: () {},
            onDelete: () {},
            onShare: () {},
            onCopy: () {},
            onChanged: (content) => setState(() {
              _demoNotes[index] = _demoNotes[index].copyWith(content: content);
            }),
            onRescue: () {},
          ),
        ),
      ),
    );
  }
}
