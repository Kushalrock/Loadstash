import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
}

class PromptTags extends Table {
  IntColumn get promptId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {promptId, tagId};
}
