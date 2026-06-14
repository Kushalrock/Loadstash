import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/usage_stats_table.dart';

part 'usage_dao.g.dart';

@DriftAccessor(tables: [UsageStats])
class UsageDao extends DatabaseAccessor<AppDatabase> with _$UsageDaoMixin {
  UsageDao(super.db);

  Future<UsageStat?> getUsageStat(int promptId, String packageName) =>
      (select(usageStats)
            ..where((t) => t.promptId.equals(promptId) & t.packageName.equals(packageName)))
          .getSingleOrNull();

  Future<List<UsageStat>> getStatsForPackage(String packageName) =>
      (select(usageStats)..where((t) => t.packageName.equals(packageName))).get();

  Future<List<UsageStat>> getAllStats() => select(usageStats).get();

  Future<void> recordUsage(int promptId, String packageName) async {
    final existing = await getUsageStat(promptId, packageName);
    if (existing == null) {
      await into(usageStats).insert(UsageStatsCompanion.insert(
        promptId: promptId,
        packageName: packageName,
        count: const Value(1),
        lastUsedAt: Value(DateTime.now()),
      ));
    } else {
      await (update(usageStats)
            ..where((t) => t.promptId.equals(promptId) & t.packageName.equals(packageName)))
          .write(UsageStatsCompanion(
        count: Value(existing.count + 1),
        lastUsedAt: Value(DateTime.now()),
      ));
    }
  }
}
