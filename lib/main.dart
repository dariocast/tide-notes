import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'design/appearance_controller.dart';
import 'data/datasources/local/tide_database.dart';
import 'data/repositories/local_note_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/usecases/append_note.dart';
import 'domain/usecases/edit_note.dart';
import 'domain/usecases/delete_all_notes.dart';
import 'domain/usecases/rescue_note.dart';
import 'domain/usecases/undo_rescue.dart';
import 'domain/usecases/watch_notes.dart';
import 'presentation/blocs/tide_bloc.dart';
import 'presentation/blocs/tide_event.dart';
import 'presentation/pages/tide_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = await AppearanceController.load();
  runApp(TideBootstrap(appearance: appearance));
}

class TideBootstrap extends StatefulWidget {
  const TideBootstrap({super.key, required this.appearance});

  final AppearanceController appearance;

  @override
  State<TideBootstrap> createState() => _TideBootstrapState();
}

class _TideBootstrapState extends State<TideBootstrap> {
  late final TideDatabase database = TideDatabase();
  late final NoteRepository repository = LocalNoteRepository(database);
  final Uuid uuid = const Uuid();

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<NoteRepository>.value(
        value: repository,
        child: BlocProvider(
          create: (_) => TideBloc(
            watchNotes: WatchNotes(repository),
            appendNote: AppendNote(
              repository,
              now: DateTime.now,
              newId: uuid.v4,
            ),
            editNote: EditNote(repository, now: DateTime.now),
            rescueNote: RescueNote(repository, now: DateTime.now),
            undoRescue: UndoRescue(repository),
            deleteAllNotes: DeleteAllNotes(repository),
          )..add(const TideStarted()),
          child: TideApp(home: const TidePage(), appearance: widget.appearance),
        ),
      );

  @override
  void dispose() {
    database.close();
    super.dispose();
  }
}
