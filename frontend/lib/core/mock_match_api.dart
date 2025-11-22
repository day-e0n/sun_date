// lib/core/mock_match_api.dart
import 'dart:async';

import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';

// 내부에서만 사용하는 유저 레코드
class _UserRecord {
  final UserProfile profile;
  final String password;
  final List<VolunteerCategory> preferredCategories;
  final List<TimeSlot> preferredTimeSlots;
  final String preferredRegion;

  _UserRecord({
    required this.profile,
    required this.password,
    required this.preferredCategories,
    required this.preferredTimeSlots,
    required this.preferredRegion,
  });
}

class MockMatchApi implements MatchApi {
  // 유저 DB
  final Map<String, _UserRecord> _userRecords = {};

  // QnA형 매칭 데이터
  final List<SentQuestion> _sentQuestions = [];
  int _qId = 0;

  // Deprecated QnA 매칭용
  final Map<String, MatchSession> _matches = {};
  final Map<String, List<QnaMessage>> _messagesByMatch = {};
  final Map<String, VolunteerActivity> _activityByMatch = {};
  int _matchSeq = 0;
  int _msgSeq = 0;
  int _activitySeq = 0;

  MockMatchApi() {
    // 더미 유저들
    _addDummyUser(
      studentId: '00000000',
      password: 'test',
      nickname: '김단국',
      age: 25,
      sex: 'female',
      mbti: 'ENTP',
      region: '서울',
      preferredCategories: [VolunteerCategory.animal],
      preferredTimeSlots: [TimeSlot.afternoon],
      preferredRegion: '서울',
    );
    _addDummyUser(
      studentId: '32221902',
      password: 'test',
      nickname: '박주희',
      age: 24,
      sex: 'male',
      mbti: 'ISTJ',
      region: '경기',
      preferredCategories: [VolunteerCategory.education],
      preferredTimeSlots: [TimeSlot.morning],
      preferredRegion: '경기',
    );
    _addDummyUser(
      studentId: '32222797',
      password: 'test',
      nickname: '위다연',
      age: 23,
      sex: 'female',
      mbti: 'ESTJ',
      region: '인천',
      preferredCategories: [VolunteerCategory.environment],
      preferredTimeSlots: [TimeSlot.evening],
      preferredRegion: '인천',
    );

    // master 계정(00000000)에게 들어온 예시 질문
    _sentQuestions.add(
      SentQuestion(
        id: 'q${++_qId}',
        senderId: '32221902',
        senderName: '박주희',
        receiverId: '00000000',
        receiverName: '김단국',
        questions: const [
          '주말에 주로 뭐하세요?',
          '취미는 무엇인가요?',
          '성격의 장단점을 알려주세요!',
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: SentQuestionStatus.pending,
      ),
    );
  }

  String _categoryToString(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '동물';
      case VolunteerCategory.nursingHome:
        return '이웃 돌봄';
      case VolunteerCategory.environment:
        return '환경';
      case VolunteerCategory.education:
        return '교육';
      case VolunteerCategory.other:
        return '기타';
    }
  }

  void _addDummyUser({
    required String studentId,
    required String password,
    required String nickname,
    required int age,
    required String sex,
    required String mbti,
    required String region,
    required List<VolunteerCategory> preferredCategories,
    required List<TimeSlot> preferredTimeSlots,
    required String preferredRegion,
  }) {
    final profile = UserProfile(
      studentId: studentId,
      nickname: nickname,
      age: age,
      sex: sex,
      mbti: mbti,
      location: region,
      volunteerField: preferredCategories.isNotEmpty
          ? _categoryToString(preferredCategories.first)
          : null,
      question1: null,
      question2: null,
      question3: null,
      selfAnswer1: null,
      selfAnswer2: null,
      selfAnswer3: null,
    );

    _userRecords[studentId] = _UserRecord(
      profile: profile,
      password: password,
      preferredCategories: preferredCategories,
      preferredTimeSlots: preferredTimeSlots,
      preferredRegion: preferredRegion,
    );
  }

  // ---------------------------------------------------------------------------
  // MatchApi 구현부
  // ---------------------------------------------------------------------------

  @override
  Future<UserProfile> signUp({
    required String nickname,
    required String studentId,
    required int age,
    required String password,
    required String sex,
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
      studentId: studentId,
      nickname: nickname,
      age: age,
      sex: sex,
      mbti: mbti,
      location: region,
      volunteerField: preferredCategories.isNotEmpty
          ? _categoryToString(preferredCategories.first)
          : null,
    );

    _userRecords[studentId] = _UserRecord(
      profile: profile,
      password: password,
      preferredCategories: preferredCategories,
      preferredTimeSlots: preferredTimeSlots,
      preferredRegion: preferredRegion,
    );

    return profile;
  }

  @override
  Future<UserProfile> login({
    required String studentId,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final record = _userRecords[studentId];
    if (record == null || record.password != password) {
      throw Exception('사용자를 찾을 수 없거나 비밀번호가 틀렸습니다.');
    }
    return record.profile;
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _userRecords[userId]?.profile;
  }

  @override
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final allOthers = _userRecords.entries
        .where((e) => e.key != userId)
        .toList();

    if (categoryFilter == null) {
      return allOthers.map((e) => e.value.profile).toList();
    }

    return allOthers
        .where((e) => e.value.preferredCategories.contains(categoryFilter))
        .map((e) => e.value.profile)
        .toList();
  }

  @override
  Future<void> sendMatchRequest({
    required String fromUserId,
    required UserProfile toUser,
    required List<String> questions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final senderRecord = _userRecords[fromUserId];
    if (senderRecord == null) {
      throw Exception('보낸 사용자를 찾을 수 없습니다.');
    }

    final newQuestion = SentQuestion(
      id: 'q${++_qId}',
      senderId: fromUserId,
      senderName: senderRecord.profile.nickname,
      receiverId: toUser.studentId,
      receiverName: toUser.nickname,
      questions: questions,
      createdAt: DateTime.now(),
      status: SentQuestionStatus.pending,
    );

    _sentQuestions.insert(0, newQuestion);
  }

  @override
  Future<List<SentQuestion>> listSentQuestions({
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _sentQuestions.where((q) => q.senderId == userId).toList();
  }

  @override
  Future<List<SentQuestion>> listReceivedQuestions({
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _sentQuestions.where((q) => q.receiverId == userId).toList();
  }

  @override
  Future<void> submitAnswer({
    required String questionId,
    required List<String> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final q = _sentQuestions.firstWhere((e) => e.id == questionId);
      q.answers = answers;
      q.status = SentQuestionStatus.answered;
    } catch (_) {
      throw Exception('해당 ID의 질문을 찾을 수 없습니다.');
    }
  }

  // ---------------------------------------------------------------------------
  // 아래는 이전 QnA 모델(Deprecated) 구현 - 일단 컴파일용 + 기존 코드 호환용
  // ---------------------------------------------------------------------------

  @Deprecated('Use sendMatchRequest instead')
  @override
  Future<MatchSession> requestMatch({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final partner = _userRecords.values
        .map((r) => r.profile)
        .firstWhere(
          (u) => u.studentId != userId,
      orElse: () => throw Exception('파트너가 없습니다.'),
    );

    final matchId = 'm${++_matchSeq}';
    final session = MatchSession(
      id: matchId,
      selfUserId: userId,
      partnerUserId: partner.studentId,
    );
    _matches[matchId] = session;
    _messagesByMatch[matchId] = [];
    return session;
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<List<MatchSession>> listMyMatches({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _matches.values
        .where((m) => m.selfUserId == userId || m.partnerUserId == userId)
        .toList();
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<void> sendQuestion({
    required String matchId,
    required String fromUserId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  @Deprecated('Will be replaced by a new QnA model')
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
    final match = _matches[matchId];
    if (match == null) return;

    final sender = (fromUserId == match.selfUserId)
        ? MessageSender.self
        : MessageSender.partner;

    final msg = QnaMessage(
      id: 'msg${++_msgSeq}',
      matchId: matchId,
      sender: sender,
      content: content,
      createdAt: DateTime.now(),
    );
    _messagesByMatch[matchId] ??= [];
    _messagesByMatch[matchId]!.add(msg);
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<List<QnaMessage>> getConversation({
    required String matchId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _messagesByMatch[matchId] ?? [];
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<void> finishMatch({
    required String matchId,
    required String userId,
    required bool accepted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Mock에서는 별것 안 함
  }

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
      id: 'mock_$matchId',
      category: '기타',
      title: '모의 봉사 활동',
      agencyName: '모의 기관',
      dateAndTime: '2025년 12월 1일, 오후 2:00',
      days: '월·수',
      location: '서울 어딘가',
      description: '테스트용 봉사 활동입니다.',
      requirements: const ['테스트 요구사항 A', '테스트 요구사항 B'],
    );

    _activityByMatch[matchId] = activity;
    return activity;
  }
}