import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:authtastic/core/constants/app_colors.dart';
import 'package:authtastic/core/models/vault_settings.dart';
import 'package:authtastic/core/state/vault_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(vaultControllerProvider).data;
    final settings = data?.settings ?? const VaultSettings();
    final notifier = ref.read(vaultControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 96,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: <Widget>[
          _SectionCard(
            title: 'Security',
            children: <Widget>[
              _ActionTile(
                icon: Icons.password,
                title: 'Change Master Password',
                onTap: () => _showChangeMasterPasswordDialog(context, notifier),
              ),
              _ToggleTile(
                icon: Icons.face_rounded,
                title: 'Face ID',
                value: settings.biometricEnabled,
                onChanged: (value) {
                  notifier.updateSettings(
                    settings.copyWith(biometricEnabled: value),
                  );
                },
              ),
              _ToggleTile(
                icon: Icons.lock_clock,
                title: 'Auto-Lock',
                value: settings.autoLockEnabled,
                onChanged: (value) {
                  notifier.updateSettings(
                    settings.copyWith(autoLockEnabled: value),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Backup & Transfer',
            children: <Widget>[
              _ActionTile(
                icon: Icons.upload_file,
                title: 'Export Vault',
                subtitle: 'Create encrypted backup',
                onTap: () => _exportVault(context, notifier),
              ),
              _ActionTile(
                icon: Icons.download_for_offline,
                title: 'Import Vault',
                subtitle: 'Restore from backup',
                onTap: () => _importVault(context, notifier),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Preferences',
            children: const <Widget>[
              _DisabledTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
              ),
              _DisabledTile(icon: Icons.dark_mode_outlined, title: 'Dark Mode'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'About',
            children: const <Widget>[
              _DisabledTile(icon: Icons.support_agent, title: 'Help & Support'),
              _DisabledTile(
                icon: Icons.info_outline,
                title: 'About AuthTastic',
              ),
              _DisabledTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE60076),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => notifier.lock(),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Lock Vault'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeMasterPasswordDialog(
    BuildContext context,
    VaultController controller,
  ) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Master Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) =>
                      (value ?? '').length < 8 ? 'Min 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (value) {
                    if (value != newCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
      return;
    }

    final success = await controller.changeMasterPassword(
      currentPassword: currentCtrl.text,
      newPassword: newCtrl.text,
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Master password updated.'
              : 'Failed to update. Check your current password.',
        ),
      ),
    );
  }

  Future<String?> _promptPassphrase(
    BuildContext context, {
    required String title,
    required String actionLabel,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passphrase',
              hintText: 'At least 6 characters',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().length < 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Passphrase must be at least 6 characters.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(ctrl.text);
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _exportVault(
    BuildContext context,
    VaultController controller,
  ) async {
    final passphrase = await _promptPassphrase(
      context,
      title: 'Export Vault',
      actionLabel: 'Export',
    );
    if (passphrase == null) return;

    final path = await controller.exportVault(passphrase);
    if (path == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export vault.')));
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path)],
        text: 'AuthTastic encrypted backup',
        subject: 'AuthTastic Backup',
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Encrypted backup exported.')));
  }

  Future<void> _importVault(
    BuildContext context,
    VaultController controller,
  ) async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['authtastic', 'json'],
    );
    if (file == null || file.files.single.path == null) return;
    if (!context.mounted) return;

    final passphrase = await _promptPassphrase(
      context,
      title: 'Import Vault',
      actionLabel: 'Continue',
    );
    if (passphrase == null) return;

    if (!context.mounted) return;
    final mode = await _promptImportMode(context);
    if (mode == null) return;

    final success = await controller.importVault(
      path: file.files.single.path!,
      passphrase: passphrase,
      mode: mode,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Vault import complete.' : 'Import failed.'),
      ),
    );
  }

  Future<ImportMode?> _promptImportMode(BuildContext context) {
    return showDialog<ImportMode>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Import Mode'),
          content: const Text('Choose how to apply imported entries.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(ImportMode.merge),
              child: const Text('Merge'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ImportMode.replace),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFDCEAFE),
        child: Icon(icon, color: AppColors.accentBlue),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: CircleAvatar(
        backgroundColor: const Color(0xFFEAD9FF),
        child: Icon(icon, color: AppColors.accentPurple),
      ),
      title: Text(title),
    );
  }
}

class _DisabledTile extends StatelessWidget {
  const _DisabledTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF3F4F6),
        child: Icon(icon),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
