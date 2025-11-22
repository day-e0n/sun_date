// // lib/ui/matching/volunteer_match_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../core/match_api.dart';
// import '../../core/models.dart';
//
// class VolunteerMatchScreen extends StatefulWidget {
//   final MatchApi api;
//   final UserProfile? currentUser;
//   final MatchSession? currentMatch;
//
//   const VolunteerMatchScreen({
//     super.key,
//     required this.api,
//     this.currentUser,
//     this.currentMatch,
//   });
//
//   @override
//   State<VolunteerMatchScreen> createState() => _VolunteerMatchScreenState();
// }
//
// class _VolunteerMatchScreenState extends State<VolunteerMatchScreen> {
//   Future<VolunteerActivity>? _activityFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }
//
//   void _load() {
//     if (widget.currentUser == null || widget.currentMatch == null) return;
//     setState(() {
//       _activityFuture = widget.api.recommendVolunteer(
//         matchId: widget.currentMatch!.id,
//         userId: widget.currentUser!.studentId, // id -> studentId
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.currentUser == null) {
//       return const Center(child: Text('로그인이 필요합니다.'));
//     }
//     if (widget.currentMatch == null) {
//       return const Center(child: Text('진행 중인 매칭이 없습니다.'));
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('봉사 활동 추천'),
//       ),
//       body: FutureBuilder<VolunteerActivity>(
//         future: _activityFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('봉사 활동을 불러오는 중 오류: ${snapshot.error}'));
//           }
//           final activity = snapshot.data;
//           if (activity == null) {
//             return const Center(child: Text('추천된 봉사 활동이 없습니다.'));
//           }
//
//           final formattedDate = DateFormat('yyyy년 MM월 dd일 HH:mm').format(activity.dateTime);
//
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   activity.title,
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildInfoRow(Icons.calendar_today, formattedDate),
//                 const SizedBox(height: 8),
//                 _buildInfoRow(Icons.location_on, activity.location),
//                 const SizedBox(height: 8),
//                 _buildInfoRow(Icons.category, _categoryLabel(activity.category)),
//                 const Divider(height: 32),
//                 Text(activity.description),
//                 const Spacer(),
//                 FilledButton.icon(
//                   onPressed: () {
//                     // TODO: 채팅방 또는 외부 링크로 연결
//                   },
//                   icon: const Icon(Icons.arrow_forward),
//                   label: const Text('파트너와 함께 봉사하러 가기'),
//                   style: FilledButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 48),
//                   ),
//                 )
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.grey[600]),
//         const SizedBox(width: 8),
//         Text(text),
//       ],
//     );
//   }
//
//   static String _categoryLabel(VolunteerCategory c) {
//     switch (c) {
//       case VolunteerCategory.animal:
//         return '동물 돌봄';
//       case VolunteerCategory.nursingHome:
//         return '이웃 돌봄';
//       case VolunteerCategory.environment:
//         return '환경보호';
//       case VolunteerCategory.education:
//         return '교육·멘토링';
//       default:
//         return '기타';
//     }
//   }
// }



// lib/ui/matching/volunteer_match_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

class VolunteerMatchScreen extends StatefulWidget {
  final MatchApi api;
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
  Future<VolunteerActivity>? _activityFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.currentUser == null) return;

    setState(() {
      _activityFuture = _fetchVolunteerActivity();
    });
  }

  /// volunteer-search API 호출
  Future<VolunteerActivity> _fetchVolunteerActivity() async {
    // 1) 로그인 때 저장해둔 토큰 로드
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('로그인 토큰이 없습니다. 다시 로그인해 주세요.');
    }

    // 2) volunteer_field 결정
    //   - 백엔드 스펙: "동물", "환경", "노인" 등 텍스트
    //   - 여기서는 예시로 "동물" 고정
    const volunteerField = '동물';

    final resp = await http.post(
      Uri.parse('http://220.149.241.209:8000/api/volunteer-search/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'volunteer_field': volunteerField,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        '봉사 검색 실패 (status: ${resp.statusCode}): ${resp.body}',
      );
    }

    final decoded = jsonDecode(resp.body);

    // 백엔드 응답 형식에 따라 조정 필요
    // 예: [ { ...봉사활동1... }, { ... } ] 형태라고 가정하고 첫 번째만 사용
    if (decoded is List && decoded.isNotEmpty) {
      return VolunteerActivity.fromJson(
        decoded.first as Map<String, dynamic>,
      );
    } else if (decoded is Map<String, dynamic>) {
      // 단일 객체로 오는 경우
      return VolunteerActivity.fromJson(decoded);
    } else {
      throw Exception('봉사 검색 결과가 비어 있습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('봉사 활동 추천'),
      ),
      body: FutureBuilder<VolunteerActivity>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('봉사 활동을 불러오는 중 오류: ${snapshot.error}'),
            );
          }
          final activity = snapshot.data;
          if (activity == null) {
            return const Center(child: Text('추천된 봉사 활동이 없습니다.'));
          }

          final formattedDate =
          DateFormat('yyyy년 MM월 dd일 HH:mm').format(activity.dateTime);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.calendar_today, formattedDate),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, activity.location),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.category,
                  _categoryLabel(activity.category),
                ),
                const Divider(height: 32),
                Text(activity.description),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: 채팅방 혹은 상세 화면으로 이동
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('파트너와 함께 봉사하러 가기'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text),
      ],
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