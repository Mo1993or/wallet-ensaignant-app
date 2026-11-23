import 'package:go_router/go_router.dart';

import 'package:wallet_enseignant/features/auth/presentation/screens/login_screen.dart';
import 'package:wallet_enseignant/features/auth/presentation/screens/forgot_pin_screen.dart';
import 'package:wallet_enseignant/features/auth/presentation/screens/new_login_screen.dart';
import 'package:wallet_enseignant/features/auth/presentation/screens/register_screen.dart';
import 'package:wallet_enseignant/features/auth/presentation/screens/startup_screen.dart';

import 'package:wallet_enseignant/features/pay/presentation/screens/pay_screen.dart';
import 'package:wallet_enseignant/features/recharge/presentation/screen/recharge_screen.dart';
import 'package:wallet_enseignant/features/services/presentation/service_screen.dart';
import 'package:wallet_enseignant/features/transfer/presentation/screens/transfer_screen.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/bank_card/presentation/screens/bank_card_screen.dart';
import '../features/professional_card/presentation/screens/professional_card_screen.dart';
import '../features/benefits/presentation/screens/benefits_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../navigation/main_navigation_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/startup',

    routes: [
      // --------------------------------------------------
      // DÉMARRAGE AUTOMATIQUE
      // --------------------------------------------------
      GoRoute(
        path: '/startup',
        builder: (context, state) => const StartupScreen(),
      ),

      // --------------------------------------------------
      // AUTHENTIFICATION
      // --------------------------------------------------
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/forgot-pin',
        builder: (context, state) => const ForgotPinScreen(),
      ),

      GoRoute(
        path: '/connexion',
        builder: (context, state) => const NewLoginScreen(),
      ),

      // --------------------------------------------------
      // PAGES FINANCIÈRES
      // --------------------------------------------------
      GoRoute(
        path: '/recharge',
        builder: (context, state) => const RechargeScreen(),
      ),

      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferScreen(),
      ),

      GoRoute(path: '/pay', builder: (context, state) => const PayScreen()),

      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesScreen(),
      ),

      // --------------------------------------------------
      // NAVIGATION PRINCIPALE
      // --------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },

        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/card',
                builder: (context, state) => const BankCardScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional-card',
                builder: (context, state) => const ProfessionalCardScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/benefits',
                builder: (context, state) => const BenefitsScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
