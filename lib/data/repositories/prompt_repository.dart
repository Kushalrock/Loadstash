import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';
import '../../services/variable_detector.dart';

typedef FolderEntry = ({String name, int count});
typedef FolderContents = ({List<FolderEntry> folders, List<Prompt> prompts});

class PromptRepository {
  PromptRepository(this._db);

  final AppDatabase _db;

  // ── Basic CRUD ──────────────────────────────────────────────

  Future<List<Prompt>> getAll() => _db.promptDao.getAllPrompts();
  Stream<List<Prompt>> watchAll() => _db.promptDao.watchAllPrompts();
  Future<List<Prompt>> search(String query) => _db.promptDao.searchPrompts(query);
  Future<Prompt?> getById(int id) => _db.promptDao.getPromptById(id);
  Future<List<PromptVariable>> getVariablesFor(int promptId) =>
      _db.promptDao.getVariablesForPrompt(promptId);

  Future<int> create({
    required String title,
    required String body,
    List<String> path = const [],
    List<String> searchTags = const [],
    String modelTags = '',
    bool pinned = false,
    bool isStarter = false,
  }) async {
    final id = await _db.promptDao.insertPrompt(PromptsCompanion.insert(
      title: title,
      body: body,
      path: Value(encodePath(path)),
      searchTags: Value(encodePath(searchTags)),
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
    List<String> path = const [],
    List<String> searchTags = const [],
    String modelTags = '',
    bool pinned = false,
  }) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      path: Value(encodePath(path)),
      searchTags: Value(encodePath(searchTags)),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
    await _syncVariables(id, body);
  }

  Future<void> delete(int id) => _db.promptDao.deletePrompt(id);

  Future<void> togglePin(int id, bool pinned) async {
    await _db.promptDao.patchPrompt(
      id,
      PromptsCompanion(
        pinned: Value(pinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> moveTo(int id, List<String> newPath) async {
    await _db.promptDao.patchPrompt(
      id,
      PromptsCompanion(
        path: Value(encodePath(newPath)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Folder derivation ───────────────────────────────────────

  /// Returns subfolders and prompts directly at [currentPath].
  static FolderContents folderContentsAt(List<Prompt> allPrompts, List<String> currentPath) {
    final folderCounts = <String, int>{};
    final promptsHere = <Prompt>[];

    for (final p in allPrompts) {
      final pPath = decodePath(p.path);
      if (pathEquals(pPath, currentPath)) {
        promptsHere.add(p);
      } else if (pPath.length > currentPath.length && pathStartsWith(pPath, currentPath)) {
        final next = pPath[currentPath.length];
        folderCounts[next] = (folderCounts[next] ?? 0) + 1;
      }
    }

    final folders = folderCounts.entries
        .map((e) => (name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return (folders: folders, prompts: promptsHere);
  }

  /// All unique folder paths across all prompts, for the folder picker.
  /// Always includes root ([]).
  static List<List<String>> allFolderPaths(List<Prompt> allPrompts) {
    final seen = <String>{};
    final result = <List<String>>[[]]; // always include root
    for (final p in allPrompts) {
      final pPath = decodePath(p.path);
      for (var depth = 1; depth <= pPath.length; depth++) {
        final sub = pPath.sublist(0, depth);
        final key = sub.join('/');
        if (seen.add(key)) result.add(sub);
      }
    }
    return result;
  }

  // ── Encoding helpers ────────────────────────────────────────

  static List<String> decodePath(String json) {
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  static String encodePath(List<String> path) => jsonEncode(path);

  static bool pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool pathStartsWith(List<String> path, List<String> prefix) {
    if (path.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (path[i] != prefix[i]) return false;
    }
    return true;
  }

  Future<void> _syncVariables(int promptId, String body) async {
    final names = VariableDetector.detect(body);
    final companions = names
        .map((n) => PromptVariablesCompanion.insert(promptId: promptId, name: n))
        .toList();
    await _db.promptDao.replaceVariables(promptId, companions);
  }
}
