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
  List<QnaMessage> _messages = [];
  final _questionCtrl = TextEditingController();
  bool _loading = false;
  int _selfQuestionCount = 0;

  @override
  void initState() {
    super.initState();
    _initMatchIfNeeded();
  }

  Future<void> _initMatchIfNeeded() async {
    if (widget.currentUser == null || _session != null) return;
    setState(() => _loading = true);
    try {
      final s = await widget.api.requestMatch(userId: widget.currentUser!.id);
      _session = s;
      widget.onMatchCreated?.call(s);
      await _refreshMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshMessages() async {
    if (_session == null) return;
    final msgs =
    await widget.api.getConversation(matchId: _session!.id);
    if (mounted) setState(() => _messages = msgs);
  }

  Future<void> _sendQuestion() async {
    if (_session == null || widget.currentUser == null) return;
    if (_selfQuestionCount >= 3) return;
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      await widget.api.sendQuestion(
        matchId: _session!.id,
        fromUserId: widget.currentUser!.id,
        content: text,
      );
      _selfQuestionCount++;
      _questionCtrl.clear();
      await _refreshMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 테스트용: 실제론 상대 단말에서 sendAnswer 호출
  Future<void> _sendAnswerAsPartner() async {
    if (_session == null) return;
    if (_messages.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.api.sendAnswer(
        matchId: _session!.id,
        fromUserId: _session!.partnerUserId,
        content: '테스트 답변입니다.',
      );
      await _refreshMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish(bool ok) async {
    if (_session == null || widget.currentUser == null) return;
    setState(() => _loading = true);
    try {
      await widget.api.finishMatch(
        matchId: _session!.id,
        userId: widget.currentUser!.id,
        accepted: ok,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '이 파트너와 계속 진행합니다.' : '매칭을 취소했습니다.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 QnA 매칭')),
      body: Column(
        children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isSelf =
                    m.sender == MessageSender.self;
                return Align(
                  alignment: isSelf
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelf
                          ? Colors.pink.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionCtrl,
                        decoration: InputDecoration(
                          labelText:
                          '질문 입력 (남은 질문 ${3 - _selfQuestionCount})',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                      _loading ? null : _sendQuestion,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                      _loading ? null : _sendAnswerAsPartner,
                      child: const Text('테스트 답변 받기'),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _finish(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading ? null : () => _finish(true),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 