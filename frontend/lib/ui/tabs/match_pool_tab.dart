import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String? _selectedUserId;

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

  Future<void> _handleSendRequest(UserProfile toUser) async {
    final prefs = await SharedPreferences.getInstance();
    final q1 = prefs.getString('fixed_question_1') ?? '';
    final q2 = prefs.getString('fixed_question_2') ?? '';
    final q3 = prefs.getString('fixed_question_3') ?? '';

    if (q1.isEmpty || q2.isEmpty || q3.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 탭에서 고정 질문을 먼저 설정해주세요.')),
      );
      return;
    }

    await widget.api.sendMatchRequest(
      fromUserId: widget.currentUser.studentId,
      toUser: toUser,
      questions: [q1, q2, q3],
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${toUser.nickname}님에게 매칭 요청을 보냈습니다.')),
    );
    // Close the card after sending
    setState(() {
      _selectedUserId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상대 찾기'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _dummyUsers.length,
        itemBuilder: (context, index) {
          final user = _dummyUsers[index];
          final isSelected = _selectedUserId == user.studentId;

          return Card(
            elevation: isSelected ? 4 : 1,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedUserId = null; 
                  } else {
                    _selectedUserId = user.studentId;
                  }
                });
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(user.nickname.substring(0, 1)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${user.age}세 / ${user.gender == Gender.male ? '남' : '여'} / ${user.region}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('MBTI: ${user.mbti}'),
                      const SizedBox(height: 2),
                      Text('선호 봉사: ${user.preferredCategories.map(_categoryLabel).join(', ')}'),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _handleSendRequest(user),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('매칭 요청 보내기'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
