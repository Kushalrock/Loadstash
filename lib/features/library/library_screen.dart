import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_context_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import 'widgets/folder_row.dart';
import 'widgets/new_folder_sheet.dart';
import 'widgets/pinned_row.dart';
import 'widgets/prompt_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<String> _path = [];
  String _query = '';
  bool _showNewFolder = false;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(promptsStreamProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: allAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: context.cAccent)),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) => _buildBody(context, all),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody(BuildContext context, List<Prompt> all) {
    final atRoot = _path.isEmpty;
    final searching = _query.trim().isNotEmpty;
    final contents = PromptRepository.folderContentsAt(all, _path);
    final pinned = all.where((p) => p.pinned).toList();
    final searchResults = searching ? all.where((p) {
      final q = _query.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q) ||
          PromptRepository.decodePath(p.searchTags).any((t) => t.contains(q));
    }).toList() : <Prompt>[];

    return Stack(children: [
      CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (atRoot)
              Row(children: [
                Text('Library', style: AppTypography.screenTitle.copyWith(fontSize: 25, letterSpacing: -0.5)),
                const Spacer(),
                _IconBtn(icon: Icons.add, onTap: () => setState(() => _showNewFolder = true)),
              ])
            else
              Row(children: [
                _BackBtn(onTap: () => setState(() => _path = _path.sublist(0, _path.length - 1))),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_path.last, style: AppTypography.screenTitle.copyWith(fontSize: 19, letterSpacing: -0.2),
                      overflow: TextOverflow.ellipsis),
                  Text(['Library', ..._path.sublist(0, _path.length - 1)].join(' › '),
                      style: TextStyle(fontSize: 11, color: context.cText2, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ])),
                _IconBtn(icon: Icons.add, onTap: () => setState(() => _showNewFolder = true)),
              ]),
            const SizedBox(height: 12),
            _SearchBar(query: _query, onChanged: (q) => setState(() => _query = q)),
          ]),
        )),

        if (searching) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            sliver: SliverToBoxAdapter(child: Text(
              '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} for "$_query"',
              style: AppTypography.bodySmall.copyWith(fontSize: 12, color: context.cText3)))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            sliver: SliverList.separated(
              itemCount: searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PromptCard(
                prompt: searchResults[i],
                onTap: () => context.push('/prompt', extra: searchResults[i].id)),
            )),
        ] else ...[
          if (atRoot && pinned.isNotEmpty) ...[
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 0, 8),
              child: _SectionLabel('Pinned'))),
            SliverToBoxAdapter(child: PinnedRow(prompts: pinned,
                onTap: (p) => context.push('/prompt', extra: p.id))),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
          ],
          if (contents.folders.isNotEmpty) ...[
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: _SectionLabel(atRoot ? 'Folders' : 'Subfolders'))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              sliver: SliverList.separated(
                itemCount: contents.folders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FolderRow(
                  folder: contents.folders[i],
                  onTap: () => setState(() => _path = [..._path, contents.folders[i].name])),
              )),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
          ],
          if (contents.prompts.isNotEmpty) ...[
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: _SectionLabel(atRoot ? 'All prompts' : 'Prompts here'))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              sliver: SliverList.separated(
                itemCount: contents.prompts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => PromptCard(
                  prompt: contents.prompts[i],
                  onTap: () => context.push('/prompt', extra: contents.prompts[i].id)),
              )),
          ],
          if (contents.folders.isEmpty && contents.prompts.isEmpty && !atRoot)
            SliverFillRemaining(child: Center(
              child: Text('No prompts here yet.',
                  style: TextStyle(color: context.cText3)))),
        ],
      ]),

      if (_showNewFolder)
        GestureDetector(
          onTap: () => setState(() => _showNewFolder = false),
          child: Container(color: Colors.black54,
            child: Align(alignment: Alignment.bottomCenter,
              child: GestureDetector(onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cSurface2,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: context.cBorder))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: SizedBox(width: 38, height: 4.5,
                      child: DecoratedBox(decoration: BoxDecoration(color: context.cSheetHandle,
                          borderRadius: const BorderRadius.all(Radius.circular(999))))))),
                    NewFolderSheet(
                      currentPath: _path,
                      onCreate: (name) {
                        setState(() { _showNewFolder = false; _path = [..._path, name]; });
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Folder "$name" created')));
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 6),
      decoration: BoxDecoration(
        color: context.cBgBase,
        border: Border(top: BorderSide(color: context.cBorder))),
      child: Row(children: [
        _NavItem(icon: Icons.book_outlined, label: 'Library', active: true, onTap: () {}),
        const Spacer(),
        GestureDetector(
          onTap: () => context.push('/editor'),
          child: Container(
            width: 52, height: 52, margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: context.cAccent, borderRadius: BorderRadius.circular(17),
              boxShadow: [BoxShadow(color: context.cAccent.withOpacity(0.6), blurRadius: 22, offset: const Offset(0, 8))]),
            child: const Icon(Icons.add, color: Colors.white, size: 26))),
        const Spacer(),
        _NavItem(icon: Icons.settings_outlined, label: 'Settings', active: false,
            onTap: () => context.go('/settings')),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: context.cText3));
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.query, required this.onChanged});
  final String query;
  final ValueChanged<String> onChanged;
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: context.cSurface1, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.query.isNotEmpty ? context.cAccentDim : context.cBorder)),
      child: Row(children: [
        Icon(Icons.search, size: 17,
            color: widget.query.isNotEmpty ? context.cAccentText : context.cText3),
        const SizedBox(width: 9),
        Expanded(child: TextField(
          controller: _ctrl,
          onChanged: widget.onChanged,
          style: TextStyle(fontSize: 13.5, color: context.cText1),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search prompts, folders, tags',
            hintStyle: TextStyle(color: context.cText3, fontSize: 13.5)))),
        if (widget.query.isNotEmpty) GestureDetector(
          onTap: () {
            _ctrl.clear();
            widget.onChanged('');
          },
          child: Icon(Icons.close, size: 16, color: context.cText3)),
      ]),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: context.cSurface1, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder)),
      child: Icon(Icons.arrow_back, size: 18, color: context.cText1)));
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: context.cSurface1, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder)),
      child: Icon(icon, size: 20, color: context.cText1)));
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: active ? context.cAccentText : context.cText3),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10.5,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? context.cAccentText : context.cText3)),
    ]));
}
