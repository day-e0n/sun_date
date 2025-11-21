// lib/ui/app_shell.dart
import 'package:flutter/material.dart';

import '../core/match_api.dart';
import '../core/models.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'tabs/discovery_tab.dart';
import 'tabs/outgoing_qna_tab.dart';
import 'tabs/incoming_qna_tab.dart';
import 'tabs/profile_tab.dart';

class AppShell extends StatefulWidget {
  final MatchApi api;

  const AppShell({super.key, required this.api});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  UserProfile? _me;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 아직 프로필(온보딩) 안 끝났으면 온보딩부터
    if (_me == null) {
      return OnboardingFlowScreen(
        api: widget.api,
        onCompleted: (profile) {
          setState(() => _me = profile);
        },
      );
    }

    final user = _me!;
    final tabs = [
      DiscoveryTab(api: widget.api, me: user),
      OutgoingQnaTab(api: widget.api, me: user),
      IncomingQnaTab(api: widget.api, me: user),
      ProfileTab(api: widget.api, me: user),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: '상대 찾기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '1:1 질문',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            label: '받은 질문',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '내 계정',
          ),
        ],
      ),
    );
  }
}