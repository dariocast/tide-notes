import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TideLocalizations {
  const TideLocalizations(this.locale);

  final Locale locale;

  bool get isItalian => locale.languageCode == 'it';

  static TideLocalizations of(BuildContext context) =>
      Localizations.of<TideLocalizations>(context, TideLocalizations) ??
      const TideLocalizations(Locale('en'));

  String get appTitle => 'Tide';
  String get retry => isItalian ? 'Riprova' : 'Retry';
  String get emptyTitle =>
      isItalian ? 'Il tuo flusso è tranquillo.' : 'Your stream is quiet.';
  String get emptyBody => isItalian
      ? 'Cattura qualsiasi pensiero qui sopra. Aggiungi liberamente, rileggi ciò che affonda, riporta a galla ciò che conta ancora.'
      : 'Capture anything above. Append freely, review what sinks, rescue what still matters.';
  String get captureHint =>
      isItalian ? 'Cattura un pensiero…' : 'Capture a thought…';
  String get saveNote => isItalian ? 'Salva nota' : 'Save note';
  String get pasteFromClipboard =>
      isItalian ? 'Incolla dagli appunti' : 'Paste from clipboard';
  String get menu => isItalian ? 'Menu' : 'Menu';
  String get appearanceSettings =>
      isItalian ? 'Impostazioni aspetto' : 'Appearance settings';
  String get theme => isItalian ? 'Tema' : 'Theme';
  String get exportNotes => isItalian ? 'Esporta note' : 'Export notes';
  String get importNotes => isItalian ? 'Importa note' : 'Import notes';
  String get quickSubmit => isItalian ? 'Invio rapido' : 'Quick submit';
  String get deleteAllNotes =>
      isItalian ? 'Elimina tutte le note' : 'Delete all notes';
  String get deleteAllTitle =>
      isItalian ? 'Eliminare tutte le note?' : 'Delete all notes?';
  String get deleteAllBody => isItalian
      ? 'Questa azione eliminerà definitivamente tutte le note.'
      : 'This action will permanently delete all notes.';
  String get cancel => isItalian ? 'Annulla' : 'Cancel';
  String get deleteAll => isItalian ? 'Elimina tutto' : 'Delete all';
  String get language => isItalian ? 'Lingua' : 'Language';
  String get systemLanguage => isItalian ? 'Sistema' : 'System';
  String get italian => 'Italiano';
  String get english => 'English';
  String get versionLabel => isItalian ? 'Versione' : 'Version';
  String get undoRescue => isItalian ? 'Annulla emersione' : 'Undo rescue';
  String get rescueNote => isItalian ? 'Riporta a galla' : 'Rescue note';
  String get archiveNote => isItalian ? 'Archivia' : 'Archive';
  String get deleteNote => isItalian ? 'Elimina' : 'Delete';
  String get shareNote => isItalian ? 'Condividi' : 'Share';
  String get copyNote => isItalian ? 'Copia' : 'Copy';
  String get noteCopied => isItalian ? 'Nota copiata.' : 'Note copied.';
  String get editNote => isItalian ? 'Modifica nota' : 'Edit note';
  String get editPreviewEmpty =>
      isItalian ? 'L\'anteprima apparirà qui.' : 'Preview appears here.';
  String get searchNotes => isItalian ? 'Cerca note' : 'Search notes';
  String get searchHint => isItalian ? 'Cerca nelle note…' : 'Search notes…';
  String get clearSearch =>
      isItalian ? 'Cancella testo di ricerca' : 'Clear search text';
  String get closeSearch => isItalian ? 'Cancella' : 'Cancel';
  String get noSearchResultsTitle =>
      isItalian ? 'Nessuna nota trovata.' : 'No notes found.';
  String get noSearchResultsBody =>
      isItalian ? 'Prova con una ricerca diversa.' : 'Try a different search.';
  String get archiveTitle => isItalian ? 'Archivio' : 'Archive';
  String get archiveEmptyTitle =>
      isItalian ? 'L\'archivio è vuoto.' : 'Archive is empty.';
  String get archiveEmptyBody => isItalian
      ? 'Le note che archivi appariranno qui.'
      : 'Notes you archive will appear here.';
  String get deletedNotesTitle => isItalian ? 'Cestino' : 'Deleted Notes';
  String get deletedNotesEmptyTitle =>
      isItalian ? 'Il cestino è vuoto.' : 'Deleted Notes is empty.';
  String get deletedNotesEmptyBody => isItalian
      ? 'Le note che elimini appariranno qui.'
      : 'Notes you delete will appear here.';
  String get emptyTrash => isItalian ? 'Svuota cestino' : 'Empty trash';
  String get emptyTrashTitle =>
      isItalian ? 'Svuotare il cestino?' : 'Empty the trash?';
  String get emptyTrashBody => isItalian
      ? 'Questa azione eliminerà definitivamente tutte le note nel cestino.'
      : 'This will permanently delete every note in the trash.';
  String get statsTitle => isItalian ? 'Statistiche Tide' : 'Tide Stats';
  String get statsTotalNotes => isItalian ? 'Note totali' : 'Total notes';
  String get statsNotesPerDay => isItalian ? 'Note al giorno' : 'Notes per day';
  String get statsAverageRescues =>
      isItalian ? 'Emersioni medie' : 'Average rescues';
  String get statsRescuesPerDay =>
      isItalian ? 'Emersioni al giorno' : 'Rescues per day';
  String get statsLongestNote =>
      isItalian ? 'Nota più lunga (caratteri)' : 'Longest note (characters)';
  String get statsMostRescued =>
      isItalian ? 'Più riportata a galla' : 'Most rescued';
  String get statsFirstNote => isItalian ? 'Prima nota' : 'First note';
  String get statsTotalCharacters =>
      isItalian ? 'Caratteri totali' : 'Total characters';
  String get statsWordDistribution =>
      isItalian ? 'Distribuzione lunghezza parole' : 'Word count distribution';
  String get statsComputedLocally => isItalian
      ? 'Statistiche calcolate localmente.'
      : 'Stats are computed locally.';
  String get tutorialTitle =>
      isItalian ? 'Come funziona Tide' : 'How Tide Works';
  String get howTideWorks =>
      isItalian ? 'Come funziona Tide' : 'How Tide Works';
  String relativeSurfacedAge(DateTime surfacedAt, DateTime now) {
    final difference = now.difference(surfacedAt);
    if (difference.isNegative || difference.inMinutes < 1) {
      return isItalian ? 'ora' : 'now';
    }
    if (difference.inHours < 1) {
      return isItalian
          ? '${difference.inMinutes} min fa'
          : '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return isItalian
          ? '${difference.inHours} h fa'
          : '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return isItalian
          ? '${difference.inDays} g fa'
          : '${difference.inDays}d ago';
    }
    final weeks = difference.inDays ~/ 7;
    return isItalian ? '$weeks sett. fa' : '${weeks}w ago';
  }

  String notesCaptured(int count) {
    if (isItalian) {
      return count == 1 ? '1 nota catturata' : '$count note catturate';
    }
    return count == 1 ? '1 note captured' : '$count notes captured';
  }

  String message(String value) => switch (value) {
    'Rescued' => isItalian ? 'Riportata a galla' : 'Rescued',
    'Archived' => isItalian ? 'Archiviata' : 'Archived',
    'Deleted' => isItalian ? 'Eliminata' : 'Deleted',
    'Trash emptied.' => isItalian ? 'Cestino svuotato.' : value,
    "Couldn't archive note." =>
      isItalian ? 'Impossibile archiviare la nota.' : value,
    "Couldn't delete note." =>
      isItalian ? 'Impossibile eliminare la nota.' : value,
    "Couldn't restore note." =>
      isItalian ? 'Impossibile ripristinare la nota.' : value,
    "Couldn't empty the trash." =>
      isItalian ? 'Impossibile svuotare il cestino.' : value,
    "Couldn't load your stream." =>
      isItalian ? 'Impossibile caricare il flusso.' : value,
    "Couldn't load archive." =>
      isItalian ? "Impossibile caricare l'archivio." : value,
    "Couldn't load trash." =>
      isItalian ? 'Impossibile caricare il cestino.' : value,
    "Couldn't save note. Try again." =>
      isItalian ? 'Impossibile salvare la nota. Riprova.' : value,
    'All notes deleted.' =>
      isItalian ? 'Tutte le note sono state eliminate.' : value,
    "Couldn't delete notes. Try again." =>
      isItalian ? 'Impossibile eliminare le note. Riprova.' : value,
    'Notes exported.' => isItalian ? 'Note esportate.' : value,
    'Notes imported.' => isItalian ? 'Note importate.' : value,
    'No new notes imported.' =>
      isItalian ? 'Nessuna nuova nota importata.' : value,
    "Couldn't export notes. Try again." =>
      isItalian ? 'Impossibile esportare le note. Riprova.' : value,
    "Couldn't import notes. Try again." =>
      isItalian ? 'Impossibile importare le note. Riprova.' : value,
    "Couldn't rescue note." =>
      isItalian ? 'Impossibile riportare a galla la nota.' : value,
    'Note copied.' => isItalian ? 'Nota copiata.' : value,
    _ => value,
  };
}

class TideLocalizationsDelegate
    extends LocalizationsDelegate<TideLocalizations> {
  const TideLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['en', 'it'].contains(locale.languageCode);

  @override
  Future<TideLocalizations> load(Locale locale) =>
      SynchronousFuture(TideLocalizations(locale));

  @override
  bool shouldReload(TideLocalizationsDelegate old) => false;
}
