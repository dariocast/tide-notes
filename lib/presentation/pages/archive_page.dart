import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_illustrations.dart';
import '../../l10n/tide_localizations.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../widgets/note_card.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle)),
      body: BlocBuilder<TideBloc, TideState>(
        builder: (context, state) {
          if (state.archivedNotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TideEmptyIllustration(
                      key: ValueKey('archive-empty-icon'),
                      icon: TideIcons.archive,
                    ),
                    const SizedBox(height: GSpace.s3),
                    Text(
                      l10n.archiveEmptyTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: GSpace.s2),
                    Text(
                      l10n.archiveEmptyBody,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: g.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: state.archivedNotes.length,
            itemBuilder: (context, index) {
              final note = state.archivedNotes[index];
              return Slidable(
                key: ValueKey(note.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.01,
                  dismissible: DismissiblePane(
                    // Matches Dismissible's own default dismissThreshold
                    // (0.4) and NoteCard's swipe-right rescue gesture, for
                    // behavioral consistency between the two swipe surfaces.
                    dismissThreshold: 0.4,
                    // DismissiblePane's own default (closeOnCancel: false)
                    // leaves the pane sitting open at whatever ratio it was
                    // dragged to once confirmDismiss returns false. Since
                    // confirmDismiss always returns false here (the side
                    // effect already happened; nothing should actually be
                    // removed from the list), closeOnCancel must be true so
                    // the row always springs back closed.
                    closeOnCancel: true,
                    confirmDismiss: () async {
                      context.read<TideBloc>().add(
                        NoteRestoreFromArchiveRequested(note.id),
                      );
                      return false;
                    },
                    onDismissed: () {},
                  ),
                  children: [
                    // Wrapped in Expanded: flutter_slidable's motion widgets
                    // lay out `children` in a Flex (both the ScrollMotion
                    // reveal and the DismissiblePane's InversedDrawerMotion
                    // during the actual dismiss animation), and require a
                    // non-zero flex factor on each child -- a bare,
                    // unconstrained DecoratedBox overflows the reveal's Flex
                    // and crashes the dismiss animation's FlexExitTransition.
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: g.rescueSoft),
                        child: Padding(
                          padding: const EdgeInsets.only(left: GSpace.s4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FaIcon(
                              TideIcons.surface,
                              color: g.rescue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => context.read<TideBloc>().add(
                        NoteDeleteRequested(note.id),
                      ),
                      backgroundColor: g.dangerSoft,
                      foregroundColor: g.danger,
                      icon: TideIcons.deleteAll.data,
                      label: l10n.deleteNote,
                    ),
                  ],
                ),
                // NoteCard itself already renders its content in an
                // AnimatedContainer keyed 'note-row' (see note_card.dart),
                // regardless of rescueEnabled -- so NoteCard is used
                // directly as the Slidable's child rather than wrapped in
                // another KeyedSubtree with the same key, which would leave
                // two 'note-row'-keyed widgets in the tree and make
                // find.byKey(ValueKey('note-row')) ambiguous in tests.
                child: NoteCard(
                  note: note,
                  index: index,
                  rescueEnabled: false,
                  onChanged: (_) {},
                  onRescue: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
