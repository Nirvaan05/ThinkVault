import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<Map<String, dynamic>> _tags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final response = await api.dio.get('/tags');
      setState(() {
        _tags = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] as String? ?? 'Failed to load tags';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            border: OutlineInputBorder(),
          ),
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
      await api.dio.post('/tags', data: {'name': name});
      _loadTags();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed to create')),
        );
      }
    }
  }

  Future<void> _deleteTag(Map<String, dynamic> tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text('Delete "${tag['name']}"? It will be removed from all notes.'),
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
      await api.dio.delete('/tags/${tag['id']}');
      _loadTags();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed to delete')),
        );
      }
    }
  }

  static const _tagColors = [
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.cyan,
    Colors.green,
    Colors.indigo,
    Colors.pink,
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
        title: const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      FilledButton.tonal(onPressed: _loadTags, child: const Text('Retry')),
                    ],
                  ),
                )
              : _tags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.label_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No tags yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text('Create tags to label and filter your notes.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTags,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _tags.asMap().entries.map((entry) {
                            final i = entry.key;
                            final tag = entry.value;
                            final color = _tagColors[i % _tagColors.length];

                            return Chip(
                              avatar: Icon(Icons.label_rounded, size: 16, color: color),
                              label: Text(
                                tag['name'] as String? ?? 'Unnamed',
                                style: TextStyle(fontWeight: FontWeight.w500, color: color),
                              ),
                              backgroundColor: color.withValues(alpha: 0.08),
                              side: BorderSide(color: color.withValues(alpha: 0.2)),
                              deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
                              onDeleted: () => _deleteTag(tag),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTag,
        icon: const Icon(Icons.add),
        label: const Text('New Tag'),
      ),
    );
  }
}
