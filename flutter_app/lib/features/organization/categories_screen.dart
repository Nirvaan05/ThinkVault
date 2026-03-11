import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final response = await api.dio.get('/categories');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] as String? ?? 'Failed to load categories';
        _isLoading = false;
      });
    }
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final api = context.read<ApiClient>();
      await api.dio.post('/categories', data: {'name': name});
      _loadCategories();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed to create')),
        );
      }
    }
  }

  Future<void> _renameCategory(Map<String, dynamic> cat) async {
    final controller = TextEditingController(text: cat['name'] as String? ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final api = context.read<ApiClient>();
      await api.dio.patch('/categories/${cat['id']}', data: {'name': name});
      _loadCategories();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed to rename')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${cat['name']}"? Notes in this category will be uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = context.read<ApiClient>();
      await api.dio.delete('/categories/${cat['id']}');
      _loadCategories();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed to delete')),
        );
      }
    }
  }

  static const _categoryIcons = [
    Icons.folder_rounded,
    Icons.work_outline_rounded,
    Icons.school_outlined,
    Icons.lightbulb_outline_rounded,
    Icons.code_rounded,
    Icons.palette_outlined,
    Icons.science_outlined,
    Icons.bookmark_outline_rounded,
  ];

  static const _categoryColors = [
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.indigo,
    Colors.pink,
    Colors.green,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 12),
                      FilledButton.tonal(onPressed: _loadCategories, child: const Text('Retry')),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No categories yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text('Create categories to organize your notes.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          final color = _categoryColors[i % _categoryColors.length];
                          final icon = _categoryIcons[i % _categoryIcons.length];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.1),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                cat['name'] as String? ?? 'Unnamed',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'rename') _renameCategory(cat);
                                  if (v == 'delete') _deleteCategory(cat);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
