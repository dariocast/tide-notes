// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tide_database.dart';

// ignore_for_file: type=lint
class $NoteRecordsTable extends NoteRecords
    with TableInfo<$NoteRecordsTable, NoteRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surfacedAtMeta = const VerificationMeta(
    'surfacedAt',
  );
  @override
  late final GeneratedColumn<DateTime> surfacedAt = GeneratedColumn<DateTime>(
    'surfaced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rescueCountMeta = const VerificationMeta(
    'rescueCount',
  );
  @override
  late final GeneratedColumn<int> rescueCount = GeneratedColumn<int>(
    'rescue_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    createdAt,
    updatedAt,
    surfacedAt,
    rescueCount,
    archivedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('surfaced_at')) {
      context.handle(
        _surfacedAtMeta,
        surfacedAt.isAcceptableOrUnknown(data['surfaced_at']!, _surfacedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_surfacedAtMeta);
    }
    if (data.containsKey('rescue_count')) {
      context.handle(
        _rescueCountMeta,
        rescueCount.isAcceptableOrUnknown(
          data['rescue_count']!,
          _rescueCountMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      surfacedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}surfaced_at'],
      )!,
      rescueCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rescue_count'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $NoteRecordsTable createAlias(String alias) {
    return $NoteRecordsTable(attachedDatabase, alias);
  }
}

class NoteRecord extends DataClass implements Insertable<NoteRecord> {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime surfacedAt;
  final int rescueCount;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  const NoteRecord({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.surfacedAt,
    required this.rescueCount,
    this.archivedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['surfaced_at'] = Variable<DateTime>(surfacedAt);
    map['rescue_count'] = Variable<int>(rescueCount);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  NoteRecordsCompanion toCompanion(bool nullToAbsent) {
    return NoteRecordsCompanion(
      id: Value(id),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      surfacedAt: Value(surfacedAt),
      rescueCount: Value(rescueCount),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory NoteRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRecord(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      surfacedAt: serializer.fromJson<DateTime>(json['surfacedAt']),
      rescueCount: serializer.fromJson<int>(json['rescueCount']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'surfacedAt': serializer.toJson<DateTime>(surfacedAt),
      'rescueCount': serializer.toJson<int>(rescueCount),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  NoteRecord copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? surfacedAt,
    int? rescueCount,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => NoteRecord(
    id: id ?? this.id,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    surfacedAt: surfacedAt ?? this.surfacedAt,
    rescueCount: rescueCount ?? this.rescueCount,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  NoteRecord copyWithCompanion(NoteRecordsCompanion data) {
    return NoteRecord(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      surfacedAt: data.surfacedAt.present
          ? data.surfacedAt.value
          : this.surfacedAt,
      rescueCount: data.rescueCount.present
          ? data.rescueCount.value
          : this.rescueCount,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRecord(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('surfacedAt: $surfacedAt, ')
          ..write('rescueCount: $rescueCount, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    createdAt,
    updatedAt,
    surfacedAt,
    rescueCount,
    archivedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRecord &&
          other.id == this.id &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.surfacedAt == this.surfacedAt &&
          other.rescueCount == this.rescueCount &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt);
}

class NoteRecordsCompanion extends UpdateCompanion<NoteRecord> {
  final Value<String> id;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> surfacedAt;
  final Value<int> rescueCount;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const NoteRecordsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.surfacedAt = const Value.absent(),
    this.rescueCount = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteRecordsCompanion.insert({
    required String id,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime surfacedAt,
    this.rescueCount = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       surfacedAt = Value(surfacedAt);
  static Insertable<NoteRecord> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? surfacedAt,
    Expression<int>? rescueCount,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (surfacedAt != null) 'surfaced_at': surfacedAt,
      if (rescueCount != null) 'rescue_count': rescueCount,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? surfacedAt,
    Value<int>? rescueCount,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return NoteRecordsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      surfacedAt: surfacedAt ?? this.surfacedAt,
      rescueCount: rescueCount ?? this.rescueCount,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (surfacedAt.present) {
      map['surfaced_at'] = Variable<DateTime>(surfacedAt.value);
    }
    if (rescueCount.present) {
      map['rescue_count'] = Variable<int>(rescueCount.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteRecordsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('surfacedAt: $surfacedAt, ')
          ..write('rescueCount: $rescueCount, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TideDatabase extends GeneratedDatabase {
  _$TideDatabase(QueryExecutor e) : super(e);
  $TideDatabaseManager get managers => $TideDatabaseManager(this);
  late final $NoteRecordsTable noteRecords = $NoteRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [noteRecords];
}

typedef $$NoteRecordsTableCreateCompanionBuilder =
    NoteRecordsCompanion Function({
      required String id,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime surfacedAt,
      Value<int> rescueCount,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$NoteRecordsTableUpdateCompanionBuilder =
    NoteRecordsCompanion Function({
      Value<String> id,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> surfacedAt,
      Value<int> rescueCount,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$NoteRecordsTableFilterComposer
    extends Composer<_$TideDatabase, $NoteRecordsTable> {
  $$NoteRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get surfacedAt => $composableBuilder(
    column: $table.surfacedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rescueCount => $composableBuilder(
    column: $table.rescueCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteRecordsTableOrderingComposer
    extends Composer<_$TideDatabase, $NoteRecordsTable> {
  $$NoteRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get surfacedAt => $composableBuilder(
    column: $table.surfacedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rescueCount => $composableBuilder(
    column: $table.rescueCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteRecordsTableAnnotationComposer
    extends Composer<_$TideDatabase, $NoteRecordsTable> {
  $$NoteRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get surfacedAt => $composableBuilder(
    column: $table.surfacedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rescueCount => $composableBuilder(
    column: $table.rescueCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$NoteRecordsTableTableManager
    extends
        RootTableManager<
          _$TideDatabase,
          $NoteRecordsTable,
          NoteRecord,
          $$NoteRecordsTableFilterComposer,
          $$NoteRecordsTableOrderingComposer,
          $$NoteRecordsTableAnnotationComposer,
          $$NoteRecordsTableCreateCompanionBuilder,
          $$NoteRecordsTableUpdateCompanionBuilder,
          (
            NoteRecord,
            BaseReferences<_$TideDatabase, $NoteRecordsTable, NoteRecord>,
          ),
          NoteRecord,
          PrefetchHooks Function()
        > {
  $$NoteRecordsTableTableManager(_$TideDatabase db, $NoteRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> surfacedAt = const Value.absent(),
                Value<int> rescueCount = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteRecordsCompanion(
                id: id,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                surfacedAt: surfacedAt,
                rescueCount: rescueCount,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime surfacedAt,
                Value<int> rescueCount = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteRecordsCompanion.insert(
                id: id,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                surfacedAt: surfacedAt,
                rescueCount: rescueCount,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$TideDatabase,
      $NoteRecordsTable,
      NoteRecord,
      $$NoteRecordsTableFilterComposer,
      $$NoteRecordsTableOrderingComposer,
      $$NoteRecordsTableAnnotationComposer,
      $$NoteRecordsTableCreateCompanionBuilder,
      $$NoteRecordsTableUpdateCompanionBuilder,
      (
        NoteRecord,
        BaseReferences<_$TideDatabase, $NoteRecordsTable, NoteRecord>,
      ),
      NoteRecord,
      PrefetchHooks Function()
    >;

class $TideDatabaseManager {
  final _$TideDatabase _db;
  $TideDatabaseManager(this._db);
  $$NoteRecordsTableTableManager get noteRecords =>
      $$NoteRecordsTableTableManager(_db, _db.noteRecords);
}
