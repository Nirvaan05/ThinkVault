import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

/// Screen for setting up TOTP-based two-factor authentication.
/// Flow:
///   1. User taps "Set Up Two-Factor Auth" → POST /auth/otp/setup
///   2. We display the QR code URI (if rendering is supported) and otpauth URL
///   3. User scans with Authenticator app, enters 6-digit code
///   4. POST /auth/otp/verify — OTP is enabled on success
class OtpSetupScreen extends StatefulWidget {
  const OtpSetupScreen({super.key});

  @override
  State<OtpSetupScreen> createState() => _OtpSetupScreenState();
}

class _OtpSetupScreenState extends State<OtpSetupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSetupLoading = false;
  Map<String, dynamic>? _setupData;
  String? _statusMessage;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _initiateSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initiateSetup() async {
    setState(() => _isSetupLoading = true);
    final auth = context.read<AuthProvider>();
    final data = await auth.setupOtp();
    setState(() {
      _setupData = data;
      _isSetupLoading = false;
    });
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_codeController.text.trim());

    if (ok && mounted) {
      setState(() {
        _success = true;
        _statusMessage = 'Two-factor authentication enabled successfully!';
      });
    } else if (mounted) {
      setState(() => _statusMessage = auth.errorMessage ?? 'Verification failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Two-Factor Auth'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _isSetupLoading
                  ? const CircularProgressIndicator()
                  : _setupData == null
                      ? _buildError(theme)
                      : _success
                          ? _buildSuccess(theme)
                          : _buildSetupForm(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Failed to start OTP setup.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        FilledButton(onPressed: _initiateSetup, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.verified_user, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('2FA Enabled!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_statusMessage ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSetupForm(ThemeData theme) {
    final otpauthUrl = _setupData!['otpauthUrl'] as String? ?? '';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.security, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Scan with your Authenticator app',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Use Google Authenticator, Authy, or any compatible app to scan the key below.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Manual key display (QR rendering requires external package — showing URL)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OTP Auth URL', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText(
                  otpauthUrl,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Enter the 6-digit code from your app to confirm:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit Code',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Code is required';
              if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                return 'Enter a valid 6-digit numeric code';
              }
              return null;
            },
          ),

          if (_statusMessage != null && !_success) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (_, auth, _) => FilledButton(
              onPressed: auth.isLoading ? null : _handleVerify,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify & Enable', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
