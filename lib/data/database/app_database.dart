import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/prompts_table.dart';
import 'tables/variables_table.dart';
import 'tables/usage_stats_table.dart';
import 'tables/folders_table.dart';
import 'tables/tags_table.dart';
import 'daos/prompt_dao.dart';
import 'daos/usage_dao.dart';
import 'daos/folder_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Prompts, PromptVariables, UsageStats, Folders, Tags, PromptTags],
  daos: [PromptDao, UsageDao, FolderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'loadstash.db'));
    return NativeDatabase.createInBackground(file);
  });
}
