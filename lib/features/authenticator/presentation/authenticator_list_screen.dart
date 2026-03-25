import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp/otp.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/otp_item.dart';
import '../../../core/state/vault_controller.dart';
import 'add_authenticator_screen.dart';

class AuthenticatorListScreen extends ConsumerStatefulWidget {
  const AuthenticatorListScreen({super.key});

  @override
  ConsumerState<AuthenticatorListScreen> createState() =>
      _AuthenticatorListScreenState();
}

class _AuthenticatorListScreenState
    extends ConsumerState<AuthenticatorListScreen> {
  final _searchController = TextEditingController();
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = _tick;
    final otps =
        ref.watch(vaultControllerProvider).data?.otps ?? const <OtpItem>[];
    final query = _searchController.text.toLowerCase().trim();
    final filtered = query.isEmpty
        ? otps
        : otps.where((item) {
            return item.issuer.toLowerCase().contains(query) ||
                item.accountName.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Authenticator',
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
                hintText: 'Search authenticators...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const _EmptyAuthenticatorView()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _OtpCard(item: item);
              },
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemCount: filtered.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const AddAuthenticatorScreen()),
        ),
        backgroundColor: AppColors.accentPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OtpCard extends ConsumerWidget {
  const _OtpCard({required this.item});

  final OtpItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final elapsed = nowSeconds % item.period;
    final remaining = item.period - elapsed;
    final progress = remaining / item.period;
    final code = _generateCode(item);

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
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0x1AAD46FF), Color(0x1AF6339A)],
                    ),
                  ),
                  child: const Text('🔐', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.issuer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.accountName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: AppColors.accentPurple,
                      ),
                      Center(
                        child: Text(
                          '$remaining',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Verification Code',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _formatOtpCode(code),
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 30,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOtpCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  String _generateCode(OtpItem item) {
    return OTP.generateTOTPCodeString(
      item.secret,
      DateTime.now().toUtc().millisecondsSinceEpoch,
      algorithm: _algorithmFromString(item.algorithm),
      interval: item.period,
      length: item.digits,
      isGoogle: true,
    );
  }

  Algorithm _algorithmFromString(String value) {
    final upper = value.toUpperCase();
    return switch (upper) {
      'SHA256' => Algorithm.SHA256,
      'SHA512' => Algorithm.SHA512,
      _ => Algorithm.SHA1,
    };
  }
}

class _EmptyAuthenticatorView extends StatelessWidget {
  const _EmptyAuthenticatorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No authenticator accounts yet.\nTap + to add one by scanning a QR code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
