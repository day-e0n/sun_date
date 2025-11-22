import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sundate/core/match_api.dart';
import 'package:sundate/ui/app_shell.dart';
import 'package:sundate/ui/auth/login_screen.dart';
import 'package:sundate/ui/onboarding/onboarding_flow_screen.dart';
import 'package:sundate/ui/screens/fixed_questions_screen.dart';


GoRouter createRouter(MatchApi api) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final message = extra?['message'] as String?;
          return LoginScreen(api: api, successMessage: message);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => OnboardingFlowScreen(api: api),
      ),
      GoRoute(
        path: '/fixed-questions',
        builder: (context, state) => const FixedQuestionsScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => AppShell(api: api),
      ),
    ],
  );
}