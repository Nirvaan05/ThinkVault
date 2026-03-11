import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import 'admin_service.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen>
    with SingleTickerProviderStateMixin {
  late final AdminService _adminService;
  late TabController _tabController;

  List<dynamic> _config = [];
  List<dynamic> _auditLogs = [];
  bool _isLoadingConfig = true;
  bool _isLoadingAudit = true;
  String? _configError;
  String? _auditError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final apiClient = context.read<ApiClient>();
    _adminService = AdminService(apiClient);
    _loadConfig();
    _loadAuditLog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoadingConfig = true;
      _configError = null;
    });
    try {
      final config = await _adminService.getConfig();
      setState(() {
        _config = config;
        _isLoadingConfig = false;
      });
    } on DioException catch (e) {
      setState(() {
        _configError = _adminService.parseError(e);
        _isLoadingConfig = false;
      });
    }
  }

  Future<void> _loadAuditLog() async {
    setState(() {
      _isLoadingAudit = true;
      _auditError = null;
    });
    try {
      final data = await _adminService.getAuditLog(limit: 30);
      setState(() {
        _auditLogs = data['logs'] as List<dynamic>;
        _isLoadingAudit = false;
      });
    } on DioException catch (e) {
      setState(() {
        _auditError = _adminService.parseError(e);
        _isLoadingAudit = false;
      });
    }
  }

  Future<void> _editConfig(Map<String, dynamic> entry) async {
    final controller = TextEditingController(text: entry['config_value'] as String? ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry['config_key'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((entry['description'] as String?)?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  entry['description'] as String,
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _adminService.updateConfig(
          entry['config_key'] as String,
          controller.text.trim(),
        );
        await _loadConfig();
        await _loadAuditLog();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Config updated successfully')),
          );
        }
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_adminService.parseError(e))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded), text: 'Config'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Audit Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigTab(theme),
          _buildAuditTab(theme),
        ],
      ),
    );
  }

  Widget _buildConfigTab(ThemeData theme) {
    if (_isLoadingConfig) return const Center(child: CircularProgressIndicator());
    if (_configError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_configError!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _loadConfig, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConfig,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _config.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (ctx, i) {
          final entry = _config[i] as Map<String, dynamic>;
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                entry['config_key'] as String,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry['config_value'] as String? ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  if ((entry['description'] as String?)?.isNotEmpty == true)
                    Text(
                      entry['description'] as String,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => _editConfig(entry),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuditTab(ThemeData theme) {
    if (_isLoadingAudit) return const Center(child: CircularProgressIndicator());
    if (_auditError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_auditError!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _loadAuditLog, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No changes yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuditLog,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length,
        itemBuilder: (ctx, i) {
          final log = _auditLogs[i] as Map<String, dynamic>;
          final changedAt = _formatDate(log['changed_at'] as String?);
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log['config_key'] as String,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                      Text(changedAt,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildValueChip(theme, log['old_value'] as String? ?? '—', isOld: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 14),
                      ),
                      _buildValueChip(theme, log['new_value'] as String? ?? '—', isOld: false),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'by ${log['user_email'] ?? 'unknown'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValueChip(ThemeData theme, String value, {required bool isOld}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOld
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: isOld
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
