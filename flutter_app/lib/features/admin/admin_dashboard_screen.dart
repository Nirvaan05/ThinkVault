import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../auth/auth_provider.dart';
import 'admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminService _adminService;
  Map<String, dynamic>? _metrics;
  List<dynamic> _users = [];
  int _totalUsers = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _adminService = AdminService(apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final metrics = await _adminService.getMetrics();
      final usersData = await _adminService.listUsers(limit: 10);
      setState(() {
        _metrics = metrics;
        _users = usersData['users'] as List<dynamic>;
        _totalUsers = (usersData['total'] as num).toInt();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _adminService.parseError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Feedback',
            onPressed: () => Navigator.pushNamed(context, '/admin/feedback'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuration',
            onPressed: () => Navigator.pushNamed(context, '/admin/config'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => Navigator.pushReplacementNamed(context, '/logout'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeBanner(theme, auth),
                      const SizedBox(height: 20),
                      _buildMetricsSection(theme),
                      const SizedBox(height: 24),
                      _buildUserListSection(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              color: theme.colorScheme.onPrimary, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Control Panel',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold)),
                Text('Logged in as ${auth.user?['email'] ?? 'admin'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(ThemeData theme) {
    final m = _metrics!;
    final cards = [
      _MetricCard(
          icon: Icons.people_alt_rounded,
          label: 'Total Users',
          value: '${m['total_users']}',
          color: Colors.blueAccent),
      _MetricCard(
          icon: Icons.note_alt_rounded,
          label: 'Total Notes',
          value: '${m['total_notes']}',
          color: Colors.teal),
      _MetricCard(
          icon: Icons.attach_file_rounded,
          label: 'Attachments',
          value: '${m['total_attachments']}',
          color: Colors.orange),
      _MetricCard(
          icon: Icons.person_add_alt_1_rounded,
          label: 'New (7d)',
          value: '${m['recent_signups']}',
          color: Colors.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildUserListSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Users  ($_totalUsers total)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...(_users.map((u) => _buildUserTile(theme, u))),
      ],
    );
  }

  Widget _buildUserTile(ThemeData theme, dynamic u) {
    final isAdmin = u['role'] == 'admin';
    final isLocked = u['is_locked'] == 1 || u['is_locked'] == true;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isAdmin ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            (u['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: isAdmin
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant),
          ),
        ),
        title: Text(u['name'] as String? ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(u['email'] as String? ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              Chip(
                label: const Text('admin',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: theme.colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
