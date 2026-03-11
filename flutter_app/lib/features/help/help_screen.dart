import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
        title: const Text('Help & About', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.lock_rounded, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'ThinkVault',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your secure, cross-platform digital vault for notes, ideas, and knowledge.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Getting Started
          _buildSectionTitle(theme, 'Getting Started'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(theme, '1', 'Create a note', 'Tap the "New Note" button to start writing. Use the rich text toolbar to format your content.'),
                  const SizedBox(height: 16),
                  _buildStep(theme, '2', 'Organize with categories & tags', 'Assign a category and multiple tags to each note. Use priority levels (Low, Medium, High) to highlight importance.'),
                  const SizedBox(height: 16),
                  _buildStep(theme, '3', 'Search & filter', 'Use the search bar to find notes instantly. Filter by category, tags, or priority using the filter button.'),
                  const SizedBox(height: 16),
                  _buildStep(theme, '4', 'Attach files', 'Add images, PDFs, or text files to your notes. View and manage attachments from the note detail screen.'),
                  const SizedBox(height: 16),
                  _buildStep(theme, '5', 'Access anywhere', 'ThinkVault syncs across all your devices. Your notes are always up to date.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FAQ
          _buildSectionTitle(theme, 'Frequently Asked Questions'),
          const SizedBox(height: 8),
          _buildFaqTile(theme, 'How do I create a category?', 'Open the navigation drawer and tap "Categories". Then tap the "New Category" button to add one.'),
          _buildFaqTile(theme, 'How do I pin a note?', 'When editing a note, tap the pin icon in the toolbar. Pinned notes appear at the top of your dashboard.'),
          _buildFaqTile(theme, 'What file types can I attach?', 'ThinkVault supports images (JPG, PNG, GIF, WebP), PDFs, and plain text files. Maximum file size is 10 MB.'),
          _buildFaqTile(theme, 'How does sync work?', 'Notes are automatically synchronized whenever you open the app or return to it. The latest version of each note is always preserved.'),
          _buildFaqTile(theme, 'Is my data secure?', 'Yes. All communication uses HTTPS encryption. Passwords are hashed with Argon2id. Two-factor authentication is available for additional security.'),
          _buildFaqTile(theme, 'How do I enable two-factor authentication?', 'Go to Settings and toggle "Two-Factor Authentication". You will need an authenticator app (like Google Authenticator) to complete setup.'),
          const SizedBox(height: 24),

          // Technology
          _buildSectionTitle(theme, 'About'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ThinkVault is a comprehensive, all-in-one digital platform designed to solve information overload and disorganization. '
                    'It provides a single, reliable repository for all types of knowledge — from quick ideas and notes to stored images and project plans.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(theme, 'Platform', 'Flutter (Android, Web, Desktop)'),
                  _buildInfoRow(theme, 'Backend', 'Node.js + Express'),
                  _buildInfoRow(theme, 'Database', 'MySQL'),
                  _buildInfoRow(theme, 'Security', 'JWT + Argon2id + TOTP 2FA'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
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

  Widget _buildStep(ThemeData theme, String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primary,
          child: Text(number, style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTile(ThemeData theme, String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          children: [
            Text(answer, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
