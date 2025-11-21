import 'package:flutter/material.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class VolunteerMatchScreen extends StatefulWidget {
  final MatchApi api;
  final UserProfile? currentUser;
  final MatchSession? currentMatch;

  const VolunteerMatchScreen({
    super.key,
    required this.api,
    required this.currentUser,
    required this.currentMatch,
  });

  @override
  State<VolunteerMatchScreen> createState() => _VolunteerMatchScreenState();
}

class _VolunteerMatchScreenState extends State<VolunteerMatchScreen> {
  VolunteerActivity? _activity;
  bool _loading = false;

  Future<void> _load() async {
    if (widget.currentUser == null || widget.currentMatch == null) return;
    setState(() => _loading = true);
    try {
      final act = await widget.api.recommendVolunteer(
        matchId: widget.currentMatch!.id,
        userId: widget.currentUser!.id,
      );
      if (mounted) setState(() => _activity = act);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish(bool ok) async {
    if (widget.currentMatch == null || widget.currentUser == null) return;
    await widget.api.finishMatch(
      matchId: widget.currentMatch!.id,
      userId: widget.currentUser!.id,
      accepted: ok,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '봉사 신청 완료(가상).' : '봉사 신청을 취소했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null || widget.currentMatch == null) {
      return const Center(child: Text('QnA 매칭을 먼저 완료해 주세요.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('봉사 매칭')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _activity == null
            ? Center(
          child: _loading
              ? const CircularProgressIndicator()
              : FilledButton(
            onPressed: _load,
            child: const Text('봉사 추천 받기'),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_activity!.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_activity!.description),
            const SizedBox(height: 8),
            Text('장소: ${_activity!.location}'),
            Text('날짜/시간: ${_activity!.dateTime}'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _finish(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _finish(true),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}