// lib/ui/tabs/profile_tab.dart
import 'package:flutter/material.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

class ProfileTab extends StatelessWidget {
  final MatchApi api;
  final UserProfile me;

  const ProfileTab({
    super.key,
    required this.api,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              child: Text(me.nickname.substring(0, 1)),
            ),
            title: Text(
              me.nickname,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${me.mbti ?? '-'} · ${me.region ?? '-'}'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            title: const Text('학번'),
            subtitle: Text(me.studentId ?? '-'),
          ),
          ListTile(
            title: const Text('나이'),
            subtitle: Text(me.age?.toString() ?? '-'),
          ),
          ListTile(
            title: const Text('성별'),
            subtitle: Text(_genderLabel(me.gender)),
          ),
          ListTile(
            title: const Text('선호 봉사 카테고리'),
            subtitle: Text(
              (me.preferredCategories ?? [])
                  .map(_categoryLabel)
                  .join(', ')
                  .ifEmpty('-'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              // TODO: 프로필 수정 화면으로 네비게이션
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 수정 화면은 추후 구현 예정입니다.')),
              );
            },
            child: const Text('프로필 수정'),
          ),
        ],
      ),
    );
  }

  static String _genderLabel(Gender? g) {
    switch (g) {
      case Gender.female:
        return '여성';
      case Gender.male:
        return '남성';
      default:
        return '-';
    }
  }

  static String _categoryLabel(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '유기동물';
      case VolunteerCategory.nursingHome:
        return '요양원';
      case VolunteerCategory.environment:
        return '환경·청소';
      case VolunteerCategory.education:
        return '교육·멘토링';
      default:
        return '기타';
    }
  }
}

// 작은 extension: 빈 리스트 처리용
extension _JoinIfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}