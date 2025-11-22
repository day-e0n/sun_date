// lib/ui/tabs/discovery_tab.dart
import 'package:flutter/material.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';

class DiscoveryTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const DiscoveryTab({
    super.key,
    required this.api,
    required this.me,
  });

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  VolunteerCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = VolunteerCategory.animal; // 기본 카테고리
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryChips(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<UserProfile>>(
              future: widget.api.listCandidates(
                userId: widget.me.id,
                categoryFilter: _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '후보를 불러오는 중 오류가 발생했습니다: ${snapshot.error}',
                    ),
                  );
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text('현재 이 카테고리에 적합한 상대가 없습니다.'),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(u.nickname.substring(0, 1)),
                      ),
                      title: Text(u.nickname),
                      subtitle: Text(
                        '${u.mbti} · ${u.region} ',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        // TODO: 실제로는 u를 지정해서 매칭하는 API 필요
                        final session = await widget.api.requestMatch(
                          userId: widget.me.id,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${u.nickname}님과의 QnA를 위한 매칭(모의)이 생성되었습니다. '
                                  '(matchId: ${session.id})',
                            ),
                          ),
                        );

                        // TODO: 여기서 QnA 화면으로 Navigator.push(...)
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
                  setState(() => _selectedCategory = c);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _categoryLabel(VolunteerCategory c) {
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