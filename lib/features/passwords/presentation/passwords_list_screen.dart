import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/password_item.dart';
import '../../../core/state/vault_controller.dart';
import '../../../core/state/vault_session_state.dart';
import 'new_password_screen.dart';
import 'password_detail_screen.dart';

class PasswordsListScreen extends ConsumerStatefulWidget {
  const PasswordsListScreen({super.key});

  @override
  ConsumerState<PasswordsListScreen> createState() =>
      _PasswordsListScreenState();
}

class _PasswordsListScreenState extends ConsumerState<PasswordsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultControllerProvider);
    final allItems = session.data?.passwords ?? const <PasswordItem>[];
    final query = _searchController.text.toLowerCase().trim();
    final items = query.isEmpty
        ? allItems
        : allItems
              .where(
                (item) =>
                    item.title.toLowerCase().contains(query) ||
                    item.username.toLowerCase().contains(query) ||
                    (item.website ?? '').toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Passwords',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 96,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: switch (session.status) {
        VaultStatus.unlocked =>
          items.isEmpty
              ? const _EmptyPasswordsView()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _PasswordCard(
                      item: item,
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                PasswordDetailScreen(itemId: item.id),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    );
                  },
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemCount: items.length,
                ),
        _ => const SizedBox.shrink(),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
          );
          if (mounted) setState(() {});
        },
        backgroundColor: AppColors.accentBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.item, required this.onTap});

  final PasswordItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastUsed = item.lastUsedAt;
    final subtitle = lastUsed == null
        ? 'Never used'
        : 'Last used ${DateFormat.yMMMd().add_jm().format(lastUsed.toLocal())}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 1),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0x1A2B7FFF), Color(0x1AAD46FF)],
                ),
              ),
              child: Text(
                _emojiFromTitle(item.title),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.category != null && item.category!.isNotEmpty)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: const Color(0xFFDCEAFE),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              item.category!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1447E6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.username,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF99A1AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('git')) return '🐙';
    if (lower.contains('mail')) return '📧';
    if (lower.contains('aws')) return '☁️';
    if (lower.contains('netflix')) return '🎬';
    if (lower.contains('spotify')) return '🎵';
    return '🔐';
  }
}

class _EmptyPasswordsView extends StatelessWidget {
  const _EmptyPasswordsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No passwords yet.\nTap + to add your first password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
