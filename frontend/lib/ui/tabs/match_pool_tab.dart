import 'package:flutter/material.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class MatchPoolTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile currentUser;

  const MatchPoolTab({super.key, required this.api, required this.currentUser});

  @override
  State<MatchPoolTab> createState() => _MatchPoolTabState();
}

class _MatchPoolTabState extends State<MatchPoolTab> {
  // 더미 데이터 생성
  final List<UserProfile> _dummyUsers = List.generate(10, (i) {
    final gender = i % 2 == 0 ? Gender.male : Gender.female;
    return UserProfile(
      studentId: '2024000$i',
      nickname: '테스트유저$i',
      age: 20 + i,
      gender: gender,
      mbti: ['INFP', 'ENFP', 'ISTJ', 'ESTJ'][i % 4],
      region: ['서울', '경기', '인천', '부산'][i % 4],
      preferredCategories: [[VolunteerCategory.animal], [VolunteerCategory.education]][i % 2],
      preferredTimeSlots: [[TimeSlot.afternoon], [TimeSlot.morning]][i % 2],
      preferredRegion: ['서울', '경기'][i % 2],
    );
  });

  // 선택된 사용자 추적
  String? _selectedUserId;

  // 카테고리 라벨 헬퍼
  static String _categoryLabel(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '동물 돌봄';
      case VolunteerCategory.nursingHome:
        return '이웃 돌봄';
      case VolunteerCategory.environment:
        return '환경보호';
      case VolunteerCategory.education:
        return '교육·멘토링';
      default:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상대 찾기'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _dummyUsers.length,
              itemBuilder: (context, index) {
                final user = _dummyUsers[index];
                final isSelected = _selectedUserId == user.studentId;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    leading: CircleAvatar(
                      child: Text(user.nickname.substring(0, 1)),
                    ),
                    title: Text(user.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${user.age}세 / ${user.gender == Gender.male ? '남' : '여'} / ${user.region}'),
                        const SizedBox(height: 2),
                        Text('MBTI: ${user.mbti}'),
                        const SizedBox(height: 2),
                        Text('선호 봉사: ${user.preferredCategories.map(_categoryLabel).join(', ')}'),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserId = null; // Toggle off
                        } else {
                          _selectedUserId = user.studentId;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // 매칭 요청 버튼
          if (_selectedUserId != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('매칭 요청이 전송되었습니다 (더미)')),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('매칭 요청 보내기'),
              ),
            ),
        ],
      ),
    );
  }
}
