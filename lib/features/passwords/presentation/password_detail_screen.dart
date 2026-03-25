import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:authtastic/core/constants/app_colors.dart';
import 'package:authtastic/core/models/password_item.dart';
import 'package:authtastic/core/state/vault_controller.dart';
import 'package:authtastic/shared/utils/clipboard_helper.dart';
import 'package:authtastic/shared/utils/emoji_from_title.dart';
import 'package:authtastic/features/passwords/presentation/new_password_screen.dart';

class PasswordDetailScreen extends ConsumerStatefulWidget {
  const PasswordDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<PasswordDetailScreen> createState() =>
      _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends ConsumerState<PasswordDetailScreen> {
  bool _showPassword = false;

  PasswordItem? _findItem() {
    final passwords =
        ref.watch(vaultControllerProvider).data?.passwords ??
        const <PasswordItem>[];
    for (final item in passwords) {
      if (item.id == widget.itemId) return item;
    }
    return null;
  }

  void _copy(String value, String label) {
    copyAndScheduleClear(value);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied (clears in 30s)')));
  }

  Future<void> _openWebsite(String website) async {
    var url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await ref
          .read(vaultControllerProvider.notifier)
          .markPasswordUsed(widget.itemId);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Unable to open website')));
  }

  Future<void> _edit(PasswordItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => NewPasswordScreen(initialItem: item)),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _delete(PasswordItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete password?'),
          content: Text('Delete ${item.title}? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ref.read(vaultControllerProvider.notifier).deletePassword(item.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _findItem();
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Password not found.')));
    }

    final displayUrl = (item.website ?? '')
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceFirst('www.', '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _edit(item),
            icon: const Icon(Icons.edit_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFE2E2),
              ),
              onPressed: () => _delete(item),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0x1A2B7FFF), Color(0x1AAD46FF)],
                  ),
                ),
                child: Text(
                  emojiFromTitle(item.title),
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (displayUrl.isNotEmpty)
                      Text(
                        displayUrl,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            label: 'Username',
            value: item.username,
            actions: <Widget>[
              TextButton.icon(
                onPressed: () => _copy(item.username, 'Username'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            label: 'Password',
            value: _showPassword ? item.password : '••••••••••••',
            valueFontFamily: _showPassword ? null : 'Menlo',
            actions: <Widget>[
              TextButton.icon(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                label: Text(_showPassword ? 'Hide' : 'Show'),
              ),
              TextButton.icon(
                onPressed: () => _copy(item.password, 'Password'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
          if (item.website != null) ...<Widget>[
            const SizedBox(height: 12),
            _InfoCard(
              label: 'Website',
              value: displayUrl,
              actions: <Widget>[
                TextButton.icon(
                  onPressed: () => _openWebsite(item.website!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _MetaCard(item: item),
          if ((item.notes ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _InfoCard(label: 'Notes', value: item.notes!),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    this.actions = const <Widget>[],
    this.valueFontFamily,
  });

  final String label;
  final String value;
  final List<Widget> actions;
  final String? valueFontFamily;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ...actions,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontFamily: valueFontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.item});

  final PasswordItem item;

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime value) =>
        DateFormat.yMMMd().format(value.toLocal());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            _MetaRow(label: 'Created', value: formatDate(item.createdAt)),
            _MetaRow(label: 'Modified', value: formatDate(item.updatedAt)),
            _MetaRow(
              label: 'Last Used',
              value: item.lastUsedAt == null
                  ? 'Never'
                  : DateFormat.yMMMd().add_jm().format(
                      item.lastUsedAt!.toLocal(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
