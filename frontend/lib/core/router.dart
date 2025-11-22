import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sundate/core/models.dart';
import 'package:sundate/ui/matching/qna_thread_screen.dart';
import 'package:sundate/core/match_api.dart'; // 수정
import 'package:sundate/ui/app_shell.dart'; // 수정
import 'package:sundate/ui/auth/login_screen.dart'; // 수정
import 'package:sundate/ui/onboarding/onboarding_flow_screen.dart'; // 수정
import 'package:sundate/ui/screens/fixed_questions_screen.dart'; // 수정

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
        routes: [
          GoRoute(
            path: 'qna/:id',
            builder: (context, state) {
              // extra를 Map으로 받아 여러 객체를 전달
              final extra = state.extra as Map<String, dynamic>?;
              final question = extra?['question'] as SentQuestion?;
              final me = extra?['me'] as UserProfile?;

              if (question == null || me == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: Data not found.')),
                );
              }
              // api와 me 객체도 함께 전달
              return QnaThreadScreen(api: api, me: me, question: question);
            },
          ),
        ],
      ),
    ],
  );
}
