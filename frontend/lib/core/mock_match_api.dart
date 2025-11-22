import 'dart:async';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';

// Mock-up of a user record in a database
class _UserRecord {
  final UserProfile profile;
  final String password;

  _UserRecord({required this.profile, required this.password});
}

class MockMatchApi implements MatchApi {
  // Data stores
  final Map<String, _UserRecord> _userRecords = {};
  final List<SentQuestion> _sentQuestions = [];
  int _qId = 0;

  // Deprecated data stores
  final Map<String, MatchSession> _matches = {};
  final Map<String, List<QnaMessage>> _messagesByMatch = {};
  final Map<String, VolunteerActivity> _activityByMatch = {};
  int _matchSeq = 0;
  int _msgSeq = 0;
  int _activitySeq = 0;

  // Constructor to initialize with some dummy data
  MockMatchApi() {
    // Add a few dummy users for testing
    _addDummyUser('00000000', 'test', '김단국', 25, Gender.female, 'ENTP');
    _addDummyUser('32221902', 'test', '박주희', 24, Gender.male, 'ISTJ');
    _addDummyUser('32222797', 'test', '위다연', 23, Gender.female, 'ESTJ');

    // Add a dummy incoming question for the master test account
    _sentQuestions.add(SentQuestion(
      id: 'q${++_qId}',
      senderId: '32221902',
      // 박주희
      receiverId: '00000000',
      // 김단국 (나)
      receiverName: '김단국',
      questions: ['주말에 주로 뭐하세요?', '취미는 무엇인가요?', '성격의 장단점을 알려주세요!'],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: SentQuestionStatus.pending,
    ));
  }

  void _addDummyUser(String studentId, String password, String nickname,
      int age, Gender gender, String mbti) {
    final profile = UserProfile(
      nickname: nickname,
      studentId: studentId,
      age: age,
      gender: gender,
      mbti: mbti,
      region: '서울',
      preferredCategories: [VolunteerCategory.animal],
    );
    _userRecords[studentId] = _UserRecord(profile: profile, password: password);
  }


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
    // Re-use the dummy user creation logic
    _addDummyUser(studentId, password, nickname, age, gender, mbti);
    return _userRecords[studentId]!.profile;
  }

  @override
  Future<UserProfile> login(
      {required String studentId, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final record = _userRecords[studentId];
    if (record == null || record.password != password) {
      throw Exception('사용자를 찾을 수 없거나 비밀번호가 틀렸습니다.');
    }
    return record.profile;
  }

  @override
  Future<List<UserProfile>> listCandidates(
      {required String userId, VolunteerCategory? categoryFilter}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _userRecords.values
        .map((r) => r.profile)
        .where((u) => u.studentId != userId)
        .toList();
  }

  @override
  Future<void> sendMatchRequest({
    required String fromUserId,
    required UserProfile toUser,
    required List<String> questions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newQuestion = SentQuestion(
      id: 'q${++_qId}',
      senderId: fromUserId,
      receiverId: toUser.studentId,
      receiverName: toUser.nickname,
      questions: questions,
      createdAt: DateTime.now(),
      status: SentQuestionStatus.pending,
    );
    _sentQuestions.insert(0, newQuestion); // Add to the top of the list
  }

  @override
  Future<List<SentQuestion>> listSentQuestions({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _sentQuestions.where((q) => q.senderId == userId).toList();
  }

  @override
  Future<List<SentQuestion>> listReceivedQuestions(
      {required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _sentQuestions.where((q) => q.receiverId == userId).toList();
  }

  @override
  Future<void> submitAnswer(
      {required String questionId, required List<String> answers}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final question = _sentQuestions.firstWhere((q) => q.id == questionId);
      question.answers = answers;
      question.status = SentQuestionStatus.answered;
    } catch (e) {
      throw Exception('Question not found');
    }
  }

  //--- Deprecated Methods ---

  @Deprecated('Use sendMatchRequest instead')
  @override
  Future<MatchSession> requestMatch({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final partner = _userRecords.values
        .map((r) => r.profile)
        .firstWhere((u) => u.studentId != userId,
        orElse: () => throw Exception('No partners'));
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
    return _matches.values.where((m) {
      return m.selfUserId == userId || m.partnerUserId == userId;
    }).toList();
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<void> sendQuestion(
      {required String matchId, required String fromUserId, required String content}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<void> sendAnswer(
      {required String matchId, required String fromUserId, required String content}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addMessage(matchId, fromUserId, content);
  }

  void _addMessage(String matchId, String fromUserId, String content) {
    final msg = QnaMessage(
      id: 'msg${'${++_msgSeq}'}',
      matchId: matchId,
      sender: fromUserId == _matches[matchId]!.selfUserId
          ? MessageSender.self
          : MessageSender.partner,
      content: content,
      createdAt: DateTime.now(),
    );
    _messagesByMatch[matchId]!.add(msg);
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<List<QnaMessage>> getConversation({required String matchId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _messagesByMatch[matchId] ?? [];
  }

  @Deprecated('Will be replaced by a new QnA model')
  @override
  Future<void> finishMatch(
      {required String matchId, required String userId, required bool accepted}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Do nothing
  }

  @override
  Future<VolunteerActivity> recommendVolunteer(
      {required String matchId, required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_activityByMatch.containsKey(matchId)) {
      return _activityByMatch[matchId]!;
    }
    final activity = VolunteerActivity(
      id: 'mock_1',
      category: '기타',
      title: '모의 봉사 활동',
      agencyName: '모의 기관',
      dateAndTime: '2025년 12월 1일, 오후 2:00', // dateAndTime으로 통합
      days: '월·수',                          // 필수 필드 추가
      location: '서울 어딘가',
      description: '테스트용 데이터',
      requirements: ['테스트 요구사항'],       // List<String>
    );

    _activityByMatch[matchId] = activity;
    return activity;
  }
}
