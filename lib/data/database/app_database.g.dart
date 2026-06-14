// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final String name;
  final DateTime createdAt;
  const Folder({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith({int? id, String? name, DateTime? createdAt}) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PromptsTable extends Prompts with TableInfo<$PromptsTable, Prompt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _modelTagsMeta = const VerificationMeta(
    'modelTags',
  );
  @override
  late final GeneratedColumn<String> modelTags = GeneratedColumn<String>(
    'model_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isStarterMeta = const VerificationMeta(
    'isStarter',
  );
  @override
  late final GeneratedColumn<bool> isStarter = GeneratedColumn<bool>(
    'is_starter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    folderId,
    modelTags,
    pinned,
    isStarter,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prompt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('model_tags')) {
      context.handle(
        _modelTagsMeta,
        modelTags.isAcceptableOrUnknown(data['model_tags']!, _modelTagsMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('is_starter')) {
      context.handle(
        _isStarterMeta,
        isStarter.isAcceptableOrUnknown(data['is_starter']!, _isStarterMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prompt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prompt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      modelTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_tags'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      isStarter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starter'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PromptsTable createAlias(String alias) {
    return $PromptsTable(attachedDatabase, alias);
  }
}

class Prompt extends DataClass implements Insertable<Prompt> {
  final int id;
  final String title;
  final String body;
  final int? folderId;
  final String modelTags;
  final bool pinned;
  final bool isStarter;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Prompt({
    required this.id,
    required this.title,
    required this.body,
    this.folderId,
    required this.modelTags,
    required this.pinned,
    required this.isStarter,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['model_tags'] = Variable<String>(modelTags);
    map['pinned'] = Variable<bool>(pinned);
    map['is_starter'] = Variable<bool>(isStarter);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PromptsCompanion toCompanion(bool nullToAbsent) {
    return PromptsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      isStarter: Value(isStarter),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Prompt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prompt(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      modelTags: serializer.fromJson<String>(json['modelTags']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      isStarter: serializer.fromJson<bool>(json['isStarter']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'folderId': serializer.toJson<int?>(folderId),
      'modelTags': serializer.toJson<String>(modelTags),
      'pinned': serializer.toJson<bool>(pinned),
      'isStarter': serializer.toJson<bool>(isStarter),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Prompt copyWith({
    int? id,
    String? title,
    String? body,
    Value<int?> folderId = const Value.absent(),
    String? modelTags,
    bool? pinned,
    bool? isStarter,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Prompt(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    folderId: folderId.present ? folderId.value : this.folderId,
    modelTags: modelTags ?? this.modelTags,
    pinned: pinned ?? this.pinned,
    isStarter: isStarter ?? this.isStarter,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Prompt copyWithCompanion(PromptsCompanion data) {
    return Prompt(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      modelTags: data.modelTags.present ? data.modelTags.value : this.modelTags,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      isStarter: data.isStarter.present ? data.isStarter.value : this.isStarter,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prompt(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('folderId: $folderId, ')
          ..write('modelTags: $modelTags, ')
          ..write('pinned: $pinned, ')
          ..write('isStarter: $isStarter, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    folderId,
    modelTags,
    pinned,
    isStarter,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prompt &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.folderId == this.folderId &&
          other.modelTags == this.modelTags &&
          other.pinned == this.pinned &&
          other.isStarter == this.isStarter &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PromptsCompanion extends UpdateCompanion<Prompt> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<int?> folderId;
  final Value<String> modelTags;
  final Value<bool> pinned;
  final Value<bool> isStarter;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PromptsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.folderId = const Value.absent(),
    this.modelTags = const Value.absent(),
    this.pinned = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PromptsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    this.folderId = const Value.absent(),
    this.modelTags = const Value.absent(),
    this.pinned = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       body = Value(body);
  static Insertable<Prompt> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? folderId,
    Expression<String>? modelTags,
    Expression<bool>? pinned,
    Expression<bool>? isStarter,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (folderId != null) 'folder_id': folderId,
      if (modelTags != null) 'model_tags': modelTags,
      if (pinned != null) 'pinned': pinned,
      if (isStarter != null) 'is_starter': isStarter,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PromptsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? body,
    Value<int?>? folderId,
    Value<String>? modelTags,
    Value<bool>? pinned,
    Value<bool>? isStarter,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PromptsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      folderId: folderId ?? this.folderId,
      modelTags: modelTags ?? this.modelTags,
      pinned: pinned ?? this.pinned,
      isStarter: isStarter ?? this.isStarter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (modelTags.present) {
      map['model_tags'] = Variable<String>(modelTags.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (isStarter.present) {
      map['is_starter'] = Variable<bool>(isStarter.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('folderId: $folderId, ')
          ..write('modelTags: $modelTags, ')
          ..write('pinned: $pinned, ')
          ..write('isStarter: $isStarter, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PromptVariablesTable extends PromptVariables
    with TableInfo<$PromptVariablesTable, PromptVariable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptVariablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _promptIdMeta = const VerificationMeta(
    'promptId',
  );
  @override
  late final GeneratedColumn<int> promptId = GeneratedColumn<int>(
    'prompt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prompts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _defaultValueMeta = const VerificationMeta(
    'defaultValue',
  );
  @override
  late final GeneratedColumn<String> defaultValue = GeneratedColumn<String>(
    'default_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    promptId,
    name,
    type,
    defaultValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompt_variables';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromptVariable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prompt_id')) {
      context.handle(
        _promptIdMeta,
        promptId.isAcceptableOrUnknown(data['prompt_id']!, _promptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_promptIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('default_value')) {
      context.handle(
        _defaultValueMeta,
        defaultValue.isAcceptableOrUnknown(
          data['default_value']!,
          _defaultValueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromptVariable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromptVariable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      promptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      defaultValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_value'],
      )!,
    );
  }

  @override
  $PromptVariablesTable createAlias(String alias) {
    return $PromptVariablesTable(attachedDatabase, alias);
  }
}

class PromptVariable extends DataClass implements Insertable<PromptVariable> {
  final int id;
  final int promptId;
  final String name;
  final String type;
  final String defaultValue;
  const PromptVariable({
    required this.id,
    required this.promptId,
    required this.name,
    required this.type,
    required this.defaultValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prompt_id'] = Variable<int>(promptId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['default_value'] = Variable<String>(defaultValue);
    return map;
  }

  PromptVariablesCompanion toCompanion(bool nullToAbsent) {
    return PromptVariablesCompanion(
      id: Value(id),
      promptId: Value(promptId),
      name: Value(name),
      type: Value(type),
      defaultValue: Value(defaultValue),
    );
  }

  factory PromptVariable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromptVariable(
      id: serializer.fromJson<int>(json['id']),
      promptId: serializer.fromJson<int>(json['promptId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      defaultValue: serializer.fromJson<String>(json['defaultValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'promptId': serializer.toJson<int>(promptId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'defaultValue': serializer.toJson<String>(defaultValue),
    };
  }

  PromptVariable copyWith({
    int? id,
    int? promptId,
    String? name,
    String? type,
    String? defaultValue,
  }) => PromptVariable(
    id: id ?? this.id,
    promptId: promptId ?? this.promptId,
    name: name ?? this.name,
    type: type ?? this.type,
    defaultValue: defaultValue ?? this.defaultValue,
  );
  PromptVariable copyWithCompanion(PromptVariablesCompanion data) {
    return PromptVariable(
      id: data.id.present ? data.id.value : this.id,
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromptVariable(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('defaultValue: $defaultValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, promptId, name, type, defaultValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromptVariable &&
          other.id == this.id &&
          other.promptId == this.promptId &&
          other.name == this.name &&
          other.type == this.type &&
          other.defaultValue == this.defaultValue);
}

class PromptVariablesCompanion extends UpdateCompanion<PromptVariable> {
  final Value<int> id;
  final Value<int> promptId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> defaultValue;
  const PromptVariablesCompanion({
    this.id = const Value.absent(),
    this.promptId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.defaultValue = const Value.absent(),
  });
  PromptVariablesCompanion.insert({
    this.id = const Value.absent(),
    required int promptId,
    required String name,
    this.type = const Value.absent(),
    this.defaultValue = const Value.absent(),
  }) : promptId = Value(promptId),
       name = Value(name);
  static Insertable<PromptVariable> custom({
    Expression<int>? id,
    Expression<int>? promptId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? defaultValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promptId != null) 'prompt_id': promptId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (defaultValue != null) 'default_value': defaultValue,
    });
  }

  PromptVariablesCompanion copyWith({
    Value<int>? id,
    Value<int>? promptId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? defaultValue,
  }) {
    return PromptVariablesCompanion(
      id: id ?? this.id,
      promptId: promptId ?? this.promptId,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (promptId.present) {
      map['prompt_id'] = Variable<int>(promptId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<String>(defaultValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptVariablesCompanion(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('defaultValue: $defaultValue')
          ..write(')'))
        .toString();
  }
}

class $UsageStatsTable extends UsageStats
    with TableInfo<$UsageStatsTable, UsageStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _promptIdMeta = const VerificationMeta(
    'promptId',
  );
  @override
  late final GeneratedColumn<int> promptId = GeneratedColumn<int>(
    'prompt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prompts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    promptId,
    packageName,
    count,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prompt_id')) {
      context.handle(
        _promptIdMeta,
        promptId.isAcceptableOrUnknown(data['prompt_id']!, _promptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_promptIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      promptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $UsageStatsTable createAlias(String alias) {
    return $UsageStatsTable(attachedDatabase, alias);
  }
}

class UsageStat extends DataClass implements Insertable<UsageStat> {
  final int id;
  final int promptId;
  final String packageName;
  final int count;
  final DateTime lastUsedAt;
  const UsageStat({
    required this.id,
    required this.promptId,
    required this.packageName,
    required this.count,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prompt_id'] = Variable<int>(promptId);
    map['package_name'] = Variable<String>(packageName);
    map['count'] = Variable<int>(count);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  UsageStatsCompanion toCompanion(bool nullToAbsent) {
    return UsageStatsCompanion(
      id: Value(id),
      promptId: Value(promptId),
      packageName: Value(packageName),
      count: Value(count),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory UsageStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageStat(
      id: serializer.fromJson<int>(json['id']),
      promptId: serializer.fromJson<int>(json['promptId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      count: serializer.fromJson<int>(json['count']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'promptId': serializer.toJson<int>(promptId),
      'packageName': serializer.toJson<String>(packageName),
      'count': serializer.toJson<int>(count),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  UsageStat copyWith({
    int? id,
    int? promptId,
    String? packageName,
    int? count,
    DateTime? lastUsedAt,
  }) => UsageStat(
    id: id ?? this.id,
    promptId: promptId ?? this.promptId,
    packageName: packageName ?? this.packageName,
    count: count ?? this.count,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  UsageStat copyWithCompanion(UsageStatsCompanion data) {
    return UsageStat(
      id: data.id.present ? data.id.value : this.id,
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      count: data.count.present ? data.count.value : this.count,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageStat(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('packageName: $packageName, ')
          ..write('count: $count, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, promptId, packageName, count, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageStat &&
          other.id == this.id &&
          other.promptId == this.promptId &&
          other.packageName == this.packageName &&
          other.count == this.count &&
          other.lastUsedAt == this.lastUsedAt);
}

class UsageStatsCompanion extends UpdateCompanion<UsageStat> {
  final Value<int> id;
  final Value<int> promptId;
  final Value<String> packageName;
  final Value<int> count;
  final Value<DateTime> lastUsedAt;
  const UsageStatsCompanion({
    this.id = const Value.absent(),
    this.promptId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.count = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  UsageStatsCompanion.insert({
    this.id = const Value.absent(),
    required int promptId,
    required String packageName,
    this.count = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  }) : promptId = Value(promptId),
       packageName = Value(packageName);
  static Insertable<UsageStat> custom({
    Expression<int>? id,
    Expression<int>? promptId,
    Expression<String>? packageName,
    Expression<int>? count,
    Expression<DateTime>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promptId != null) 'prompt_id': promptId,
      if (packageName != null) 'package_name': packageName,
      if (count != null) 'count': count,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  UsageStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? promptId,
    Value<String>? packageName,
    Value<int>? count,
    Value<DateTime>? lastUsedAt,
  }) {
    return UsageStatsCompanion(
      id: id ?? this.id,
      promptId: promptId ?? this.promptId,
      packageName: packageName ?? this.packageName,
      count: count ?? this.count,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (promptId.present) {
      map['prompt_id'] = Variable<int>(promptId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageStatsCompanion(')
          ..write('id: $id, ')
          ..write('promptId: $promptId, ')
          ..write('packageName: $packageName, ')
          ..write('count: $count, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $PromptTagsTable extends PromptTags
    with TableInfo<$PromptTagsTable, PromptTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _promptIdMeta = const VerificationMeta(
    'promptId',
  );
  @override
  late final GeneratedColumn<int> promptId = GeneratedColumn<int>(
    'prompt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [promptId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompt_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromptTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prompt_id')) {
      context.handle(
        _promptIdMeta,
        promptId.isAcceptableOrUnknown(data['prompt_id']!, _promptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_promptIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {promptId, tagId};
  @override
  PromptTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromptTag(
      promptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $PromptTagsTable createAlias(String alias) {
    return $PromptTagsTable(attachedDatabase, alias);
  }
}

class PromptTag extends DataClass implements Insertable<PromptTag> {
  final int promptId;
  final int tagId;
  const PromptTag({required this.promptId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prompt_id'] = Variable<int>(promptId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  PromptTagsCompanion toCompanion(bool nullToAbsent) {
    return PromptTagsCompanion(promptId: Value(promptId), tagId: Value(tagId));
  }

  factory PromptTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromptTag(
      promptId: serializer.fromJson<int>(json['promptId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'promptId': serializer.toJson<int>(promptId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  PromptTag copyWith({int? promptId, int? tagId}) => PromptTag(
    promptId: promptId ?? this.promptId,
    tagId: tagId ?? this.tagId,
  );
  PromptTag copyWithCompanion(PromptTagsCompanion data) {
    return PromptTag(
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromptTag(')
          ..write('promptId: $promptId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(promptId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromptTag &&
          other.promptId == this.promptId &&
          other.tagId == this.tagId);
}

class PromptTagsCompanion extends UpdateCompanion<PromptTag> {
  final Value<int> promptId;
  final Value<int> tagId;
  final Value<int> rowid;
  const PromptTagsCompanion({
    this.promptId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromptTagsCompanion.insert({
    required int promptId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : promptId = Value(promptId),
       tagId = Value(tagId);
  static Insertable<PromptTag> custom({
    Expression<int>? promptId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (promptId != null) 'prompt_id': promptId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromptTagsCompanion copyWith({
    Value<int>? promptId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return PromptTagsCompanion(
      promptId: promptId ?? this.promptId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (promptId.present) {
      map['prompt_id'] = Variable<int>(promptId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptTagsCompanion(')
          ..write('promptId: $promptId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $PromptsTable prompts = $PromptsTable(this);
  late final $PromptVariablesTable promptVariables = $PromptVariablesTable(
    this,
  );
  late final $UsageStatsTable usageStats = $UsageStatsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $PromptTagsTable promptTags = $PromptTagsTable(this);
  late final PromptDao promptDao = PromptDao(this as AppDatabase);
  late final UsageDao usageDao = UsageDao(this as AppDatabase);
  late final FolderDao folderDao = FolderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folders,
    prompts,
    promptVariables,
    usageStats,
    tags,
    promptTags,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prompts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prompt_variables', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prompts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('usage_stats', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PromptsTable, List<Prompt>> _promptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.prompts,
    aliasName: $_aliasNameGenerator(db.folders.id, db.prompts.folderId),
  );

  $$PromptsTableProcessedTableManager get promptsRefs {
    final manager = $$PromptsTableTableManager(
      $_db,
      $_db.prompts,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_promptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> promptsRefs(
    Expression<bool> Function($$PromptsTableFilterComposer f) f,
  ) {
    final $$PromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableFilterComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> promptsRefs<T extends Object>(
    Expression<T> Function($$PromptsTableAnnotationComposer a) f,
  ) {
    final $$PromptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableAnnotationComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool promptsRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoldersCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (promptsRefs) db.prompts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (promptsRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, Prompt>(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences
                          ._promptsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FoldersTableReferences(db, table, p0).promptsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool promptsRefs})
    >;
typedef $$PromptsTableCreateCompanionBuilder =
    PromptsCompanion Function({
      Value<int> id,
      required String title,
      required String body,
      Value<int?> folderId,
      Value<String> modelTags,
      Value<bool> pinned,
      Value<bool> isStarter,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PromptsTableUpdateCompanionBuilder =
    PromptsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> body,
      Value<int?> folderId,
      Value<String> modelTags,
      Value<bool> pinned,
      Value<bool> isStarter,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PromptsTableReferences
    extends BaseReferences<_$AppDatabase, $PromptsTable, Prompt> {
  $$PromptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) => db.folders
      .createAlias($_aliasNameGenerator(db.prompts.folderId, db.folders.id));

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PromptVariablesTable, List<PromptVariable>>
  _promptVariablesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.promptVariables,
    aliasName: $_aliasNameGenerator(db.prompts.id, db.promptVariables.promptId),
  );

  $$PromptVariablesTableProcessedTableManager get promptVariablesRefs {
    final manager = $$PromptVariablesTableTableManager(
      $_db,
      $_db.promptVariables,
    ).filter((f) => f.promptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _promptVariablesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UsageStatsTable, List<UsageStat>>
  _usageStatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.usageStats,
    aliasName: $_aliasNameGenerator(db.prompts.id, db.usageStats.promptId),
  );

  $$UsageStatsTableProcessedTableManager get usageStatsRefs {
    final manager = $$UsageStatsTableTableManager(
      $_db,
      $_db.usageStats,
    ).filter((f) => f.promptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_usageStatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PromptsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelTags => $composableBuilder(
    column: $table.modelTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
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

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> promptVariablesRefs(
    Expression<bool> Function($$PromptVariablesTableFilterComposer f) f,
  ) {
    final $$PromptVariablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promptVariables,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptVariablesTableFilterComposer(
            $db: $db,
            $table: $db.promptVariables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> usageStatsRefs(
    Expression<bool> Function($$UsageStatsTableFilterComposer f) f,
  ) {
    final $$UsageStatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageStats,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageStatsTableFilterComposer(
            $db: $db,
            $table: $db.usageStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelTags => $composableBuilder(
    column: $table.modelTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
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

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get modelTags =>
      $composableBuilder(column: $table.modelTags, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get isStarter =>
      $composableBuilder(column: $table.isStarter, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> promptVariablesRefs<T extends Object>(
    Expression<T> Function($$PromptVariablesTableAnnotationComposer a) f,
  ) {
    final $$PromptVariablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.promptVariables,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptVariablesTableAnnotationComposer(
            $db: $db,
            $table: $db.promptVariables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> usageStatsRefs<T extends Object>(
    Expression<T> Function($$UsageStatsTableAnnotationComposer a) f,
  ) {
    final $$UsageStatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.usageStats,
      getReferencedColumn: (t) => t.promptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsageStatsTableAnnotationComposer(
            $db: $db,
            $table: $db.usageStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptsTable,
          Prompt,
          $$PromptsTableFilterComposer,
          $$PromptsTableOrderingComposer,
          $$PromptsTableAnnotationComposer,
          $$PromptsTableCreateCompanionBuilder,
          $$PromptsTableUpdateCompanionBuilder,
          (Prompt, $$PromptsTableReferences),
          Prompt,
          PrefetchHooks Function({
            bool folderId,
            bool promptVariablesRefs,
            bool usageStatsRefs,
          })
        > {
  $$PromptsTableTableManager(_$AppDatabase db, $PromptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> modelTags = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PromptsCompanion(
                id: id,
                title: title,
                body: body,
                folderId: folderId,
                modelTags: modelTags,
                pinned: pinned,
                isStarter: isStarter,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String body,
                Value<int?> folderId = const Value.absent(),
                Value<String> modelTags = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PromptsCompanion.insert(
                id: id,
                title: title,
                body: body,
                folderId: folderId,
                modelTags: modelTags,
                pinned: pinned,
                isStarter: isStarter,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PromptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                promptVariablesRefs = false,
                usageStatsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (promptVariablesRefs) db.promptVariables,
                    if (usageStatsRefs) db.usageStats,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$PromptsTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$PromptsTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (promptVariablesRefs)
                        await $_getPrefetchedData<
                          Prompt,
                          $PromptsTable,
                          PromptVariable
                        >(
                          currentTable: table,
                          referencedTable: $$PromptsTableReferences
                              ._promptVariablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PromptsTableReferences(
                                db,
                                table,
                                p0,
                              ).promptVariablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.promptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (usageStatsRefs)
                        await $_getPrefetchedData<
                          Prompt,
                          $PromptsTable,
                          UsageStat
                        >(
                          currentTable: table,
                          referencedTable: $$PromptsTableReferences
                              ._usageStatsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PromptsTableReferences(
                                db,
                                table,
                                p0,
                              ).usageStatsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.promptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptsTable,
      Prompt,
      $$PromptsTableFilterComposer,
      $$PromptsTableOrderingComposer,
      $$PromptsTableAnnotationComposer,
      $$PromptsTableCreateCompanionBuilder,
      $$PromptsTableUpdateCompanionBuilder,
      (Prompt, $$PromptsTableReferences),
      Prompt,
      PrefetchHooks Function({
        bool folderId,
        bool promptVariablesRefs,
        bool usageStatsRefs,
      })
    >;
typedef $$PromptVariablesTableCreateCompanionBuilder =
    PromptVariablesCompanion Function({
      Value<int> id,
      required int promptId,
      required String name,
      Value<String> type,
      Value<String> defaultValue,
    });
typedef $$PromptVariablesTableUpdateCompanionBuilder =
    PromptVariablesCompanion Function({
      Value<int> id,
      Value<int> promptId,
      Value<String> name,
      Value<String> type,
      Value<String> defaultValue,
    });

final class $$PromptVariablesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PromptVariablesTable, PromptVariable> {
  $$PromptVariablesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PromptsTable _promptIdTable(_$AppDatabase db) =>
      db.prompts.createAlias(
        $_aliasNameGenerator(db.promptVariables.promptId, db.prompts.id),
      );

  $$PromptsTableProcessedTableManager get promptId {
    final $_column = $_itemColumn<int>('prompt_id')!;

    final manager = $$PromptsTableTableManager(
      $_db,
      $_db.prompts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_promptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PromptVariablesTableFilterComposer
    extends Composer<_$AppDatabase, $PromptVariablesTable> {
  $$PromptVariablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnFilters(column),
  );

  $$PromptsTableFilterComposer get promptId {
    final $$PromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableFilterComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVariablesTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptVariablesTable> {
  $$PromptVariablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$PromptsTableOrderingComposer get promptId {
    final $$PromptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableOrderingComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVariablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptVariablesTable> {
  $$PromptVariablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => column,
  );

  $$PromptsTableAnnotationComposer get promptId {
    final $$PromptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableAnnotationComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptVariablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptVariablesTable,
          PromptVariable,
          $$PromptVariablesTableFilterComposer,
          $$PromptVariablesTableOrderingComposer,
          $$PromptVariablesTableAnnotationComposer,
          $$PromptVariablesTableCreateCompanionBuilder,
          $$PromptVariablesTableUpdateCompanionBuilder,
          (PromptVariable, $$PromptVariablesTableReferences),
          PromptVariable,
          PrefetchHooks Function({bool promptId})
        > {
  $$PromptVariablesTableTableManager(
    _$AppDatabase db,
    $PromptVariablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptVariablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptVariablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptVariablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> promptId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> defaultValue = const Value.absent(),
              }) => PromptVariablesCompanion(
                id: id,
                promptId: promptId,
                name: name,
                type: type,
                defaultValue: defaultValue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int promptId,
                required String name,
                Value<String> type = const Value.absent(),
                Value<String> defaultValue = const Value.absent(),
              }) => PromptVariablesCompanion.insert(
                id: id,
                promptId: promptId,
                name: name,
                type: type,
                defaultValue: defaultValue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PromptVariablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (promptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.promptId,
                                referencedTable:
                                    $$PromptVariablesTableReferences
                                        ._promptIdTable(db),
                                referencedColumn:
                                    $$PromptVariablesTableReferences
                                        ._promptIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PromptVariablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptVariablesTable,
      PromptVariable,
      $$PromptVariablesTableFilterComposer,
      $$PromptVariablesTableOrderingComposer,
      $$PromptVariablesTableAnnotationComposer,
      $$PromptVariablesTableCreateCompanionBuilder,
      $$PromptVariablesTableUpdateCompanionBuilder,
      (PromptVariable, $$PromptVariablesTableReferences),
      PromptVariable,
      PrefetchHooks Function({bool promptId})
    >;
typedef $$UsageStatsTableCreateCompanionBuilder =
    UsageStatsCompanion Function({
      Value<int> id,
      required int promptId,
      required String packageName,
      Value<int> count,
      Value<DateTime> lastUsedAt,
    });
typedef $$UsageStatsTableUpdateCompanionBuilder =
    UsageStatsCompanion Function({
      Value<int> id,
      Value<int> promptId,
      Value<String> packageName,
      Value<int> count,
      Value<DateTime> lastUsedAt,
    });

final class $$UsageStatsTableReferences
    extends BaseReferences<_$AppDatabase, $UsageStatsTable, UsageStat> {
  $$UsageStatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PromptsTable _promptIdTable(_$AppDatabase db) => db.prompts
      .createAlias($_aliasNameGenerator(db.usageStats.promptId, db.prompts.id));

  $$PromptsTableProcessedTableManager get promptId {
    final $_column = $_itemColumn<int>('prompt_id')!;

    final manager = $$PromptsTableTableManager(
      $_db,
      $_db.prompts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_promptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UsageStatsTableFilterComposer
    extends Composer<_$AppDatabase, $UsageStatsTable> {
  $$UsageStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PromptsTableFilterComposer get promptId {
    final $$PromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableFilterComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageStatsTable> {
  $$UsageStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PromptsTableOrderingComposer get promptId {
    final $$PromptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableOrderingComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageStatsTable> {
  $$UsageStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  $$PromptsTableAnnotationComposer get promptId {
    final $$PromptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.promptId,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableAnnotationComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsageStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsageStatsTable,
          UsageStat,
          $$UsageStatsTableFilterComposer,
          $$UsageStatsTableOrderingComposer,
          $$UsageStatsTableAnnotationComposer,
          $$UsageStatsTableCreateCompanionBuilder,
          $$UsageStatsTableUpdateCompanionBuilder,
          (UsageStat, $$UsageStatsTableReferences),
          UsageStat,
          PrefetchHooks Function({bool promptId})
        > {
  $$UsageStatsTableTableManager(_$AppDatabase db, $UsageStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> promptId = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
              }) => UsageStatsCompanion(
                id: id,
                promptId: promptId,
                packageName: packageName,
                count: count,
                lastUsedAt: lastUsedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int promptId,
                required String packageName,
                Value<int> count = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
              }) => UsageStatsCompanion.insert(
                id: id,
                promptId: promptId,
                packageName: packageName,
                count: count,
                lastUsedAt: lastUsedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UsageStatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({promptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (promptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.promptId,
                                referencedTable: $$UsageStatsTableReferences
                                    ._promptIdTable(db),
                                referencedColumn: $$UsageStatsTableReferences
                                    ._promptIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UsageStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsageStatsTable,
      UsageStat,
      $$UsageStatsTableFilterComposer,
      $$UsageStatsTableOrderingComposer,
      $$UsageStatsTableAnnotationComposer,
      $$UsageStatsTableCreateCompanionBuilder,
      $$UsageStatsTableUpdateCompanionBuilder,
      (UsageStat, $$UsageStatsTableReferences),
      UsageStat,
      PrefetchHooks Function({bool promptId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$PromptTagsTableCreateCompanionBuilder =
    PromptTagsCompanion Function({
      required int promptId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$PromptTagsTableUpdateCompanionBuilder =
    PromptTagsCompanion Function({
      Value<int> promptId,
      Value<int> tagId,
      Value<int> rowid,
    });

class $$PromptTagsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptTagsTable> {
  $$PromptTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get promptId => $composableBuilder(
    column: $table.promptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromptTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptTagsTable> {
  $$PromptTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get promptId => $composableBuilder(
    column: $table.promptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromptTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptTagsTable> {
  $$PromptTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get promptId =>
      $composableBuilder(column: $table.promptId, builder: (column) => column);

  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$PromptTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptTagsTable,
          PromptTag,
          $$PromptTagsTableFilterComposer,
          $$PromptTagsTableOrderingComposer,
          $$PromptTagsTableAnnotationComposer,
          $$PromptTagsTableCreateCompanionBuilder,
          $$PromptTagsTableUpdateCompanionBuilder,
          (
            PromptTag,
            BaseReferences<_$AppDatabase, $PromptTagsTable, PromptTag>,
          ),
          PromptTag,
          PrefetchHooks Function()
        > {
  $$PromptTagsTableTableManager(_$AppDatabase db, $PromptTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> promptId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromptTagsCompanion(
                promptId: promptId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int promptId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => PromptTagsCompanion.insert(
                promptId: promptId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromptTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptTagsTable,
      PromptTag,
      $$PromptTagsTableFilterComposer,
      $$PromptTagsTableOrderingComposer,
      $$PromptTagsTableAnnotationComposer,
      $$PromptTagsTableCreateCompanionBuilder,
      $$PromptTagsTableUpdateCompanionBuilder,
      (PromptTag, BaseReferences<_$AppDatabase, $PromptTagsTable, PromptTag>),
      PromptTag,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db, _db.prompts);
  $$PromptVariablesTableTableManager get promptVariables =>
      $$PromptVariablesTableTableManager(_db, _db.promptVariables);
  $$UsageStatsTableTableManager get usageStats =>
      $$UsageStatsTableTableManager(_db, _db.usageStats);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$PromptTagsTableTableManager get promptTags =>
      $$PromptTagsTableTableManager(_db, _db.promptTags);
}
