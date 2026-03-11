import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'attachments_provider.dart';

/// Displays the attachment list for a note and provides upload/delete UX.
class AttachmentsWidget extends StatefulWidget {
  final int noteId;

  const AttachmentsWidget({super.key, required this.noteId});

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttachmentsProvider>().loadAttachments(widget.noteId);
    });
  }

  Future<void> _pickAndUpload(AttachmentsProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'txt'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    final success = await provider.uploadAttachment(widget.noteId, path);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Upload failed'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      AttachmentsProvider provider, Map<String, dynamic> attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete attachment?'),
        content: Text('Remove "${attachment['filename']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteAttachment(attachment['id'] as int);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData _mimeIcon(String? mime) {
    if (mime == null) return Icons.attach_file_rounded;
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_rounded;
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttachmentsProvider>();
    final theme = Theme.of(context);
    final attachments = provider.attachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Row(
          children: [
            Icon(Icons.attach_file_rounded,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Attachments (${attachments.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed:
                  provider.isLoading ? null : () => _pickAndUpload(provider),
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: const Text('Attach'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No attachments yet.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          ...attachments.map((att) {
            final mime = att['mime_type'] as String?;
            final bytes = att['size_bytes'] as int?;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_mimeIcon(mime),
                  color: theme.colorScheme.primary, size: 22),
              title: Text(
                att['filename'] as String? ?? 'file',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: bytes != null
                  ? Text(_formatSize(bytes),
                      style: theme.textTheme.bodySmall)
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(provider, att),
              ),
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }
}
