import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FixedQuestionsScreen extends StatefulWidget {
  const FixedQuestionsScreen({super.key});

  @override
  State<FixedQuestionsScreen> createState() => _FixedQuestionsScreenState();
}

class _FixedQuestionsScreenState extends State<FixedQuestionsScreen> {
  final _q1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _q3Ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _q1Ctrl.text = prefs.getString('fixed_question_1') ?? '';
      _q2Ctrl.text = prefs.getString('fixed_question_2') ?? '';
      _q3Ctrl.text = prefs.getString('fixed_question_3') ?? '';
      _loading = false;
    });
  }

  Future<void> _saveQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fixed_question_1', _q1Ctrl.text.trim());
    await prefs.setString('fixed_question_2', _q2Ctrl.text.trim());
    await prefs.setString('fixed_question_3', _q3Ctrl.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('질문이 저장되었습니다.')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _q1Ctrl.dispose();
    _q2Ctrl.dispose();
    _q3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고정 질문 설정'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  '매칭 요청 시 상대에게 자동 발송되는 질문 3개를 등록하세요.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _q1Ctrl,
                  decoration: const InputDecoration(
                    labelText: '질문 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _q2Ctrl,
                  decoration: const InputDecoration(
                    labelText: '질문 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _q3Ctrl,
                  decoration: const InputDecoration(
                    labelText: '질문 3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saveQuestions,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('저장하기'),
                ),
              ],
            ),
    );
  }
}
