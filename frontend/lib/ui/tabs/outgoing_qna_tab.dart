import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sundate/core/match_api.dart'; // 수정
import 'package:sundate/core/models.dart'; // 수정

class OutgoingQnaTab extends StatelessWidget {
  final MatchApi api;
  final UserProfile me;

  const OutgoingQnaTab({super.key, required this.api, required this.me});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<SentQuestion>>(
      future: api.listSentQuestions(userId: me.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('보낸 질문 목록을 불러오는 중 오류: ${snapshot.error}'));
        }
        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return const Center(child: Text('아직 보낸 질문이 없습니다.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final item = questions[index];
            final formattedDate = DateFormat('MM/dd HH:mm').format(item.createdAt);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                onTap: () {
                  // extra를 Map 형태로 전달하도록 수정
                  context.go('/qna/${item.id}', extra: {'question': item, 'me': me});
                },
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(
                  '${item.receiverName}님에게 보낸 질문',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '상태: ${item.status.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formattedDate, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
