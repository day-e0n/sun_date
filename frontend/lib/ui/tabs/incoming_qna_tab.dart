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
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MatchSession>>(
      future: widget.api.listMyMatches(userId: widget.me.studentId), // id -> studentId
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('받은 질문 목록을 불러오는 중 오류: ${snapshot.error}'),
          );
        }
        final matches = snapshot.data ?? [];
        final incomingMatches = matches
            .where((m) => m.partnerUserId == widget.me.studentId) // id -> studentId
            .toList();

        if (incomingMatches.isEmpty) {
          return const Center(child: Text('아직 받은 질문이 없습니다.'));
        }

        return ListView.separated(
          itemCount: incomingMatches.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final match = incomingMatches[index];
            return ListTile(
              title: Text('${match.selfUserId} 님에게서 온 질문'),
              subtitle: Text('답변을 기다리는 중입니다.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 답변하는 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('답변 화면은 아직 구현되지 않았습니다.')),
                );
              },
            );
          },
        );
      },
    );
  }
}
