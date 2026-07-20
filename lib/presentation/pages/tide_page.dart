import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../widgets/note_composer.dart';
import '../widgets/note_card.dart';
import '../widgets/note_stream.dart';
import '../widgets/tide_header.dart';

DateTime defaultTideNow() => DateTime.now();

class TidePage extends StatelessWidget {
  const TidePage({
    super.key,
    this.haptic = defaultTideHaptic,
    this.now = defaultTideNow,
  });

  final VoidCallback haptic;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) => BlocConsumer<TideBloc, TideState>(
    listener: (context, state) {
      final message = state.message;
      if (message == null) return;
      if (message == 'Rescued') {
        context.read<TideBloc>().add(const TideMessageAcknowledged());
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<TideBloc>().add(const TideMessageAcknowledged());
    },
    builder: (context, state) {
      if (state.fatalFailure != null) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: FilledButton.icon(
                onPressed: () =>
                    context.read<TideBloc>().add(const TideStarted()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ),
        );
      }

      return Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                key: const ValueKey('tide-shell'),
                constraints: const BoxConstraints(maxWidth: GLayout.contentMax),
                child: FocusTraversalGroup(
                  child: MastheadFrame(
                    child: Column(
                      children: [
                        TideHeader(noteCount: state.notes.length, now: now()),
                        NoteComposer(
                          appendCompleted: state.appendCompleted,
                          onSubmit: (content) => context.read<TideBloc>().add(
                            NoteAppendRequested(content),
                          ),
                        ),
                        if (state.rescueReceipt != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                GSpace.s4,
                                0,
                                GSpace.s4,
                                GSpace.s2,
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () => context.read<TideBloc>().add(
                                  const RescueUndoRequested(),
                                ),
                                icon: const Icon(Icons.undo_rounded, size: 18),
                                label: const Text('Undo rescue'),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: GSpace.s2),
                        Hairline(
                          indent:
                              sizeClassOf(context) == GSizeClass.compact
                              ? GSpace.s4
                              : GSpace.s6,
                        ),
                        Expanded(
                          child: NoteStream(
                            notes: state.notes,
                            busyNoteIds: state.busyNoteIds,
                            haptic: haptic,
                            now: now,
                            onChanged: (edit) => context.read<TideBloc>().add(
                              NoteEditRequested(edit.id, edit.content),
                            ),
                            onRescue: (id) => context.read<TideBloc>().add(
                              NoteRescueRequested(id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
