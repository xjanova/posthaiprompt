// Thaiprompt POS — Route configuration
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/cashier_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/receipt_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => _fade(s, const OverviewScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/cashier',
        pageBuilder: (c, s) => _fade(s, const CashierScreen()),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (c, s) => _fade(s, const PaymentScreen()),
      ),
      GoRoute(
        path: '/receipt',
        pageBuilder: (c, s) => _fade(s, const ReceiptScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (c, s) => _fade(s, const DashboardScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (c, s) => _fade(s, const SettingsScreen()),
      ),
    ],
  );

  /// Fast fade transition (no horizontal slide — feels instant).
  static CustomTransitionPage _fade(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 100),
      transitionsBuilder: (c, anim, sec, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }
}
