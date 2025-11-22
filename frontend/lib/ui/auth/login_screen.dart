import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/match_api.dart';

class LoginScreen extends StatefulWidget {
  final MatchApi api;
  final String? successMessage;

  const LoginScreen({super.key, required this.api, this.successMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Show success message if coming from signup
    if (widget.successMessage != null) {
      // Post a frame to ensure Scaffold is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.successMessage!)),
        );
      });
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_studentIdCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학번과 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final profile = await widget.api.login(
        studentId: _studentIdCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString('user_profile', profileJson);

      if (!mounted) return;
      context.go('/'); // Go to AppShell
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학번 또는 비밀번호가 일치하지 않습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToSignUp() {
    context.push('/signup'); // Go to Onboarding
  }

  void _findPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호 찾기 기능은 구현 예정입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                '선데이트',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '봉사로 만나는 새로운 인연',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(flex: 2),
              TextField(
                controller: _studentIdCtrl,
                decoration: const InputDecoration(
                  labelText: '학번',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('로그인'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _findPassword,
                    child: const Text('비밀번호 찾기'),
                  ),
                  const Text('|'),
                  TextButton(
                    onPressed: _goToSignUp,
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
