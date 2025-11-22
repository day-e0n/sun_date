import 'package:flutter/material.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class QnaMatchScreen extends StatefulWidget {
  final MatchApi api;
  final UserProfile? currentUser;
  final void Function(MatchSession session)? onMatchCreated;

  const QnaMatchScreen({
    super.key,
    required this.api,
    required this.currentUser,
    this.onMatchCreated,
  });

  @override
  State<QnaMatchScreen> createState() => _QnaMatchScreenState();
}

class _QnaMatchScreenState extends State<QnaMatchScreen> {
  MatchSession? _session;
  List<QnaMessage> _questions = [];
  final List<TextEditingController> _answerCtrls = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initMatchIfNeeded();
  }

  @override
  void dispose() {
    for (var ctrl in _answerCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initMatchIfNeeded() async {
    if (widget.currentUser == null || _session != null) return;
    setState(() => _loading = true);
    try {
      final s = await widget.api.requestMatch(userId: widget.currentUser!.studentId);
      _session = s;
      widget.onMatchCreated?.call(s);
      await _refreshMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshMessages() async {
    if (_session == null) return;
    final msgs = await widget.api.getConversation(matchId: _session!.id);
    if (mounted) {
      setState(() {
        _questions = msgs.where((m) => m.sender == MessageSender.partner).toList();
        // 질문 수에 맞게 답변 컨트롤러 초기화
        _answerCtrls.forEach((c) => c.dispose());
        _answerCtrls.clear();
        for (int i = 0; i < _questions.length; i++) {
          _answerCtrls.add(TextEditingController());
        }
      });
    }
  }

  Future<void> _sendAnswers() async {
    if (_session == null || widget.currentUser == null) return;

    final answers = _answerCtrls.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 질문에 답변해주세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // 여러 답변을 순차적으로 전송
      for (final answer in answers) {
        await widget.api.sendAnswer(
          matchId: _session!.id,
          fromUserId: widget.currentUser!.studentId,
          content: answer,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답변을 성공적으로 전송했습니다!')),
      );
      // 매칭 수락/종료 화면으로 이동하거나, 홈으로 복귀 등의 로직 추가 가능
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('답변 전송 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Center(child: Text('먼저 프로필을 완료해 주세요.'));
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('1:1 QnA')),
      body: Column(
        children: [
          Expanded(
            child: _loading && _questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              // 질문과 답변 쌍으로 아이템 수 설정
              itemCount: _questions.length * 2,
              itemBuilder: (ctx, i) {
                final questionIndex = i ~/ 2;
                final isQuestion = i % 2 == 0;

                if (isQuestion) {
                  // 질문 버블
                  final q = _questions[questionIndex];
                  return _buildMessageBubble(
                    message: q.content,
                    isSelf: false,
                    colorScheme: colorScheme,
                  );
                } else {
                  // 답변 입력 버블
                  return _buildAnswerInputBubble(
                    controller: _answerCtrls[questionIndex],
                    colorScheme: colorScheme,
                  );
                }
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _loading ? null : _sendAnswers,
              icon: const Icon(Icons.send),
              label: const Text('답변 전송'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isSelf,
    required ColorScheme colorScheme,
  }) {
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelf
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isSelf
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInputBubble({
    required TextEditingController controller,
    required ColorScheme colorScheme,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '여기에 답변 입력...',
            hintStyle: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.6)),
          ),
          style: TextStyle(color: colorScheme.onPrimaryContainer),
          maxLines: null, // 여러 줄 입력 지원
        ),
      ),
    );
  }
}
