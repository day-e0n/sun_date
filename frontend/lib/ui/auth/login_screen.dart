// lib/ui/auth/login_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/match_api.dart';

class LoginScreen extends StatefulWidget {
  final MatchApi api;
  final String? successMessage;

  const LoginScreen({
    super.key,
    required this.api,
    this.successMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _studentIdCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 회원가입 후 넘어올 때 성공 메시지 표시
    if (widget.successMessage != null) {
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
    final studentId = _studentIdCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학번과 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1) 로그인 요청
      debugPrint('=== LOGIN REQUEST START ===');
      final loginResp = await http.post(
        Uri.parse('http://220.149.241.209:8000/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'password': password,
        }),
      );

      debugPrint('LOGIN status: ${loginResp.statusCode}');
      debugPrint('LOGIN body: ${loginResp.body}');

      if (loginResp.statusCode != 200 && loginResp.statusCode != 201) {
        throw Exception('로그인 실패: ${loginResp.body}');
      }

      final loginData = jsonDecode(loginResp.body) as Map<String, dynamic>;
      final token = loginData['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('서버 응답에 token 필드가 없습니다.');
      }

      // 2) 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // 3) 토큰으로 /api/user-profile/ 조회
      final profileResp = await http.get(
        Uri.parse('http://220.149.241.209:8000/api/user-profile/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      debugPrint('PROFILE status: ${profileResp.statusCode}');
      debugPrint('PROFILE body: ${profileResp.body}');

      if (profileResp.statusCode != 200) {
        throw Exception('프로필 조회 실패: ${profileResp.body}');
      }

      // 그대로 문자열 형태로 저장 (AppShell에서 jsonDecode + UserProfile.fromJson 사용)
      await prefs.setString('user_profile', profileResp.body);

      debugPrint('=== LOGIN SUCCESS, NAVIGATE TO "/" ===');

      if (!mounted) return;
      context.go('/'); // 메인(AppShell)으로 이동

    } catch (e) {
      if (!mounted) return;
      debugPrint('LOGIN ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToSignUp() {
    context.push('/signup');
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
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
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