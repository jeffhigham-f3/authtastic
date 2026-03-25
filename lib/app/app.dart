import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:authtastic/core/constants/app_colors.dart';
import 'package:authtastic/core/state/vault_controller.dart';
import 'package:authtastic/core/state/vault_session_state.dart';
import 'package:authtastic/features/home/presentation/home_shell.dart';
import 'package:authtastic/features/vault_unlock/presentation/create_vault_screen.dart';
import 'package:authtastic/features/vault_unlock/presentation/unlock_screen.dart';

class AuthTasticApp extends ConsumerStatefulWidget {
  const AuthTasticApp({super.key});

  @override
  ConsumerState<AuthTasticApp> createState() => _AuthTasticAppState();
}

class _AuthTasticAppState extends ConsumerState<AuthTasticApp>
    with WidgetsBindingObserver {
  Timer? _lockTimer;
  static const _lockDelay = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final session = ref.read(vaultControllerProvider);
    final shouldAutoLock = session.data?.settings.autoLockEnabled ?? false;

    if (lifecycleState == AppLifecycleState.paused &&
        session.isUnlocked &&
        shouldAutoLock) {
      _lockTimer?.cancel();
      _lockTimer = Timer(_lockDelay, () {
        ref.read(vaultControllerProvider.notifier).lock();
      });
    }

    if (lifecycleState == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      _lockTimer = null;
    }

    super.didChangeAppLifecycleState(lifecycleState);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultControllerProvider);

    final home = switch (session.status) {
      VaultStatus.loading => const _LoadingScreen(),
      VaultStatus.needsSetup => const CreateVaultScreen(),
      VaultStatus.locked => const UnlockScreen(),
      VaultStatus.unlocked => const HomeShell(),
      VaultStatus.error =>
        ref.read(vaultControllerProvider.notifier).hasExistingVault
            ? const UnlockScreen()
            : const CreateVaultScreen(),
    };

    return MaterialApp(
      title: 'AuthTastic',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: home,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentBlue,
        primary: AppColors.accentBlue,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(foregroundColor: AppColors.textPrimary),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
