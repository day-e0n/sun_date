import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';

class MatchPoolTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile currentUser;

  const MatchPoolTab({super.key, required this.api, required this.currentUser});

  @override
  State<MatchPoolTab> createState() => _MatchPoolTabState();
}

class _MatchPoolTabState extends State<MatchPoolTab> {
  // 더미 데이터 생성 (카테고리 다양화)
  final List<UserProfile> _dummyUsers = List.generate(10, (i) {
    return UserProfile(
      studentId: '2024000$i',
      nickname: '테스트유저$i',
      age: 20 + i,
      gender: i % 2 == 0 ? Gender.male : Gender.female,
      mbti: ['INFP', 'ENFP', 'ISTJ', 'ESTJ'][i % 4],
      region: ['서울', '경기', '인천', '부산'][i % 4],
      // 카테고리를 다양하게 분포
      preferredCategories: [
        if (i % 3 == 0) VolunteerCategory.animal,
        if (i % 3 == 1) VolunteerCategory.education,
        if (i % 3 == 2) VolunteerCategory.nursingHome,
        if (i > 7) VolunteerCategory.environment,
      ],
      preferredTimeSlots: [[TimeSlot.afternoon], [TimeSlot.morning]][i % 2],
      preferredRegion: ['서울', '경기'][i % 2],
    );
  });

  // 선택된 사용자 및 카테고리 추적
  String? _selectedUserId;
  VolunteerCategory _selectedCategory = VolunteerCategory.animal; // '전체'를 없애고 기본값 설정

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
    setState(() {
      _selectedUserId = null;
    });
  }

  void _onCategorySelected(VolunteerCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedUserId = null; // 필터 변경 시 카드 선택 해제
    });
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 카테고리에 따라 사용자 목록 필터링
    final filteredUsers = _dummyUsers.where((user) => user.preferredCategories.contains(_selectedCategory)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('상대 찾기'),
      ),
      body: Column(
        children: [
          // 1. 카테고리 필터 UI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: VolunteerCategory.values.map((category) {
                return ChoiceChip(
                  label: Text(_categoryLabel(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      _onCategorySelected(category);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // 2. 필터링된 후보자 목록
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
              child: Text('해당 카테고리에 맞는 상대가 없습니다.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
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
                                CircleAvatar(child: Text(user.nickname.substring(0, 1))),
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
          ),
        ],
      ),
    );
  }
}
