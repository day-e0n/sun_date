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
    _loadTokenAndFetchUsers();
    _checkFixedQuestions(); // 고정 질문 확인
  }

  Future<void> _checkFixedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final q1 = prefs.getString('fixed_question_1') ?? '';
    final q2 = prefs.getString('fixed_question_2') ?? '';
    final q3 = prefs.getString('fixed_question_3') ?? '';

    if (q1.isEmpty || q2.isEmpty || q3.isEmpty) {
      // 고정 질문이 없으면 안내
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 탭에서 매칭 질문을 먼저 설정해주세요!'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    }
  }

  Future<void> _loadTokenAndFetchUsers() async {
    await _loadToken();
    _fetchUsersByCategory(_selectedCategory);
  }


  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString("token");
  }

  // Convert VolunteerCategory → 서버에서 기대하는 volunteer_field 문자열
  String _categoryToServerString(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return "동물";
      case VolunteerCategory.education:
        return "교육";
      case VolunteerCategory.environment:
        return "환경";
      case VolunteerCategory.nursingHome:
        return "시설";
      default:
        return "기타";
    }
  }

  // 서버에서 사용자 목록 불러오기 (실패시 MockApi 사용)
  Future<void> _fetchUsersByCategory(VolunteerCategory category) async {
    setState(() => _loading = true);

    try {
      // 1. 서버 API 시도
      if (_authToken == null) {
        await _loadToken();
      }

      if (_authToken != null) {
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

        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(resp.bodyBytes));

          setState(() {
            _users = data.map((e) {
              return UserProfile(
                studentId: e["student_id"] ?? "",
                nickname: e["nickname"] ?? "",
                age: e["age"] ?? 0,
                sex: e["sex"] ?? "unknown",
                mbti: e["mbti"] ?? "",
                location: e["location"] ?? "",
                volunteerField: e["volunteer_field"],
              );
            }).toList();
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      print("서버 API 호출 실패, MockApi 사용: $e");
    }

    // 2. 서버 API 실패시 MockApi의 더미 데이터 사용
    try {
      final candidates = await widget.api.listCandidates(
        userId: widget.currentUser.studentId,
        categoryFilter: category,
      );

      if (mounted) {
        setState(() {
          _users = candidates;
          _loading = false;
        });
      }
    } catch (e) {
      print("MockApi 호출도 실패: $e");
      if (mounted) {
        setState(() {
          _users = [];
          _loading = false;
        });
      }
    }
  }

  // 매칭 요청 보내기
  Future<void> _handleSendRequest(UserProfile toUser) async {
    final prefs = await SharedPreferences.getInstance();
    final q1 = prefs.getString('fixed_question_1') ?? '';
    final q2 = prefs.getString('fixed_question_2') ?? '';
    final q3 = prefs.getString('fixed_question_3') ?? '';

    if (q1.isEmpty || q2.isEmpty || q3.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('질문 설정 필요'),
          content: const Text('매칭 요청을 보내려면\n프로필 탭에서 고정 질문 3개를\n먼저 설정해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    if (toUser.studentId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청을 보낼 사용자의 학번 정보가 없습니다.')),
      );
      return;
    }

    try {
      await widget.api.sendMatchRequest(
        fromUserId: widget.currentUser.studentId,
        toUser: toUser,
        questions: [q1, q2, q3],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${toUser.nickname}님에게 매칭 요청을 보냈습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _selectedUserId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매칭 요청 실패: $e')),
      );
    }
  }

  static String _categoryLabel(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '동물';
      case VolunteerCategory.nursingHome:
        return '시설';
      case VolunteerCategory.environment:
        return '환경';
      case VolunteerCategory.education:
        return '교육';
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedUserId =
                      isSelected ? null : user.studentId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.pinkAccent.shade100,
                                child: Text(
                                  user.nickname.isNotEmpty ? user.nickname[0] : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.age}세 · ${user.sex == "male" ? "남성" : "여성"} · ${user.location}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text('MBTI: ${user.mbti}'),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: const TextStyle(fontSize: 12),
                              ),
                              if (user.volunteerField != null)
                                Chip(
                                  label: Text(user.volunteerField!),
                                  backgroundColor: Colors.green.shade50,
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _handleSendRequest(user),
                                icon: const Icon(Icons.send),
                                label: const Text("매칭 요청 보내기"),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                ),
                              ),
                            ),
                          ],
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