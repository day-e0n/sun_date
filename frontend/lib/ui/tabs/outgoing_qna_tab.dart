import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class OutgoingQnaTab extends StatelessWidget {
  final MatchApi api;
  final UserProfile me;

  const OutgoingQnaTab({super.key, required this.api, required this.me});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(8),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final item = questions[index];
            final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To: ${item.receiverName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(height: 16),
                    ...item.questions.asMap().entries.map((e) {
                      return Text('${e.key + 1}. ${e.value}');
                    }),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '상태: ${item.status.name}',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '보낸 시각: $formattedDate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
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
