import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/state/vault_controller.dart';
import '../../../core/state/vault_session_state.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _unlocking = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPassword() async {
    final password = _passwordController.text;
    if (password.trim().isEmpty) {
      return;
    }
    setState(() => _unlocking = true);
    await ref
        .read(vaultControllerProvider.notifier)
        .unlockWithPassword(password);
    if (!mounted) return;
    setState(() => _unlocking = false);
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() => _unlocking = true);
    await ref.read(vaultControllerProvider.notifier).unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _unlocking = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    final errorText = switch (state.status) {
      VaultStatus.error => state.errorMessage,
      VaultStatus.locked => state.errorMessage,
      _ => null,
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.accentBlue,
              AppColors.accentPurple,
              AppColors.accentPink,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AuthTastic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your secure vault',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: FilledButton(
                        onPressed: _unlocking ? null : _unlockWithBiometrics,
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to unlock with Face ID',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Or enter master password',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.2),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _unlockWithPassword(),
                    ),
                    if (errorText != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        errorText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _unlocking ? null : _unlockWithPassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_unlocking ? 'Unlocking...' : 'Unlock'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
