import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      final hasUndo = message == 'Rescued' && state.rescueReceipt != null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: hasUndo
                ? SnackBarAction(
                    label: 'Undo',
                    onPressed: () => context.read<TideBloc>().add(
                      const RescueUndoRequested(),
                    ),
                  )
                : null,
          ),
        );
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
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              key: const ValueKey('tide-shell'),
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  TideHeader(noteCount: state.notes.length, now: now()),
                  NoteComposer(
                    appendCompleted: state.appendCompleted,
                    onSubmit: (content) => context.read<TideBloc>().add(
                      NoteAppendRequested(content),
                    ),
                  ),
                  Expanded(
                    child: NoteStream(
                      notes: state.notes,
                      busyNoteIds: state.busyNoteIds,
                      haptic: haptic,
                      onChanged: (edit) => context.read<TideBloc>().add(
                        NoteEditRequested(edit.id, edit.content),
                      ),
                      onRescue: (id) =>
                          context.read<TideBloc>().add(NoteRescueRequested(id)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
