import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/models.dart';

class ApplicationHistoryTab extends StatefulWidget {
  final List<AppliedActivity> myApplications;

  const ApplicationHistoryTab({super.key, required this.myApplications});

  @override
  State<ApplicationHistoryTab> createState() => _ApplicationHistoryTabState();
}

class _ApplicationHistoryTabState extends State<ApplicationHistoryTab> {

  @override
  void initState() {
    super.initState();
    // [Simulation] 화면이 열릴 때 대기중인 항목들을 체크하여 매칭 완료 시뮬레이션
    _simulateMatchingProcess();
  }

  void _simulateMatchingProcess() {
    for (var app in widget.myApplications) {
      if (app.status == MatchStatus.waiting) {
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              app.status = MatchStatus.matched;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myApplications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('아직 신청한 봉사활동이 없습니다.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.myApplications.length,
      itemBuilder: (context, index) {
        final application = widget.myApplications[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        application.activity.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(application.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(application.activity.agencyName, style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),
                _buildStatusDescription(application.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(MatchStatus status) {
    Color color;
    String text;

    switch (status) {
      case MatchStatus.waiting:
        color = Colors.orange;
        text = '상대방 응답 대기중';
        break;
      case MatchStatus.matched:
        color = Colors.green;
        text = '매칭 완료 (전송됨)';
        break;
      case MatchStatus.rejected:
        color = Colors.red;
        text = '매칭 실패';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusDescription(MatchStatus status) {
    String desc;
    switch (status) {
      case MatchStatus.waiting:
        desc = '상대방이 수락할 때까지 기다리고 있습니다.';
        break;
      case MatchStatus.matched:
        desc = '축하합니다! 두 분 모두 수락하여 기관으로 정보가 전송되었습니다.';
        break;
      case MatchStatus.rejected:
        desc = '아쉽게도 매칭이 성사되지 않았습니다.';
        break;
    }
    return Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87));
  }
}
