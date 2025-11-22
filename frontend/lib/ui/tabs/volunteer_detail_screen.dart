import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/match_api.dart'; // API 사용을 위해 추가

class VolunteerDetailScreen extends StatefulWidget {
  final VolunteerActivity activity;final UserProfile currentUser;
  final MatchApi api; // 매칭된 유저 목록을 불러오기 위해 API 필요
  final Function(UserProfile partner) onAccept; // 선택된 파트너를 부모에게 전달

  const VolunteerDetailScreen({
    super.key,
    required this.activity,
    required this.currentUser,
    required this.api,
    required this.onAccept,
  });

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  List<UserProfile> _matchedPartners = [];
  bool _isLoadingPartners = false;

  @override
  void initState() {
    super.initState();
    _loadMatchedPartners();
  }

  // [핵심 로직] 이전에 QnA로 서로 수락한(매칭된) 상대방 목록 불러오기
  Future<void> _loadMatchedPartners() async {
    setState(() => _isLoadingPartners = true);

    try {
      // 실제로는 API에 'listMatchedUsers' 같은 메서드가 있어야 합니다.
      // 현재 MockMatchApi 구조상 listCandidates를 재활용하여 시뮬레이션합니다.
      // (실제 구현 시: widget.api.getMatchedUsers() 등으로 교체 필요)
      final candidates = await widget.api.listCandidates(userId: widget.currentUser.studentId);

      if (mounted) {
        setState(() {
          // 예시를 위해 상위 3명을 매칭된 상대로 가정합니다.
          _matchedPartners = candidates.take(3).toList();
          _isLoadingPartners = false;
        });
      }
    } catch (e) {
      debugPrint('파트너 로드 실패: $e');
      if (mounted) setState(() => _isLoadingPartners = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세 정보')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activity.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.agencyName,
              style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, widget.activity.date),
            _buildInfoRow(Icons.access_time, widget.activity.time),
            _buildInfoRow(Icons.calendar_month, widget.activity.days),
            _buildInfoRow(Icons.location_on_outlined, widget.activity.location),

            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '활동 내용',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.activity.description, style: const TextStyle(height: 1.5, color: Color(0xFF7986CB))),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              '요구사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 12),
            if (widget.activity.requirements.isNotEmpty)
              ...widget.activity.requirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.circle, size: 6, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        req,
                        style: TextStyle(color: Colors.blue.shade200, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ))
            else
              Text('별도 요구사항 없음', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  // 매칭된 파트너가 없으면 버튼 비활성화
                  onPressed: _matchedPartners.isEmpty
                      ? null
                      : () => _showPartnerSelectionDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('함께하기', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [New] 파트너 선택 다이얼로그
  void _showPartnerSelectionDialog(BuildContext context) {
    UserProfile? selectedPartner;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('누구와 함께 하시겠습니까?'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '매칭된 상대방(QnA 수락) 중 한 명을 선택해주세요.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingPartners)
                      const Center(child: CircularProgressIndicator())
                    else if (_matchedPartners.isEmpty)
                      const Text('매칭된 상대가 없습니다.')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _matchedPartners.length,
                          itemBuilder: (context, index) {
                            final partner = _matchedPartners[index];
                            return RadioListTile<UserProfile>(
                              title: Text(partner.nickname),
                              subtitle: Text('${partner.age}세 / ${partner.mbti}'),
                              value: partner,
                              groupValue: selectedPartner,
                              activeColor: Colors.pinkAccent,
                              onChanged: (value) {
                                setState(() {
                                  selectedPartner = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: selectedPartner == null
                      ? null
                      : () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(context); // 상세 화면 닫기
                    widget.onAccept(selectedPartner!); // 선택된 파트너 전달
                  },
                  child: const Text('신청 완료'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pinkAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF455A64), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
