import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/prompt_repository.dart';
import '../data/repositories/usage_repository.dart';
import 'database_provider.dart';

final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository(ref.watch(databaseProvider));
});

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(ref.watch(databaseProvider));
});
