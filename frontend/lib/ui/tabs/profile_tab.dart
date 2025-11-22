import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models.dart';

class ProfileTab extends StatelessWidget {
  final UserProfile me;

  const ProfileTab({
    super.key,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 상단 프로필 영역
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              child: Text(me.nickname.isNotEmpty ? me.nickname.substring(0, 1) : ""),
            ),
            title: Text(
              me.nickname,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${me.mbti} · ${me.location}'),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // 기본 정보
          ListTile(
            title: const Text('학번'),
            subtitle: Text(me.studentId),
          ),
          ListTile(
            title: const Text('나이'),
            subtitle: Text(me.age.toString()),
          ),
          ListTile(
            title: const Text('성별'),
            subtitle: Text(_genderLabel(me.sex)),
          ),
          ListTile(
            title: const Text('선호 봉사 카테고리'),
            subtitle: Text(me.volunteerField ?? '-'),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              // TODO: 프로필 수정 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('프로필 수정 화면은 추후 구현 예정입니다.'),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('프로필 수정'),
          ),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () {
              context.push('/fixed-questions');
            },
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('매칭 상대에게 보낼 질문 설정'),
          ),
        ],
      ),
    );
  }

  static String _genderLabel(String g) {
    switch (g.toLowerCase()) {
      case 'female':
        return '여성';
      case 'male':
        return '남성';
      default:
        return g;
    }
  }
}
