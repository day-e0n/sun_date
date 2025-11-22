import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // 파일 읽기용
import 'package:csv/csv.dart'; // CSV 파싱용
import '../../core/match_api.dart';
import '../../core/models.dart';
import 'volunteer_detail_screen.dart';
import 'application_history_tab.dart';

class AgencyTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile currentUser;

  const AgencyTab({
    super.key,
    required this.api,
    required this.currentUser,
  });

  @override
  State<AgencyTab> createState() => _AgencyTabState();
}

class _AgencyTabState extends State<AgencyTab> {
  // 카테고리 목록
  final List<String> _categories = [
    '전체',
    '동물 돌봄',
    '이웃 돌봄',
    '환경보호',
    '교육·멘토링',
    '기타'
  ];
  String _selectedCategory = '전체';

  // 신청 내역 리스트
  final List<AppliedActivity> _myApplications = [];

  // CSV 데이터를 담을 리스트 (초기엔 비어있음)
  List<VolunteerActivity> _allActivities = [];
  bool _isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadCsvData(); // CSV 로드 시작
  }

  // CSV 파일 로드 및 파싱 함수 (수정됨)
  Future<void> _loadCsvData() async {
    try {
      // 1. CSV 파일 읽기
      final rawData = await rootBundle.loadString('assets/volunteers.csv');

      // 2. CSV 파싱 (중요: eol 설정을 '\n'으로 강제하여 OS 호환성 확보)
      List<List<dynamic>> listData =
      const CsvToListConverter(eol: '\n').convert(rawData);

      // 만약 위 설정으로 파싱이 안돼서 행이 1개 이하라면, 기본 설정으로 재시도 (안전장치)
      if (listData.length <= 1) {
        listData = const CsvToListConverter().convert(rawData);
      }

      List<VolunteerActivity> activities = [];

      // 헤더(0번) 제외하고 1번부터 시작
      for (var i = 1; i < listData.length; i++) {
        final row = listData[i];

        // 데이터 유효성 검사: 컬럼이 8개여야 함
        if (row.length < 8) continue;

        try {
          activities.add(VolunteerActivity(
            id: 'csv_$i',
            title: row[0].toString(),
            agencyName: row[1].toString(),
            category: row[2].toString(),
            dateAndTime: row[3].toString(),
            days: row[4].toString(),
            location: row[5].toString(),
            description: row[6].toString(),
            // 요구사항: 쉼표로 구분된 문자열을 리스트로 변환
            requirements:
            row[7].toString().split(',').map((e) => e.trim()).toList(),
          ));
        } catch (e) {
          debugPrint("Error parsing row $i: $e");
        }
      }

      if (mounted) {
        setState(() {
          _allActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading CSV: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 카테고리별 색상
  Color _getCategoryColor(String category) {
    return Colors.pinkAccent.shade100.withOpacity(0.2);
  }

  // 필터링된 리스트 반환
  List<VolunteerActivity> get _filteredActivities {
    if (_selectedCategory == '전체') {
      return _allActivities;
    }
    return _allActivities
        .where((activity) => activity.category.contains(_selectedCategory))
        .toList();
  }

  void _handleApplication(VolunteerActivity activity) {
    setState(() {
      _myApplications.insert(
        0,
        AppliedActivity(activity: activity, appliedAt: DateTime.now()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('봉사활동'),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pinkAccent,
            tabs: [
              Tab(text: '봉사 목록'),
              Tab(text: '내 신청 내역'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // [Tab 1] 봉사 목록
            Column(
              children: [
                _buildCategoryFilter(), // 여기서 호출 중이므로 아래에 정의가 있어야 함
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredActivities.isEmpty
                      ? const Center(child: Text('해당하는 봉사활동이 없습니다.'))
                      : ListView.builder(
                    itemCount: _filteredActivities.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final activity = _filteredActivities[index];
                      return _buildActivityCard(context, activity);
                    },
                  ),
                ),
              ],
            ),
            // [Tab 2] 신청 내역
            ApplicationHistoryTab(myApplications: _myApplications),
          ],
        ),
      ),
    );
  }

  // [복구됨] 카테고리 필터 UI 함수
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                _selectedCategory = category;
              });
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.pinkAccent,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.pinkAccent : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }

  // 카드 UI
  Widget _buildActivityCard(BuildContext context, VolunteerActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VolunteerDetailScreen(
                activity: activity,
                currentUser: widget.currentUser,
                api: widget.api, // [추가] API 전달
                onAccept: (partner) {
                  // [변경] 선택된 파트너 정보를 받음
                  _handleApplication(activity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text('${partner.nickname}님에게 봉사 매칭 요청을 보냈습니다!')),
                  );
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 칩
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activity.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activity.title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                activity.agencyName,
                style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
              ),
              const SizedBox(height: 12),
              // 정보 행
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  // 날짜만 표시
                  Expanded(
                    flex: 2,
                    child: Text(
                      activity.date, // 헬퍼 getter 사용
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 1,
                    child: Text(
                      activity.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
