import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';
import 'package:http/http.dart' as http;

class MatchPoolTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile currentUser;

  const MatchPoolTab({super.key, required this.api, required this.currentUser});

  @override
  State<MatchPoolTab> createState() => _MatchPoolTabState();
}

class _MatchPoolTabState extends State<MatchPoolTab> {
  List<UserProfile> _users = [];
  VolunteerCategory _selectedCategory = VolunteerCategory.animal;
  String? _authToken;
  bool _loading = false;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _fetchUsersByCategory(_selectedCategory);
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString("auth_token");
  }

  // Convert VolunteerCategory → 서버에서 기대하는 volunteer_field 문자열
  String _categoryToServerString(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return "동물";
      case VolunteerCategory.education:
        return "교육·멘토링";
      case VolunteerCategory.environment:
        return "환경보호";
      case VolunteerCategory.nursingHome:
        return "이웃 돌봄";
      default:
        return "기타";
    }
  }

  // 서버에서 사용자 목록 불러오기
  Future<void> _fetchUsersByCategory(VolunteerCategory category) async {
    if (_authToken == null) return;

    setState(() => _loading = true);

    final url = Uri.parse("http://220.149.241.209:8000/api/volunteer-search/");
    final resp = await http.post(
      url,
      headers: {
        "Authorization": "Token $_authToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "volunteer_field": _categoryToServerString(category),
      }),
    );

    if (resp.statusCode != 200) {
      print("검색 실패: ${resp.body}");
      setState(() => _loading = false);
      return;
    }

    final List<dynamic> data = jsonDecode(resp.body);

    setState(() {
      _users = data.map((e) {
        return UserProfile(
          studentId: "",
          nickname: e["nickname"] ?? "",
          age: e["age"] ?? 0,
          gender: (e["sex"] == "male") ? Gender.male : Gender.female,
          mbti: e["mbti"] ?? "",
          region: e["location"] ?? "",
          preferredCategories: [category],
        );
      }).toList();
      _loading = false;
    });
  }

  // 매칭 요청 보내기 (이전 로직 사용)
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
      appBar: AppBar(title: const Text('상대 찾기')),
      body: Column(
        children: [
          // 카테고리 선택
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: VolunteerCategory.values.map((category) {
                return ChoiceChip(
                  label: Text(_categoryLabel(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                      _fetchUsersByCategory(category);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // 사용자 목록
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? const Center(child: Text("해당 카테고리에 맞는 상대가 없습니다."))
                : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = _selectedUserId == user.nickname;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedUserId =
                      isSelected ? null : user.nickname);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.nickname,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text('${user.age}세 / ${user.region}'),
                          Text('MBTI: ${user.mbti}'),
                          if (isSelected)
                            FilledButton(
                              onPressed: () =>
                                  _handleSendRequest(user),
                              child: const Text("매칭 요청 보내기"),
                            ),
                        ],
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