import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';

class UsageRepository {
  UsageRepository(this._db);

  final AppDatabase _db;

  Future<void> recordUsage(int promptId, String packageName) =>
      _db.usageDao.recordUsage(promptId, packageName);

  // Returns prompts sorted by app-aware score.
  // Score = (app-specific count * 3) + (global count * 1) + recency bonus (0-2).
  // Pinned prompts always lead.
  Future<List<Prompt>> getRankedPrompts(String callingPackage) async {
    final allPrompts = await _db.promptDao.getAllPrompts();
    final appStats = await _db.usageDao.getStatsForPackage(callingPackage);
    final allStats = await _db.usageDao.getAllStats();

    final appCountByPrompt = {for (final s in appStats) s.promptId: s.count};
    final globalCountByPrompt = <int, int>{};
    for (final s in allStats) {
      globalCountByPrompt[s.promptId] =
          (globalCountByPrompt[s.promptId] ?? 0) + s.count;
    }
    final lastUsedByPrompt = <int, DateTime>{};
    for (final s in allStats) {
      final existing = lastUsedByPrompt[s.promptId];
      if (existing == null || s.lastUsedAt.isAfter(existing)) {
        lastUsedByPrompt[s.promptId] = s.lastUsedAt;
      }
    }

    final now = DateTime.now();

    double score(Prompt p) {
      final appCount = appCountByPrompt[p.id] ?? 0;
      final globalCount = globalCountByPrompt[p.id] ?? 0;
      final lastUsed = lastUsedByPrompt[p.id];
      double recency = 0;
      if (lastUsed != null) {
        final hoursSince = now.difference(lastUsed).inHours;
        recency = hoursSince < 24 ? 2.0 : hoursSince < 168 ? 1.0 : 0.0;
      }
      return (appCount * 3.0) + (globalCount * 1.0) + recency;
    }

    final pinned = allPrompts.where((p) => p.pinned).toList();
    final unpinned = allPrompts.where((p) => !p.pinned).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));

    return [...pinned, ...unpinned];
  }
}
