import '../../core/content_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/app_drawer.dart';

import 'notes_provider.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;

  // Filter state
  int? _filterCategoryId;
  String? _filterCategoryName;
  int? _filterTagId;
  String? _filterTagName;
  String? _filterPriority;

  // Cached categories and tags for filter bottom sheet
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _tags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().fetchNotes();
      _loadFiltersData();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<NotesProvider>().fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiltersData() async {
    try {
      final api = context.read<ApiClient>();
      final catRes = await api.dio.get('/categories');
      final tagRes = await api.dio.get('/tags');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(catRes.data['data'] ?? []);
          _tags = List<Map<String, dynamic>>.from(tagRes.data['data'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }

    setState(() => _searchLoading = true);
    try {
      final api = context.read<ApiClient>();
      final params = <String, dynamic>{'q': query.trim()};
      if (_filterCategoryId != null) params['category_id'] = _filterCategoryId;
      if (_filterTagId != null) params['tag_id'] = _filterTagId;
      if (_filterPriority != null) params['priority'] = _filterPriority;

      final response = await api.dio.get('/notes/search', queryParameters: params);
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(
            response.data['data']?['notes'] ?? [],
          );
          _searchLoading = false;
        });
      }
    } on DioException {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _filterCategoryId = null;
      _filterCategoryName = null;
      _filterTagId = null;
      _filterTagName = null;
      _filterPriority = null;
    });
    if (_isSearching && _searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  bool get _hasActiveFilters =>
      _filterCategoryId != null || _filterTagId != null || _filterPriority != null;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _filterCategoryId = null;
                            _filterCategoryName = null;
                            _filterTagId = null;
                            _filterTagName = null;
                            _filterPriority = null;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text('Category', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _filterCategoryId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    hint: const Text('All categories'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                      ..._categories.map((c) => DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['name'] as String? ?? ''),
                          )),
                    ],
                    onChanged: (v) {
                      setSheetState(() {
                        _filterCategoryId = v;
                        _filterCategoryName = v != null
                            ? _categories.firstWhere((c) => c['id'] == v)['name'] as String?
                            : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Text('Tag', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _filterTagId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    hint: const Text('All tags'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All tags')),
                      ..._tags.map((t) => DropdownMenuItem<int?>(
                            value: t['id'] as int,
                            child: Text(t['name'] as String? ?? ''),
                          )),
                    ],
                    onChanged: (v) {
                      setSheetState(() {
                        _filterTagId = v;
                        _filterTagName = v != null
                            ? _tags.firstWhere((t) => t['id'] == v)['name'] as String?
                            : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  Text('Priority', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: 'low', label: Text('Low')),
                      ButtonSegment(value: 'medium', label: Text('Medium')),
                      ButtonSegment(value: 'high', label: Text('High')),
                    ],
                    selected: {_filterPriority},
                    onSelectionChanged: (s) {
                      setSheetState(() => _filterPriority = s.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                        if (_isSearching && _searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('h:mm a').format(dt);
      }
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade400;
      case 'low':
        return Colors.green.shade400;
      default:
        return Colors.amber.shade400;
    }
  }

  Future<void> _deleteNote(BuildContext ctx, int id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctx.mounted) {
      await ctx.read<NotesProvider>().deleteNote(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = context.watch<NotesProvider>();
    final displayNotes = _isSearching ? _searchResults : notes.notes;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(currentRoute: '/notes'),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                onChanged: (q) => _performSearch(q),
              )
            : const Text(
                'All Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filters',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filterCategoryName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.folder_outlined, size: 16),
                          label: Text(_filterCategoryName!, style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            setState(() {
                              _filterCategoryId = null;
                              _filterCategoryName = null;
                            });
                            if (_isSearching) _performSearch(_searchController.text);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (_filterTagName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.label_outlined, size: 16),
                          label: Text(_filterTagName!, style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            setState(() {
                              _filterTagId = null;
                              _filterTagName = null;
                            });
                            if (_isSearching) _performSearch(_searchController.text);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (_filterPriority != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: Icon(Icons.flag_rounded, size: 16, color: _priorityColor(_filterPriority)),
                          label: Text(_filterPriority!, style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            setState(() => _filterPriority = null);
                            if (_isSearching) _performSearch(_searchController.text);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),
            ),
          // List
          Expanded(
            child: _isSearching && _searchLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isLoading && notes.notes.isEmpty && !_isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : displayNotes.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: () => context.read<NotesProvider>().fetchNotes(),
                            child: ListView.builder(
                              controller: _isSearching ? null : _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: displayNotes.length +
                                  (!_isSearching && notes.hasMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == displayNotes.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final note = displayNotes[i];
                                final preview = extractPreviewText(note['content']);
                                final dateStr = _formatDate(note['updated_at'] as String?);
                                final isPinned =
                                    note['is_pinned'] == 1 || note['is_pinned'] == true;
                                final priority = note['priority'] as String?;
                                final categoryName = note['category_name'] as String?;

                                return Dismissible(
                                  key: ValueKey(note['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child:
                                        const Icon(Icons.delete_outline, color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    await _deleteNote(context, note['id'] as int);
                                    return false;
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/notes/detail',
                                          arguments: note,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Priority dot
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: _priorityColor(priority),
                                                  ),
                                                ),
                                                if (isPinned) ...[
                                                  Icon(
                                                    Icons.push_pin_rounded,
                                                    size: 14,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    note['title'] as String? ?? 'Untitled',
                                                    style:
                                                        theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  dateStr,
                                                  style:
                                                      theme.textTheme.bodySmall?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (preview.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                preview,
                                                style:
                                                    theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            // Category & tag chips
                                            if (categoryName != null) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primaryContainer
                                                          .withValues(alpha: 0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.folder_outlined,
                                                            size: 12,
                                                            color: theme
                                                                .colorScheme.primary),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          categoryName,
                                                          style: theme
                                                              .textTheme.labelSmall
                                                              ?.copyWith(
                                                            color: theme
                                                                .colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/notes/editor');
          if (context.mounted) {
            context.read<NotesProvider>().fetchNotes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off_rounded : Icons.note_alt_outlined,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching ? 'No results found' : 'No notes yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try a different search term or adjust filters.'
                : 'Tap + New Note to capture your first thought.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
