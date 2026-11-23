import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wallet_enseignant/app/app_providers.dart';
import 'package:wallet_enseignant/app/app_theme.dart';
import 'package:wallet_enseignant/core/security/installation_state_service.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  ProviderSubscription<AsyncValue<AppStartupDestination>>? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = ref.listenManual(startupDestinationProvider, (
      previous,
      next,
    ) {
      next.whenData((destination) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          switch (destination) {
            case AppStartupDestination.register:
              context.go('/register');
              break;

            case AppStartupDestination.login:
              context.go('/login');
              break;

            case AppStartupDestination.reconnect:
              context.go('/connexion');
              break;
          }
        });
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startupState = ref.watch(startupDestinationProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: startupState.when(
            loading: () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Préparation de votre espace...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de préparer votre espace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vérifiez votre stockage local et réessayez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(startupDestinationProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
            data: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
