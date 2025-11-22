// lib/ui/matching/volunteer_match_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷 필요 없으면 삭제해도 됨
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

/// 백엔드 volunteer-search 응답 1개 원소를 표현하는 간단한 모델
class VolunteerUser {
  final String nickname;
  final int? age;
  final String sex;
  final String mbti;
  final String location;
  final String volunteerField;

  VolunteerUser({
    required this.nickname,
    required this.age,
    required this.sex,
    required this.mbti,
    required this.location,
    required this.volunteerField,
  });

  factory VolunteerUser.fromJson(Map<String, dynamic> json) {
    return VolunteerUser(
      nickname: json['nickname'] as String? ?? '',
      age: json['age'] as int?, // null 가능
      sex: json['sex'] as String? ?? '',
      mbti: json['mbti'] as String? ?? '',
      location: json['location'] as String? ?? '',
      volunteerField: json['volunteer_field'] as String? ?? '',
    );
  }
}

class VolunteerMatchScreen extends StatefulWidget {
  final MatchApi api;          // 지금은 사용 안 할 수도 있지만, 구조 유지
  final UserProfile? currentUser;
  final MatchSession? currentMatch;

  const VolunteerMatchScreen({
    super.key,
    required this.api,
    this.currentUser,
    this.currentMatch,
  });

  @override
  State<VolunteerMatchScreen> createState() => _VolunteerMatchScreenState();
}

class _VolunteerMatchScreenState extends State<VolunteerMatchScreen> {
  VolunteerCategory _selectedCategory = VolunteerCategory.animal;
  Future<List<VolunteerUser>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // 로그인 안 되어 있으면 호출 안 함
    if (widget.currentUser == null) return;
    setState(() {
      _usersFuture = _fetchVolunteerUsers(_selectedCategory);
    });
  }

  /// VolunteerCategory → volunteer_field 문자열 매핑
  String _volunteerFieldValue(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '동물';
      case VolunteerCategory.nursingHome:
        return '노인';        // 혹은 서버에서 요구하는 정확한 문자열
      case VolunteerCategory.environment:
        return '환경';
      case VolunteerCategory.education:
        return '교육';
      default:
        return '기타';
    }
  }

  /// volunteer-search API 호출해서 해당 필드의 사람 목록을 가져옴
  Future<List<VolunteerUser>> _fetchVolunteerUsers(
      VolunteerCategory category,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('로그인 토큰이 없습니다. 다시 로그인해 주세요.');
    }

    final volunteerField = _volunteerFieldValue(category);

    final resp = await http.post(
      Uri.parse('http://220.149.241.209:8000/api/volunteer-search/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'volunteer_field': volunteerField}),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        '봉사자 검색 실패 (status: ${resp.statusCode}): ${resp.body}',
      );
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! List) {
      throw Exception('예상과 다른 응답 형식입니다: ${resp.body}');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(VolunteerUser.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('봉사 파트너 찾기'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryChips(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<VolunteerUser>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('봉사 파트너를 불러오는 중 오류: ${snapshot.error}'),
                  );
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text('해당 분야에 등록된 봉사 파트너가 아직 없습니다.'),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          u.nickname.isNotEmpty
                              ? u.nickname.characters.first
                              : '?',
                        ),
                      ),
                      title: Text(u.nickname.isNotEmpty ? u.nickname : '이름 미등록'),
                      subtitle: Text(
                        [
                          u.mbti.isNotEmpty ? u.mbti : null,
                          u.location.isNotEmpty ? u.location : null,
                          u.volunteerField.isNotEmpty ? u.volunteerField : null,
                        ].whereType<String>().join(' · '),
                      ),
                      onTap: () {
                        // TODO: 해당 유저와 QnA 시작, 매칭 요청 등 연결
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

  Widget _buildCategoryChips() {
    final categories = VolunteerCategory.values;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final selected = c == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_categoryLabel(c)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = c;
                    _usersFuture = _fetchVolunteerUsers(_selectedCategory);
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
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
}