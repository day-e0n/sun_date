import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundate/ui/tabs/qna_box_tab.dart';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';
import 'package:sundate/ui/tabs/profile_tab.dart';
import 'package:sundate/ui/tabs/match_pool_tab.dart';
import 'tabs/agency_tab.dart';

class AppShell extends StatefulWidget {
  final MatchApi api;

  const AppShell({super.key, required this.api});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  UserProfile? _currentUser;
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }


  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      final profileMap = jsonDecode(profileJson);
      setState(() {
        _currentUser = UserProfile.fromJson(profileMap);
        _loading = false;
      });
    } else {
      if (mounted) context.go('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = [
      MatchPoolTab(api: widget.api, currentUser: _currentUser!),
      QnaBoxTab(api: widget.api, me: _currentUser!),
      const Center(child: Text('봉사기관')),
      ProfileTab(me: _currentUser!),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: '상대 찾기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: '질문함',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism),
            label: '봉사기관',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 프로필',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
