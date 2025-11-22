import 'package:flutter/material.dart';
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
    _loadActivities(); // 활동 데이터 로드
  }

  // 봉사활동 데이터 로드 (더미 데이터 직접 생성)
  Future<void> _loadActivities() async {
    debugPrint("🔄 봉사활동 데이터 로드 시작");
    
    try {
      // 약간의 지연으로 로딩 표시
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 더미 데이터 생성
      final List<VolunteerActivity> activities = [
        VolunteerActivity(
          id: 'v1',
          title: '유기동물 산책 및 놀이 보조',
          agencyName: '부산시 동물보호센터',
          category: '동물 돌봄',
          dateAndTime: '2025-11-25 ~ 2025-12-20, 10:00~13:00',
          days: '화·목',
          location: '부산광역시 북구',
          description: '유기동물의 산책을 돕고 놀이 활동을 보조하는 역할입니다.',
          requirements: ['반려동물 친화적 성향'],
        ),
        VolunteerActivity(
          id: 'v2',
          title: '고양이 보호실 청소 및 사회화 활동',
          agencyName: '대구 반려동물 복지센터',
          category: '동물 돌봄',
          dateAndTime: '2025-11-30 ~ 2026-01-15, 14:00~17:00',
          days: '수·금',
          location: '대구광역시 수성구',
          description: '보호 중인 고양이 사회화 및 환경 정리 활동입니다.',
          requirements: ['고양이 알레르기 없음'],
        ),
        VolunteerActivity(
          id: 'v3',
          title: '독거어르신 말벗 및 안부 확인',
          agencyName: '서울중앙복지센터',
          category: '이웃 돌봄',
          dateAndTime: '2025-11-25 ~ 2026-01-10, 10:00~13:00',
          days: '월·목',
          location: '서울특별시 중구',
          description: '독거 어르신 방문해 말벗 및 안전 확인.',
          requirements: ['기본 의사소통 가능자'],
        ),
        VolunteerActivity(
          id: 'v4',
          title: '치매 어르신 프로그램 보조',
          agencyName: '부산 서구 노인복지관',
          category: '이웃 돌봄',
          dateAndTime: '2025-12-01 ~ 2026-02-01, 13:00~17:00',
          days: '화·금',
          location: '부산광역시 서구',
          description: '치매 어르신 프로그램 보조 및 정서 지원.',
          requirements: ['치매 교육 이수자 우대'],
        ),
        VolunteerActivity(
          id: 'v5',
          title: '해변 쓰레기 수거 및 친환경 캠페인',
          agencyName: '부산 해양환경보호센터',
          category: '환경보호',
          dateAndTime: '2025-11-25 ~ 2026-01-10, 10:00~13:00',
          days: '토',
          location: '부산광역시 해운대구',
          description: '해변 쓰레기 수거 및 친환경 캠페인 지원.',
          requirements: ['야외 활동 가능자'],
        ),
        VolunteerActivity(
          id: 'v6',
          title: '도심 미세먼지 저감 거리정화',
          agencyName: '서울 녹색지구재단',
          category: '환경보호',
          dateAndTime: '2025-11-28 ~ 2026-02-01, 09:00~12:00',
          days: '수·금',
          location: '서울특별시 성동구',
          description: '거리 청소 및 식재 관리.',
          requirements: ['간단한 작업 가능'],
        ),
        VolunteerActivity(
          id: 'v7',
          title: '초등학생 기초학습 멘토링',
          agencyName: '서울동부지역아동센터',
          category: '교육·멘토링',
          dateAndTime: '2025-11-25 ~ 2026-02-25, 15:00~18:00',
          days: '월·수',
          location: '서울특별시 광진구',
          description: '초등 기초 학습 지도.',
          requirements: ['학습 지도 경험자 우대'],
        ),
        VolunteerActivity(
          id: 'v8',
          title: '중학생 영어회화 스터디 코치',
          agencyName: '부산 청소년배움터',
          category: '교육·멘토링',
          dateAndTime: '2025-11-30 ~ 2026-01-30, 16:00~18:00',
          days: '금',
          location: '부산광역시 진구',
          description: '중학생 영어 회화 연습 지도.',
          requirements: ['기본 회화 능력'],
        ),
        VolunteerActivity(
          id: 'v9',
          title: '지역 도서관 자료 정리 및 대출 보조',
          agencyName: '서울시 공공도서관 연합',
          category: '기타',
          dateAndTime: '2025-11-26 ~ 2026-01-15, 13:00~16:00',
          days: '화·금',
          location: '서울특별시 송파구',
          description: '도서 정리·대출 보조 및 이용자 안내.',
          requirements: ['정리 능력'],
        ),
        VolunteerActivity(
          id: 'v10',
          title: '문화행사 안내 및 운영 보조',
          agencyName: '부산 시민문화재단',
          category: '기타',
          dateAndTime: '2025-12-01 ~ 2026-02-01, 14:00~18:00',
          days: '토·일',
          location: '부산광역시 남구',
          description: '문화행사 안내·운영 지원.',
          requirements: ['대외활동 가능자'],
        ),
      ];

      debugPrint("✅ 총 ${activities.length}개 봉사활동 생성 완료");

      if (mounted) {
        setState(() {
          _allActivities = activities;
          _isLoading = false;
        });
        debugPrint("✅ UI 업데이트 완료 - 화면에 표시됨");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ 데이터 로드 에러: $e");
      debugPrint("스택: $stackTrace");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
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
