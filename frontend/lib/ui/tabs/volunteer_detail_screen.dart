import 'package:flutter/material.dart';
import '../../core/models.dart';

class VolunteerDetailScreen extends StatelessWidget {
  final VolunteerActivity activity;
  final UserProfile currentUser;
  final VoidCallback onAccept;

  const VolunteerDetailScreen({
    super.key,
    required this.activity,
    required this.currentUser,
    required this.onAccept,
  });

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
              activity.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activity.agencyName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // [수정] CSV 데이터 필드에 맞춰 정보 표시 변경
            _buildInfoRow(Icons.calendar_today_outlined, activity.date), // 날짜
            _buildInfoRow(Icons.access_time, activity.time),             // 시간
            _buildInfoRow(Icons.calendar_month, activity.days),          // [추가] 활동 요일
            _buildInfoRow(Icons.location_on_outlined, activity.location),// 장소

            // currentParticipants는 CSV에 없으므로 제거하거나 임시로 숨김

            const SizedBox(height: 30),

            // 활동 내용 박스
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      height: 1.5,
                      color: Color(0xFF7986CB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 요구사항
            const Text(
              '요구사항',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            if (activity.requirements.isNotEmpty)
              ...activity.requirements.map((req) => Padding(
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
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
            else
              Text(
                '별도 요구사항 없음',
                style: TextStyle(color: Colors.grey.shade500),
              ),
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
                  child: const Text('거절', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent, // 메인 테마 색상
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('수락', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    // 텍스트가 비어있으면 보여주지 않음
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pinkAccent), // 아이콘 색상도 테마에 맞게
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF455A64),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신청 하시겠습니까?'),
        content: const Text('상대방에게 수락 의사를 전달합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog 닫기
              Navigator.pop(context); // Screen 닫기
              onAccept();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
