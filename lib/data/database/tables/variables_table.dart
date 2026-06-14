import 'package:drift/drift.dart';
import 'prompts_table.dart';

class PromptVariables extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get promptId => integer().references(Prompts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get defaultValue => text().withDefault(const Constant(''))();
}
