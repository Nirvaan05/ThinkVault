import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final userName = user?['name'] as String? ?? 'User';
    final userEmail = user?['email'] as String? ?? '';
    final isAdmin = auth.isAdmin;

    return Drawer(
      child: Column(
        children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Admin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () => _navigateTo(context, '/dashboard'),
                ),
                _DrawerItem(
                  icon: Icons.note_alt_outlined,
                  selectedIcon: Icons.note_alt_rounded,
                  label: 'All Notes',
                  route: '/notes',
                  isSelected: currentRoute == '/notes',
                  onTap: () => _navigateTo(context, '/notes'),
                ),
                const Divider(indent: 16, endIndent: 16, height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                  child: Text(
                    'ORGANIZE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder_rounded,
                  label: 'Categories',
                  route: '/categories',
                  isSelected: currentRoute == '/categories',
                  onTap: () => _navigateTo(context, '/categories'),
                ),
                _DrawerItem(
                  icon: Icons.label_outlined,
                  selectedIcon: Icons.label_rounded,
                  label: 'Tags',
                  route: '/tags',
                  isSelected: currentRoute == '/tags',
                  onTap: () => _navigateTo(context, '/tags'),
                ),
                const Divider(indent: 16, endIndent: 16, height: 16),
                _DrawerItem(
                  icon: Icons.feedback_outlined,
                  selectedIcon: Icons.feedback_rounded,
                  label: 'Feedback',
                  route: '/feedback',
                  isSelected: currentRoute == '/feedback',
                  onTap: () => _navigateTo(context, '/feedback'),
                ),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  selectedIcon: Icons.help_rounded,
                  label: 'Help & About',
                  route: '/help',
                  isSelected: currentRoute == '/help',
                  onTap: () => _navigateTo(context, '/help'),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () => _navigateTo(context, '/settings'),
                ),
                if (isAdmin) ...[
                  const Divider(indent: 16, endIndent: 16, height: 16),
                  _DrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Panel',
                    route: '/admin',
                    isSelected: currentRoute == '/admin',
                    onTap: () => _navigateTo(context, '/admin'),
                  ),
                ],
              ],
            ),
          ),

          // Logout
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/logout');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          size: 22,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
