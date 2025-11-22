import 'dart:async';
import 'match_api.dart';
import 'models.dart';

// Mock-up of a user record in a database
class _UserRecord {
  final UserProfile profile;
  final String password;

  _UserRecord({required this.profile, required this.password});
}

class MockMatchApi implements MatchApi {
  // 학번을 키로 사용하는 사용자 정보 및 비밀번호 저장소
  final Map<String, _UserRecord> _userRecords = {};
  final Map<String, MatchSession> _matches = {};
  final Map<String, List<QnaMessage>> _messagesByMatch = {};
  final Map<String, VolunteerActivity> _activityByMatch = {};

  int _matchSeq = 0;
  int _msgSeq = 0;
  int _activitySeq = 0;

  @override
  Future<UserProfile> signUp({
    required String nickname,
    required String studentId,
    required int age,
    required String password,
    required Gender gender,
    required String mbti,
    required String region,
    required List<VolunteerCategory> preferredCategories,
    required List<TimeSlot> preferredTimeSlots,
    required String preferredRegion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_userRecords.containsKey(studentId)) {
      throw Exception('이미 가입된 학번입니다.');
    }

    final profile = UserProfile(
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

    _userRecords[studentId] = _UserRecord(profile: profile, password: password);
    return profile;
  }

  @override
  Future<UserProfile> login(
      {required String studentId, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Master account for testing
    if (studentId == '00000000' && password == 'test') {
      return UserProfile(
        nickname: '테스트계정',
        studentId: '00000000',
        age: 25,
        gender: Gender.female,
        mbti: 'ENTP',
        region: '테스트시 테스트구',
        preferredCategories: [VolunteerCategory.animal, VolunteerCategory.education],
        preferredTimeSlots: [TimeSlot.afternoon],
        preferredRegion: '테스트도',
      );
    }

    final record = _userRecords[studentId];
    if (record == null || record.password != password) {
      throw Exception('사용자를 찾을 수 없거나 비밀번호가 틀렸습니다.');
    }
    return record.profile;
  }

  @Deprecated('Use signUp instead')
  @override
  Future<UserProfile> createProfile(
      {required String nickname,
      required String studentId,
      required int age,
      required Gender gender,
      required String mbti,
      required String region,
      required List<VolunteerCategory> preferredCategories,
      required List<TimeSlot> preferredTimeSlots,
      required String preferredRegion}) async {
    return signUp(
        nickname: nickname,
        studentId: studentId,
        age: age,
        password: 'temppassword', // 임시 비밀번호
        gender: gender,
        mbti: mbti,
        region: region,
        preferredCategories: preferredCategories,
        preferredTimeSlots: preferredTimeSlots,
        preferredRegion: preferredRegion);
  }

  @override
  Future<List<UserProfile>> listCandidates(
      {required String userId, VolunteerCategory? categoryFilter}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // userId is now studentId
    return _userRecords.values
        .map((r) => r.profile)
        .where((u) {
          if (u.studentId == userId) return false;
          if (categoryFilter == null) return true;
          return u.preferredCategories.contains(categoryFilter);
        })
        .toList();
  }

  @override
  Future<List<MatchSession>> listMyMatches({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // userId is now studentId
    return _matches.values.where((m) {
      return m.selfUserId == userId || m.partnerUserId == userId;
    }).toList();
  }

  @override
  Future<MatchSession> requestMatch({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final partner = _userRecords.values
        .map((r) => r.profile)
        .firstWhere((u) => u.studentId != userId, orElse: () => throw Exception('No partners'));

    final matchId = (++_matchSeq).toString();
    final session = MatchSession(
      id: matchId,
      selfUserId: userId, // This is the studentId of the current user
      partnerUserId: partner.studentId, // This is the studentId of the partner
    );
    _matches[matchId] = session;
    _messagesByMatch[matchId] = []; // 새 매칭에는 빈 대화 목록으로 시작
    return session;
  }

  @override
  Future<void> sendQuestion(
      {required String matchId,
      required String fromUserId,
      required String content}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  @override
  Future<void> sendAnswer(
      {required String matchId,
      required String fromUserId,
      required String content}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  void _addMessage(String matchId, String fromUserId, String content) {
    final msg = QnaMessage(
      id: (++_msgSeq).toString(),
      matchId: matchId,
      sender: fromUserId == _matches[matchId]!.selfUserId
          ? MessageSender.self
          : MessageSender.partner,
      content: content,
      createdAt: DateTime.now(),
    );
    _messagesByMatch[matchId]!.add(msg);
  }

  @override
  Future<List<QnaMessage>> getConversation({required String matchId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _messagesByMatch[matchId] ?? [];
    final sorted = [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Future<void> finishMatch(
      {required String matchId,
      required String userId,
      required bool accepted}) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<VolunteerActivity> recommendVolunteer(
      {required String matchId, required String userId}) async {
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
