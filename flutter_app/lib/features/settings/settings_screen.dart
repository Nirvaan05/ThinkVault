import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final userName = user?['name'] as String? ?? 'User';
    final userEmail = user?['email'] as String? ?? '';
    final userRole = user?['role'] as String? ?? 'user';
    final otpEnabled = user?['otp_enabled'] == true || user?['otp_enabled'] == 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account section
          _buildSectionTitle(theme, 'Account'),
          const SizedBox(height: 8),
          _buildSettingsCard(theme, [
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePasswordDialog(),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Two-Factor Authentication',
              subtitle: otpEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: otpEnabled,
                onChanged: (value) {
                  if (value) {
                    _setupOtp();
                  } else {
                    _disableOtp();
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // App section
          _buildSectionTitle(theme, 'Application'),
          const SizedBox(height: 8),
          _buildSettingsCard(theme, [
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: '1.0.0',
            ),
          ]),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/logout'),
              icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              label: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, List<_SettingsTile> tiles) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final tile = entry.value;
          final isLast = entry.key == tiles.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(tile.icon, color: theme.colorScheme.primary),
                title: Text(tile.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: tile.subtitle != null
                    ? Text(tile.subtitle!, style: theme.textTheme.bodySmall)
                    : null,
                trailing: tile.trailing ??
                    (tile.onTap != null
                        ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant)
                        : null),
                onTap: tile.onTap,
              ),
              if (!isLast) Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    // Placeholder - would need a change-password API endpoint
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change coming soon')),
    );
  }

  Future<void> _setupOtp() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.setupOtp();
    if (data == null || !mounted) return;

    final otpUrl = data['otpauth_url'] as String?;
    if (otpUrl == null) return;

    final tokenController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setup Two-Factor Auth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add this account to your authenticator app, then enter the 6-digit code:',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            SelectableText(otpUrl, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, tokenController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) return;
    final success = await auth.verifyOtp(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Two-factor auth enabled!' : 'Invalid code. Try again.')),
      );
    }
  }

  Future<void> _disableOtp() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Two-Factor Auth'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm your password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.disableOtp(password);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Two-factor auth disabled.' : 'Invalid password.')),
      );
    }
  }
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
