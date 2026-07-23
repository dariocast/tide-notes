import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/design_helpers.dart';
import '../../design/appearance_controller.dart';
import '../../design/tide_icons.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../widgets/note_card.dart';
import '../widgets/note_composer.dart';
import '../widgets/note_stream.dart';
import '../widgets/tide_header.dart';
import '../widgets/tide_shell.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
                icon: const FaIcon(TideIcons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ),
        );
      }

      return Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: TideShell(
              header: TideHeader(
                noteCount: state.notes.length,
                now: now(),
                onExport: () => context.read<TideBloc>().add(
                  NotesExportRequested(state.notes),
                ),
                onDeleteAll: () => context.read<TideBloc>().add(
                  const NotesDeleteAllRequested(),
                ),
              ),
              composer: NoteComposer(
                appendCompleted: state.appendCompleted,
                submitOnEnter:
                    AppearanceScope.maybeOf(context)?.submitOnEnter ?? false,
                onSubmit: (content) =>
                    context.read<TideBloc>().add(NoteAppendRequested(content)),
              ),
              undoAction: const SizedBox.shrink(),
              stream: NoteStream(
                notes: state.notes,
                busyNoteIds: state.busyNoteIds,
                haptic: haptic,
                now: now,
                undoNoteId: state.rescueReceipt?.noteId,
                onUndo: () =>
                    context.read<TideBloc>().add(const RescueUndoRequested()),
                onChanged: (edit) => context.read<TideBloc>().add(
                  NoteEditRequested(edit.id, edit.content),
                ),
                onRescue: (id) =>
                    context.read<TideBloc>().add(NoteRescueRequested(id)),
              ),
            ),
          ),
        ),
      );
    },
  );
}
