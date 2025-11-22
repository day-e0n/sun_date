// lib/ui/tabs/incoming_qna_tab.dart
import 'package:flutter/material.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

class IncomingQnaTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const IncomingQnaTab({
    super.key,
    required this.api,
    required this.me,
  });

  @override
  State<IncomingQnaTab> createState() => _IncomingQnaTabState();
}

class _IncomingQnaTabState extends State<IncomingQnaTab> {
  MatchSession? _selectedMatch;
  final _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 좌측: 내가 참여 중인 매칭 리스트
        SizedBox(
          width: 220,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '받은 질문 / 매칭 목록',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<MatchSession>>(
                  future: widget.api.listMyMatches(userId: widget.me.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('매칭을 불러오는 중 오류가 발생했습니다: ${snapshot.error}'),
                      );
                    }
                    final matches = snapshot.data ?? [];
                    if (matches.isEmpty) {
                      return const Center(
                        child: Text('현재 진행 중인 매칭이 없습니다.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = matches[index];
                        final selected = _selectedMatch?.id == m.id;

                        // 현재 유저 기준으로 상대 id 추론
                        final partnerId = (m.selfUserId == widget.me.id)
                            ? m.partnerUserId
                            : m.selfUserId;

                        return ListTile(
                          selected: selected,
                          title: Text('상대: $partnerId'),
                          subtitle: Text('매칭 ID: ${m.id}'),
                          onTap: () {
                            setState(() => _selectedMatch = m);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedMatch == null
              ? const Center(
            child: Text('좌측에서 매칭을 선택해 주세요.'),
          )
              : _buildIncomingDetail(_selectedMatch!),
        ),
      ],
    );
  }

  Widget _buildIncomingDetail(MatchSession match) {
    final partnerId = (match.selfUserId == widget.me.id)
        ? match.partnerUserId
        : match.selfUserId;

    return Column(
      children: [
        ListTile(
          title: Text('상대: $partnerId'),
          subtitle: const Text('서로 질문과 답변을 주고받을 수 있습니다.'),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<QnaMessage>>(
            future: widget.api.getConversation(matchId: match.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('대화를 불러오는 중 오류가 발생했습니다: ${snapshot.error}'),
                );
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text('아직 대화가 없습니다. 먼저 질문을 보내보세요.'),
                );
              }

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[messages.length - 1 - index];

                  // MockMatchApi 에서는 sender 가 self / partner 로만 들어감
                  final isSelfSide = m.sender == MessageSender.self;

                  return Align(
                    alignment: isSelfSide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelfSide
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(m.content),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(
                    hintText: '답변 또는 메시지를 입력하세요...',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  final text = _answerCtrl.text.trim();
                  if (text.isEmpty) return;

                  // 여기서는 "답변"으로 간주해서 sendAnswer 사용
                  await widget.api.sendAnswer(
                    matchId: match.id,
                    fromUserId: widget.me.id,
                    content: text,
                  );

                  _answerCtrl.clear();
                  // 새로고침
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}