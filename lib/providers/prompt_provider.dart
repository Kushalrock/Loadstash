import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'repository_providers.dart';

final promptsStreamProvider = StreamProvider<List<Prompt>>((ref) {
  return ref.watch(promptRepositoryProvider).watchAll();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredPromptsProvider = FutureProvider<List<Prompt>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(promptRepositoryProvider);
  if (query.isEmpty) return repo.getAll();
  return repo.search(query);
});
