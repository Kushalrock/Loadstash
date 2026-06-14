import 'package:drift/drift.dart';
import 'prompts_table.dart';

class UsageStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get promptId => integer().references(Prompts, #id, onDelete: KeyAction.cascade)();
  TextColumn get packageName => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();
}
