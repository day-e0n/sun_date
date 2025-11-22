import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class IncomingQnaTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const IncomingQnaTab({super.key, required this.api, required this.me});

  @override
  State<IncomingQnaTab> createState() => _IncomingQnaTabState();
}

class _IncomingQnaTabState extends State<IncomingQnaTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SentQuestion>>(
      future: widget.api.listReceivedQuestions(userId: widget.me.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('받은 질문 목록을 불러오는 중 오류: ${snapshot.error}'),
          );
        }
        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return const Center(child: Text('아직 받은 질문이 없습니다.'));
        }

        return ListView.separated(
          itemCount: questions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = questions[index];
            return ListTile(
              title: Text('${item.senderName} 님에게서 온 질문'),
              subtitle: Text(
                item.status == SentQuestionStatus.pending
                    ? '답변을 기다리는 중입니다.'
                    : '답변 완료',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.go('/qna/${item.id}', extra: {'question': item, 'me': widget.me});
              },
            );
          },
        );
      },
    );
  }
}
