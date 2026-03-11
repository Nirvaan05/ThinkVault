import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/content_utils.dart';
import '../../core/api_client.dart';
import '../../core/app_drawer.dart';
import '../auth/auth_provider.dart';
import '../notes/notes_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _tags = [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    final api = context.read<ApiClient>();
    final notesProvider = context.read<NotesProvider>();

    // Fetch notes if not already loaded
    if (notesProvider.notes.isEmpty) {
      await notesProvider.fetchNotes();
    }

    try {
      final catRes = await api.dio.get('/categories');
      final tagRes = await api.dio.get('/tags');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(catRes.data['data'] ?? []);
          _tags = List<Map<String, dynamic>>.from(tagRes.data['data'] ?? []);
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final userName = auth.user?['name'] as String? ?? 'User';
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final pinnedNotes = notes.notes.where((n) => n['is_pinned'] == 1 || n['is_pinned'] == true).toList();
    final recentNotes = notes.notes.take(5).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'ThinkVault',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Notes',
            onPressed: () => Navigator.pushNamed(context, '/notes'),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Welcome banner
            _buildWelcomeBanner(theme, greeting, userName),
            const SizedBox(height: 24),

            // Stats row
            _buildStatsRow(theme, notes),
            const SizedBox(height: 28),

            // Quick actions
            _buildQuickActions(theme),
            const SizedBox(height: 28),

            // Pinned notes
            if (pinnedNotes.isNotEmpty) ...[
              _buildSectionHeader(theme, 'Pinned', Icons.push_pin_rounded),
              const SizedBox(height: 12),
              _buildHorizontalNoteCards(theme, pinnedNotes),
              const SizedBox(height: 28),
            ],

            // Recent notes
            _buildSectionHeader(theme, 'Recent Notes', Icons.history_rounded),
            const SizedBox(height: 12),
            if (notes.isLoading && notes.notes.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (recentNotes.isEmpty)
              _buildEmptyState(theme)
            else
              ...recentNotes.map((note) => _buildNoteListTile(theme, note)),
          ],
        ),
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

  Widget _buildWelcomeBanner(ThemeData theme, String greeting, String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, NotesProvider notes) {
    final stats = [
      _StatItem(
        label: 'Notes',
        value: '${notes.total}',
        icon: Icons.note_alt_outlined,
        color: theme.colorScheme.primary,
      ),
      _StatItem(
        label: 'Categories',
        value: _statsLoading ? '-' : '${_categories.length}',
        icon: Icons.folder_outlined,
        color: Colors.teal,
      ),
      _StatItem(
        label: 'Tags',
        value: _statsLoading ? '-' : '${_tags.length}',
        icon: Icons.label_outlined,
        color: Colors.orange,
      ),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: stats.indexOf(s) < stats.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.08),
                    border: Border.all(color: s.color.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: s.color, size: 22),
                      const SizedBox(height: 8),
                      Text(
                        s.value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: s.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.note_add_outlined,
            label: 'New Note',
            color: theme.colorScheme.primary,
            onTap: () async {
              await Navigator.pushNamed(context, '/notes/editor');
              if (context.mounted) context.read<NotesProvider>().fetchNotes();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.list_alt_rounded,
            label: 'All Notes',
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/notes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.folder_outlined,
            label: 'Categories',
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHorizontalNoteCards(ThemeData theme, List<Map<String, dynamic>> pinnedNotes) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pinnedNotes.length,
        itemBuilder: (ctx, i) {
          final note = pinnedNotes[i];
          final preview = extractPreviewText(note['content'], maxLength: 80);
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notes/detail', arguments: note),
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: i < pinnedNotes.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.push_pin_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note['title'] as String? ?? 'Untitled',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteListTile(ThemeData theme, Map<String, dynamic> note) {
    final preview = extractPreviewText(note['content'], maxLength: 80);
    final isPinned = note['is_pinned'] == 1 || note['is_pinned'] == true;
    final priority = note['priority'] as String? ?? 'medium';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red.shade400;
        break;
      case 'low':
        priorityColor = Colors.green.shade400;
        break;
      default:
        priorityColor = Colors.amber.shade400;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/notes/detail', arguments: note),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Priority dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPinned) ...[
                          Icon(Icons.push_pin_rounded, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            note['title'] as String? ?? 'Untitled',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.note_alt_outlined, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Note" to start capturing your thoughts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
