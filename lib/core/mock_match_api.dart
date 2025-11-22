// core/mock_match_api.dart
import 'dart:async';
import 'match_api.dart';
import 'models.dart';

class MockMatchApi implements MatchApi {
  final Map<String, UserProfile> _users = {};
  final Map<String, MatchSession> _matches = {};
  final Map<String, List<QnaMessage>> _messagesByMatch = {};
  final Map<String, VolunteerActivity> _activityByMatch = {};

  // 매칭 후보 풀 (실제로는 DB 쿼리로 대체)
  final List<UserProfile> _candidatePool = [];

  int _userSeq = 0;
  int _matchSeq = 0;
  int _msgSeq = 0;
  int _activitySeq = 0;

  @override
  Future<UserProfile> createProfile({
    required String nickname,
    required String studentId,
    required int age,
    required Gender gender,
    required String mbti,
    required String region,
    required List<VolunteerCategory> preferredCategories,
    required List<TimeSlot> preferredTimeSlots,
    required String preferredRegion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final id = (++_userSeq).toString();
    final profile = UserProfile(
      id: id,
      nickname: nickname,
      studentId: studentId,
      age: age,
      gender: gender,
      mbti: mbti,
      region: region,
      preferredCategories: preferredCategories,
      preferredTimeSlots: preferredTimeSlots,
      preferredRegion: preferredRegion,
    );

    _users[id] = profile;
    _candidatePool.add(profile);
    return profile;
  }

  // ============================================================
  // 탭 1: 매칭 후보 리스트 조회
  // ============================================================
  @override
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _candidatePool.where((u) {
      if (u.id == userId) return false;
      if (categoryFilter == null) return true;
      return u.preferredCategories.contains(categoryFilter);
    }).toList();
  }

  // ============================================================
  // 탭 2/3: 내가 참여 중인 매칭 리스트
  // ============================================================
  @override
  Future<List<MatchSession>> listMyMatches({
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _matches.values.where((m) {
      return m.selfUserId == userId || m.partnerUserId == userId;
    }).toList();
  }

  // ============================================================
  // 자동 매칭 (임시 매칭 생성)
  // ============================================================
  @override
  Future<MatchSession> requestMatch({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // 임시: 자기 자신 제외한 임의 상대 선택
    final partner = _candidatePool.firstWhere(
          (u) => u.id != userId,
      orElse: () => _users.values.firstWhere((u) => u.id != userId,
          orElse: () => throw Exception('No partners')),
    );

    final matchId = (++_matchSeq).toString();
    final session = MatchSession(
      id: matchId,
      selfUserId: userId,
      partnerUserId: partner.id,
    );
    _matches[matchId] = session;
    // 테스트를 위해 파트너가 보낸 3개의 질문 데이터 추가
    _messagesByMatch[matchId] = [
      QnaMessage(
        id: '1',
        matchId: matchId,
        sender: MessageSender.partner,
        content: '가장 기억에 남는 봉사활동 경험은 무엇인가요?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      QnaMessage(
        id: '2',
        matchId: matchId,
        sender: MessageSender.partner,
        content: '주말에 주로 어떻게 시간을 보내시나요? 취미가 궁금해요!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      QnaMessage(
        id: '3',
        matchId: matchId,
        sender: MessageSender.partner,
        content: '만약 우리가 같이 봉사를 하게 된다면, 어떤 종류의 봉사를 해보고 싶으신가요?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
    return session;
  }

  // ============================================================
  // 채팅(QnA) 메시지
  // ============================================================
  @override
  Future<void> sendQuestion({
    required String matchId,
    required String fromUserId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  @override
  Future<void> sendAnswer({
    required String matchId,
    required String fromUserId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  void _addMessage(String matchId, String fromUserId, String content) {
    final msg = QnaMessage(
      id: (++_msgSeq).toString(),
      matchId: matchId,
      sender:
      fromUserId == _matches[matchId]!.selfUserId ? MessageSender.self : MessageSender.partner,
      content: content,
      createdAt: DateTime.now(),
    );
    _messagesByMatch[matchId]!.add(msg);
  }

  @override
  Future<List<QnaMessage>> getConversation({
    required String matchId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _messagesByMatch[matchId] ?? [];
    final sorted = [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // ============================================================
  // 매칭 종료 (수락 여부 기록)
  // ============================================================
  @override
  Future<void> finishMatch({
    required String matchId,
    required String userId,
    required bool accepted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // ============================================================
  // 봉사 추천
  // ============================================================
  @override
  Future<VolunteerActivity> recommendVolunteer({
    required String matchId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_activityByMatch.containsKey(matchId)) {
      return _activityByMatch[matchId]!;
    }

    final activity = VolunteerActivity(
      id: (++_activitySeq).toString(),
      title: '유기견 산책 봉사',
      description: '보호소 강아지 산책 및 환경 정리 봉사.',
      location: '경기도 용인시 ○○ 보호소',
      dateTime: DateTime(2025, 12, 1, 14, 0),
      category: VolunteerCategory.animal,
    );

    _activityByMatch[matchId] = activity;
    return activity;
  }
}