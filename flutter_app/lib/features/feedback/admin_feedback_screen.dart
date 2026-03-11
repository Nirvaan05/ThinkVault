import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import 'feedback_service.dart';

// ── Status chip colour map ────────────────────────────────────────────────────
const _statusColors = {
  'open':         Colors.orange,
  'in_progress':  Colors.blue,
  'resolved':     Colors.green,
  'closed':       Colors.grey,
};

const _statusLabels = {
  'open':        'Open',
  'in_progress': 'In Progress',
  'resolved':    'Resolved',
  'closed':      'Closed',
};

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final FeedbackService _service;
  late final TabController _tabs;

  // Indexed by tab: All/Feedback/Bug
  static const _typeFilters = [null, 'feedback', 'bug'];
  static const _tabTitles = ['All', 'Feedback', 'Bug Reports'];

  List<Map<String, dynamic>> _items = [];
  // ignore: unused_field
  int _total = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = FeedbackService(context.read<ApiClient>());
    _tabs = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) _load();
      });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.list(
        type: _typeFilters[_tabs.index],
        limit: 50,
      );
      setState(() {
        _items = List<Map<String, dynamic>>.from(data['items'] as List);
        _total = (data['total'] as num).toInt();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = _service.parseError(e); _isLoading = false; });
    }
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FeedbackDetailSheet(
        item: item,
        service: _service,
        onUpdated: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: _tabTitles
              .map((t) => Tab(text: t))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : TabBarView(
                  controller: _tabs,
                  children: List.generate(3, (_) => _buildList(theme)),
                ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No entries yet',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        itemBuilder: (ctx, i) => _buildTile(theme, _items[i]),
      ),
    );
  }

  Widget _buildTile(ThemeData theme, Map<String, dynamic> item) {
    final status = item['status'] as String? ?? 'open';
    final type   = item['type']   as String? ?? 'feedback';
    final dot    = _statusColors[status] ?? Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (type == 'bug'
                          ? Colors.redAccent
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type == 'bug' ? Icons.bug_report_outlined : Icons.lightbulb_outline,
                  color: type == 'bug' ? Colors.redAccent : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item['subject'] as String? ?? '',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: dot.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabels[status] ?? status,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: dot)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item['body'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDate(item['created_at'] as String?)}  ·  ${item['user_email'] as String? ?? ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 52, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) { return ''; }
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _FeedbackDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final FeedbackService service;
  final VoidCallback onUpdated;

  const _FeedbackDetailSheet({
    required this.item,
    required this.service,
    required this.onUpdated,
  });

  @override
  State<_FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<_FeedbackDetailSheet> {
  bool _isUpdating = false;
  late String _currentStatus;

  static const _allStatuses = ['open', 'in_progress', 'resolved', 'closed'];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.item['status'] as String? ?? 'open';
  }

  Future<void> _setStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      await widget.service.updateStatus(widget.item['id'] as int, status);
      setState(() { _currentStatus = status; _isUpdating = false; });
      widget.onUpdated();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.service.parseError(e))),
        );
      }
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = widget.item['type'] as String? ?? 'feedback';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          controller: ctrl,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type badge + subject
            Row(children: [
              Chip(
                avatar: Icon(
                  type == 'bug' ? Icons.bug_report_outlined : Icons.lightbulb_outline,
                  size: 16,
                ),
                label: Text(type == 'bug' ? 'Bug Report' : 'Feedback'),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
            const SizedBox(height: 10),
            Text(widget.item['subject'] as String? ?? '',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'From: ${widget.item['user_name'] ?? ''} (${widget.item['user_email'] ?? ''})',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(widget.item['body'] as String? ?? '',
                  style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),

            // Status update
            Text('Update Status', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    children: _allStatuses.map((s) {
                      final isActive = s == _currentStatus;
                      final color = _statusColors[s] ?? Colors.grey;
                      return FilterChip(
                        label: Text(_statusLabels[s] ?? s,
                            style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                        selected: isActive,
                        selectedColor: color.withValues(alpha: 0.2),
                        checkmarkColor: color,
                        side: BorderSide(color: isActive ? color : Colors.transparent),
                        onSelected: isActive ? null : (_) => _setStatus(s),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
