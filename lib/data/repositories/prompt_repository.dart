import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';
import '../../services/variable_detector.dart';

class PromptRepository {
  PromptRepository(this._db);

  final AppDatabase _db;

  Future<List<Prompt>> getAll() => _db.promptDao.getAllPrompts();
  Stream<List<Prompt>> watchAll() => _db.promptDao.watchAllPrompts();
  Future<List<Prompt>> search(String query) => _db.promptDao.searchPrompts(query);
  Future<Prompt?> getById(int id) => _db.promptDao.getPromptById(id);

  Future<List<PromptVariable>> getVariablesFor(int promptId) =>
      _db.promptDao.getVariablesForPrompt(promptId);

  Future<int> create({
    required String title,
    required String body,
    String path = '[]',
    String searchTags = '[]',
    String modelTags = '',
    bool pinned = false,
    bool isStarter = false,
  }) async {
    final id = await _db.promptDao.insertPrompt(PromptsCompanion.insert(
      title: title,
      body: body,
      path: Value(path),
      searchTags: Value(searchTags),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      isStarter: Value(isStarter),
    ));
    await _syncVariables(id, body);
    return id;
  }

  Future<void> update({
    required int id,
    required String title,
    required String body,
    String path = '[]',
    String searchTags = '[]',
    String modelTags = '',
    bool pinned = false,
  }) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      path: Value(path),
      searchTags: Value(searchTags),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
    await _syncVariables(id, body);
  }

  Future<void> delete(int id) => _db.promptDao.deletePrompt(id);

  Future<void> togglePin(int id, bool pinned) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      pinned: Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _syncVariables(int promptId, String body) async {
    final names = VariableDetector.detect(body);
    final companions = names
        .map((n) => PromptVariablesCompanion.insert(promptId: promptId, name: n))
        .toList();
    await _db.promptDao.replaceVariables(promptId, companions);
  }
}
