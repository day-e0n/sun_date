import 'package:flutter/material.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';
import '../matching/qna_match_screen.dart';

class DiscoveryTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const DiscoveryTab({super.key, required this.api, required this.me});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상대 찾기'),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<UserProfile>>(
              future: widget.api.listCandidates(userId: widget.me.studentId), // id -> studentId
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('후보 목록을 불러오는 중 오류: ${snapshot.error}'));
                }
                final candidates = snapshot.data ?? [];
                if (candidates.isEmpty) {
                  return const Center(child: Text('아직 매칭 상대가 없습니다.'));
                }
                return ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = candidates[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.nickname.substring(0, 1)),
                      ),
                      title: Text(user.nickname),
                      subtitle: Text('${user.mbti} · ${user.region}'),
                      onTap: () async {
                        // 1:1 QnA 매칭 생성
                        final session = await widget.api.requestMatch(
                          userId: widget.me.studentId, // id -> studentId
                        );
                        // QnA 화면으로 이동
                        if (!mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QnaMatchScreen(
                              api: widget.api,
                              currentUser: widget.me,
                              onMatchCreated: (newSession) {},
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
