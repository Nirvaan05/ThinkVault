import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/content_utils.dart';
import 'notes_provider.dart';
import 'attachments_widget.dart';

/// Create or edit a note with a rich text (Quill) editor.
///
/// Pass a `Map<String, dynamic>` note via route arguments to enter edit mode.
/// If no arguments are provided, it opens in create mode.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final QuillController _quillController;
  late final TextEditingController _titleController;
  late final FocusNode _editorFocusNode;
  bool _isPinned = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  int? _editNoteId;

  // Metadata
  int? _categoryId;
  String _priority = 'medium';
  List<int> _selectedTagIds = [];

  // Loaded categories and tags
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _tags = [];
  bool _metaLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _editorFocusNode = FocusNode();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final api = context.read<ApiClient>();
      final catRes = await api.dio.get('/categories');
      final tagRes = await api.dio.get('/tags');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(catRes.data['data'] ?? []);
          _tags = List<Map<String, dynamic>>.from(tagRes.data['data'] ?? []);
          _metaLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _metaLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once
    if (_editNoteId != null || _isEditMode) return;

    final note = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (note != null) {
      _isEditMode = true;
      _editNoteId = note['id'] as int;
      _titleController.text = note['title'] as String? ?? '';
      _isPinned = note['is_pinned'] == 1 || note['is_pinned'] == true;
      _categoryId = note['category_id'] as int?;
      _priority = note['priority'] as String? ?? 'medium';

      // Parse tag_ids if present
      final tagIds = note['tag_ids'];
      if (tagIds is List) {
        _selectedTagIds = tagIds.cast<int>();
      }

      final rawContent = note['content'];
      if (rawContent != null) {
        final deltaJson = parseDeltaContent(rawContent);
        if (deltaJson != null) {
          try {
            final doc = Document.fromJson(deltaJson);
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            return;
          } catch (e) {
            debugPrint('Failed to create Document from delta: $e');
            final text = rawContent.toString();
            final doc = Document()..insert(0, text);
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            return;
          }
        }
      }
    }

    _quillController = QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Serialize Quill Delta to JSON string
    final delta = _quillController.document.toDelta().toJson();
    final contentJson = jsonEncode(delta);

    final provider = context.read<NotesProvider>();
    bool success;

    if (_isEditMode && _editNoteId != null) {
      final result = await provider.updateNote(
        _editNoteId!,
        title: title,
        content: contentJson,
        isPinned: _isPinned,
        categoryId: _categoryId,
        priority: _priority,
        tagIds: _selectedTagIds,
      );
      success = result != null;
    } else {
      final result = await provider.createNote(
        title: title,
        content: contentJson,
        isPinned: _isPinned,
        categoryId: _categoryId,
        priority: _priority,
        tagIds: _selectedTagIds,
      );
      success = result != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save note'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _quickCreateCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post('/categories', data: {'name': name});
      final newCat = Map<String, dynamic>.from(res.data['data']);
      setState(() {
        _categories.add(newCat);
        _categoryId = newCat['id'] as int;
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed')),
        );
      }
    }
  }

  Future<void> _quickCreateTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.post('/tags', data: {'name': name});
      final newTag = Map<String, dynamic>.from(res.data['data']);
      setState(() {
        _tags.add(newTag);
        _selectedTagIds.add(newTag['id'] as int);
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? theme.colorScheme.primary : null,
            ),
            tooltip: _isPinned ? 'Unpin' : 'Pin',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Title field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _editorFocusNode.requestFocus(),
            ),
          ),

          // Metadata section
          _buildMetadataSection(theme),

          // Attachments section (edit mode only)
          if (_isEditMode && _editNoteId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: AttachmentsWidget(noteId: _editNoteId!),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Save note first to attach files',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          Divider(
            height: 24,
            indent: 20,
            endIndent: 20,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),

          // Quill toolbar
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              showSmallButton: false,
              showIndent: false,
              showLink: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),

          const Divider(height: 1),

          // Quill editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                scrollController: ScrollController(),
                config: const QuillEditorConfig(
                  placeholder: 'Start writing...',
                  padding: EdgeInsets.zero,
                  expands: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    if (_metaLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority selector
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Priority', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'low',
                      label: Text('Low', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                    ),
                    ButtonSegment(
                      value: 'medium',
                      label: Text('Medium', style: TextStyle(fontSize: 12, color: Colors.amber.shade700)),
                    ),
                    ButtonSegment(
                      value: 'high',
                      label: Text('High', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                    ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) => setState(() => _priority = s.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category selector
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Category', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  isDense: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('None', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None', style: TextStyle(fontSize: 13))),
                    ..._categories.map((c) => DropdownMenuItem<int?>(
                          value: c['id'] as int,
                          child: Text(c['name'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: 'Create Category',
                onPressed: _quickCreateCategory,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tags selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.label_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Tags', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ..._tags.map((t) {
                      final tagId = t['id'] as int;
                      final isSelected = _selectedTagIds.contains(tagId);
                      return FilterChip(
                        label: Text(t['name'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTagIds.add(tagId);
                            } else {
                              _selectedTagIds.remove(tagId);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('New', style: TextStyle(fontSize: 12)),
                      onPressed: _quickCreateTag,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
