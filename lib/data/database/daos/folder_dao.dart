import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/folders_table.dart';

part 'folder_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  Future<List<Folder>> getAllFolders() => select(folders).get();
  Stream<List<Folder>> watchAllFolders() => select(folders).watch();
  Future<int> insertFolder(FoldersCompanion entry) => into(folders).insert(entry);
  Future<int> deleteFolder(int id) =>
      (delete(folders)..where((t) => t.id.equals(id))).go();
}
