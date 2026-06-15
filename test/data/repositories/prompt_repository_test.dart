import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PromptRepository(db);
  });

  tearDown(() async => db.close());

  test('folderContentsAt returns correct subfolders and prompts', () async {
    await repo.create(title: 'A', body: 'B', path: ['Writing', 'Email']);
    await repo.create(title: 'C', body: 'D', path: ['Writing', 'Social']);
    await repo.create(title: 'E', body: 'F', path: ['Writing']);
    await repo.create(title: 'G', body: 'H', path: []);

    final all = await repo.getAll();

    final root = PromptRepository.folderContentsAt(all, []);
    expect(root.folders.map((f) => f.name).toList(), ['Writing']);
    expect(root.prompts.length, 1); // G at root

    final writing = PromptRepository.folderContentsAt(all, ['Writing']);
    expect(writing.folders.map((f) => f.name).toSet(), {'Email', 'Social'});
    expect(writing.prompts.length, 1); // E at Writing
  });

  test('allFolderPaths includes root and all nested paths', () async {
    await repo.create(title: 'A', body: 'B', path: ['Writing', 'Email', 'Cold']);
    final all = await repo.getAll();
    final paths = PromptRepository.allFolderPaths(all);
    expect(paths, containsAll([
      [],
      ['Writing'],
      ['Writing', 'Email'],
      ['Writing', 'Email', 'Cold'],
    ]));
  });

  test('decodePath handles invalid JSON gracefully', () {
    expect(PromptRepository.decodePath(''), []);
    expect(PromptRepository.decodePath('not-json'), []);
    expect(PromptRepository.decodePath('["a","b"]'), ['a', 'b']);
  });

  test('moveTo updates prompt path', () async {
    final id = await repo.create(title: 'T', body: 'B', path: ['Writing']);
    await repo.moveTo(id, ['Dev', 'Reviews']);
    final p = await repo.getById(id);
    expect(PromptRepository.decodePath(p!.path), ['Dev', 'Reviews']);
  });
}
