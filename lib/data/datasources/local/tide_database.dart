import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'tide_database.g.dart';

class NoteRecords extends Table {
  TextColumn get id => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get surfacedAt => dateTime()();

  IntColumn get rescueCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [NoteRecords])
class TideDatabase extends _$TideDatabase {
  TideDatabase() : super(driftDatabase(name: 'tide'));

  TideDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
