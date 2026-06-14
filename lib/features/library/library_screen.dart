import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../providers/prompt_provider.dart';
import 'widgets/prompt_list_section.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final promptsAsync = _query.isEmpty
        ? ref.watch(promptsStreamProvider)
        : ref.watch(filteredPromptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('loadstash', style: AppTypography.screenTitle),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => context.push('/editor'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (q) {
                setState(() => _query = q);
                ref.read(searchQueryProvider.notifier).state = q;
              },
              decoration: const InputDecoration(
                hintText: 'Search your library…',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: promptsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodySmall),
              ),
              data: (prompts) {
                final mine = prompts.where((p) => !p.isStarter).toList();
                final starter = prompts.where((p) => p.isStarter).toList();

                if (prompts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No prompts yet.\nTap + to create your first.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    PromptListSection(
                      title: 'YOUR PROMPTS',
                      prompts: mine,
                      onPromptTap: (p) => context.push('/editor', extra: p.id),
                      onPromptEdit: (p) => context.push('/editor', extra: p.id),
                    ),
                    PromptListSection(
                      title: 'STARTER LIBRARY',
                      prompts: starter,
                      onPromptTap: (p) => context.push('/editor', extra: p.id),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
