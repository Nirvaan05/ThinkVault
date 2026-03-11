import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../core/content_utils.dart';
import 'notes_provider.dart';
import 'attachments_widget.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late QuillController _quillController;
  bool _initialized = false;

  void _initQuill(dynamic rawContent) {
    if (_initialized) return;
    _initialized = true;

    if (rawContent != null) {
      final deltaJson = parseDeltaContent(rawContent);
      if (deltaJson != null) {
        try {
          final doc = Document.fromJson(deltaJson);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
          return;
        } catch (_) {}
      }
    }
    final doc = Document()..insert(0, rawContent?.toString() ?? '');
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    if (_initialized) _quillController.dispose();
    super.dispose();
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

  String _priorityLabel(String? priority) {
    switch (priority) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteArg = ModalRoute.of(context)?.settings.arguments;
    if (noteArg == null || noteArg is! Map<String, dynamic>) {
      // Arguments lost (e.g. after hot restart) — go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final note = noteArg;
    final content = note['content'];
    _initQuill(content);

    final theme = Theme.of(context);
    final isPinned = note['is_pinned'] == 1 || note['is_pinned'] == true;
    final priority = note['priority'] as String?;
    final categoryName = note['category_name'] as String?;
    final tags = note['tags'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                '/notes/editor',
                arguments: note,
              );
              if (context.mounted) {
                context.read<NotesProvider>().fetchNotes();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                if (isPinned) ...[
                  Icon(Icons.push_pin_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    note['title'] as String? ?? 'Untitled',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(note['updated_at'] as String?),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Metadata section
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withValues(alpha: 0.1),
                    border: Border.all(color: _priorityColor(priority).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 14, color: _priorityColor(priority)),
                      const SizedBox(width: 4),
                      Text(
                        _priorityLabel(priority),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(priority),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category badge
                if (categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tags
                if (tags is List)
                  ...tags.map((t) {
                    final tagName = t is Map ? (t['name'] as String? ?? '') : t.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_outlined, size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            tagName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),

            const Divider(height: 32),

            // Content
            QuillEditor.basic(
              controller: _quillController,
            ),

            // Attachments
            AttachmentsWidget(
              noteId: note['id'] as int,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}
