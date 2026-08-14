import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../../design/appearance_controller.dart';
import '../../core/utils/note_importer.dart';
import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../domain/entities/note.dart';
import '../../l10n/tide_localizations.dart';
import '../blocs/tide_bloc.dart';
import '../blocs/tide_event.dart';
import '../blocs/tide_state.dart';
import '../search/note_search.dart';
import '../widgets/note_card.dart';
import '../widgets/note_composer.dart';
import '../widgets/note_stream.dart';
import '../widgets/tide_header.dart';
import '../widgets/tide_search_header.dart';
import '../widgets/tide_shell.dart';

DateTime defaultTideNow() => DateTime.now();
typedef PickTideImportFile = Future<List<int>?> Function();

Future<List<int>?> defaultPickTideImportFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Tide notes',
        extensions: ['tide', 'json'],
        mimeTypes: ['application/json'],
      ),
    ],
  );
  return file?.readAsBytes();
}

class TidePage extends StatefulWidget {
  const TidePage({
    super.key,
    this.haptic = defaultTideHaptic,
    this.now = defaultTideNow,
    this.pickImportFile = defaultPickTideImportFile,
  });

  final VoidCallback haptic;
  final DateTime Function() now;
  final PickTideImportFile pickImportFile;

  @override
  State<TidePage> createState() => _TidePageState();
}

class _TidePageState extends State<TidePage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _searchChanged(String value) => setState(() {});

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _searching = false);
  }

  Future<void> _importNotes() async {
    try {
      final bytes = await widget.pickImportFile();
      if (bytes == null || !mounted) return;
      final notes = const NoteImporter().parse(bytes);
      if (notes.isNotEmpty) {
        context.read<TideBloc>().add(NotesImportRequested(notes));
      }
    } on FormatException {
      if (mounted) context.read<TideBloc>().add(const NotesImportFailed());
    } catch (_) {
      if (mounted) context.read<TideBloc>().add(const NotesImportFailed());
    }
  }

  Note? _findNote(String id, TideState state) {
    final matches = [
      ...state.notes,
      ...state.archivedNotes,
    ].where((note) => note.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _shareNote(String id, TideState state) async {
    final note = _findNote(id, state);
    if (note == null) return;
    await SharePlus.instance.share(ShareParams(text: note.content));
  }

  Future<void> _copyNote(
    String id,
    TideState state,
    BuildContext context,
  ) async {
    final note = _findNote(id, state);
    if (note == null) return;
    await Clipboard.setData(ClipboardData(text: note.content));
    if (!context.mounted) return;
    context.read<TideBloc>().add(const TideMessageAcknowledged());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(TideLocalizations.of(context).noteCopied)),
      );
  }

  Widget _buildHeader(BuildContext context, TideState state) {
    final header = _searching
        ? TideSearchHeader(
            key: const ValueKey('active-search-header'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _searchChanged,
            onClear: _clearSearch,
            onClose: _closeSearch,
          )
        : TideHeader(
            key: const ValueKey('regular-header'),
            noteCount: state.notes.length,
            now: widget.now(),
            onSearch: _openSearch,
            onExport: () =>
                context.read<TideBloc>().add(NotesExportRequested(state.notes)),
            onImport: _importNotes,
            onDeleteAll: () =>
                context.read<TideBloc>().add(const NotesDeleteAllRequested()),
          );
    if (context.motion.reduceMotion) return header;

    return AnimatedSize(
      duration: context.motion.duration(GMotion.reveal),
      curve: GMotion.settle,
      child: AnimatedSwitcher(
        duration: context.motion.duration(GMotion.reveal),
        switchInCurve: GMotion.settle,
        switchOutCurve: GMotion.settle,
        child: header,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<TideBloc, TideState>(
    listener: (context, state) {
      final l10n = TideLocalizations.of(context);
      final message = state.message;
      if (message == null) return;
      if (message == 'Rescued' ||
          message == 'Archived' ||
          message == 'Deleted') {
        context.read<TideBloc>().add(const TideMessageAcknowledged());
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.message(message))));
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
                label: Text(TideLocalizations.of(context).retry),
              ),
            ),
          ),
        );
      }

      final visibleNotes = _searching
          ? filterNotesByContent(state.notes, _searchController.text)
          : state.notes;
      final showNoSearchResults =
          _searching &&
          _searchController.text.trim().isNotEmpty &&
          visibleNotes.isEmpty;

      return Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: TideShell(
              header: _buildHeader(context, state),
              searching: _searching,
              composer: NoteComposer(
                appendCompleted: state.appendCompleted,
                submitOnEnter:
                    AppearanceScope.maybeOf(context)?.submitOnEnter ?? false,
                onSubmit: (content) =>
                    context.read<TideBloc>().add(NoteAppendRequested(content)),
              ),
              undoAction: const SizedBox.shrink(),
              stream: NoteStream(
                notes: visibleNotes,
                showNoSearchResults: showNoSearchResults,
                busyNoteIds: state.busyNoteIds,
                haptic: widget.haptic,
                now: widget.now,
                undoNoteId:
                    state.rescueReceipt?.noteId ??
                    state.archiveReceipt?.noteId ??
                    state.deleteReceipt?.noteId,
                onUndo: () {
                  final bloc = context.read<TideBloc>();
                  if (state.rescueReceipt != null) {
                    bloc.add(const RescueUndoRequested());
                  } else if (state.archiveReceipt != null) {
                    bloc.add(const ArchiveUndoRequested());
                  } else if (state.deleteReceipt != null) {
                    bloc.add(const DeleteUndoRequested());
                  }
                },
                onChanged: (edit) => context.read<TideBloc>().add(
                  NoteEditRequested(edit.id, edit.content),
                ),
                onRescue: (id) =>
                    context.read<TideBloc>().add(NoteRescueRequested(id)),
                onArchive: (id) =>
                    context.read<TideBloc>().add(NoteArchiveRequested(id)),
                onDelete: (id) =>
                    context.read<TideBloc>().add(NoteDeleteRequested(id)),
                onShare: (id) => _shareNote(id, state),
                onCopy: (id) => _copyNote(id, state, context),
              ),
            ),
          ),
        ),
      );
    },
  );
}
