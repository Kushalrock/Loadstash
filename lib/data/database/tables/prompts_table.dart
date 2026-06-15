import 'package:drift/drift.dart';

class Prompts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  // JSON-encoded List<String> e.g. '["Writing","Email"]'. Root = '[]'.
  TextColumn get path => text().withDefault(const Constant('[]'))();
  // JSON-encoded List<String> of user search tags e.g. '["work","sales"]'
  TextColumn get searchTags => text().withDefault(const Constant('[]'))();
  TextColumn get modelTags => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
