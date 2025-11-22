// lib/ui/tabs/outgoing_qna_tab.dart
import 'package:flutter/material.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

class OutgoingQnaTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const OutgoingQnaTab({
    super.key,
    required this.api,
    required this.me,
  });

  @override
  State<OutgoingQnaTab> createState() => _OutgoingQnaTabState();
}

class _OutgoingQnaTabState extends State<OutgoingQnaTab> {
  MatchSession? _selectedMatch;
  final _questionCtrl = TextEditingController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 내가 시작한 QnA(= selfUserId == me.studentId) 리스트
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '진행 중인 QnA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<MatchSession>>(
                  future: widget.api.listMyMatches(userId: widget.me.studentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('QnA 목록을 불러오는 중 오류가 발생했습니다: ${snapshot.error}'),
                      );
                    }

                    // 내가 "selfUserId" 인 세션만 내보냄 = 내가 매칭을 시작한 방
                    final allMatches = snapshot.data ?? [];
                    final matches = allMatches
                        .where((m) => m.selfUserId == widget.me.studentId)
                        .toList();

                    if (matches.isEmpty) {
                      return const Center(
                        child: Text('진행 중인 QnA가 없습니다.\n상대 찾기 탭에서 먼저 시작해 보세요.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = matches[index];
                        final selected = _selectedMatch?.id == m.id;

                        final partnerId = m.partnerUserId;

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
                  child: Text('좌측에서 대화를 선택해 주세요.'),
                )
              : _buildRoomDetail(_selectedMatch!),
        ),
      ],
    );
  }

  Widget _buildRoomDetail(MatchSession match) {
    final partnerId = match.partnerUserId;

    return Column(
      children: [
        ListTile(
          title: Text('상대: $partnerId'),
          subtitle: const Text('QnA 진행 중입니다. 질문을 보내보세요.'),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<QnaMessage>>(
            // key를 추가하여 setState() 호출 시 FutureBuilder가 재실행되도록 함
            key: ValueKey(match.id),
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
                  child: Text('아직 대화가 없습니다. 첫 질문을 보내보세요.'),
                );
              }

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[messages.length - 1 - index];
                  final isMe = m.sender == MessageSender.self;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(m.content,
                          style: TextStyle(
                              color: isMe
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
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
                  controller: _questionCtrl,
                  decoration: const InputDecoration(
                    hintText: '질문 또는 메시지를 입력하세요...',
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
                  final text = _questionCtrl.text.trim();
                  if (text.isEmpty || _selectedMatch == null) return;

                  await widget.api.sendQuestion(
                    matchId: match.id,
                    fromUserId: widget.me.studentId,
                    content: text,
                  );
                  _questionCtrl.clear();
                  // Re-fetch messages after sending
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
