import 'package:sundate/core/models.dart';

abstract class MatchApi {
  // 인증
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
  });

  Future<UserProfile> login({
    required String studentId,
    required String password,
  });

  Future<UserProfile?> getUserProfile(String userId);

  // 매칭 및 질문
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  });

  Future<void> sendMatchRequest({
    required String fromUserId,
    required UserProfile toUser,
    required List<String> questions,
  });

  Future<List<SentQuestion>> listSentQuestions({required String userId});

  Future<List<SentQuestion>> listReceivedQuestions({required String userId});

  Future<void> submitAnswer({
    required String questionId,
    required List<String> answers,
  });


  // 기존 QnA (향후 위 구조와 통합하거나 재설계 필요)
  @Deprecated('Use sendMatchRequest instead')
  Future<MatchSession> requestMatch({required String userId});

  @Deprecated('Will be replaced by a new QnA model')
  Future<List<MatchSession>> listMyMatches({required String userId});

  @Deprecated('Will be replaced by a new QnA model')
  Future<void> sendQuestion({
    required String matchId,
    required String fromUserId,
    required String content,
  });

  @Deprecated('Will be replaced by a new QnA model')
  Future<void> sendAnswer({
    required String matchId,
    required String fromUserId,
    required String content,
  });

  @Deprecated('Will be replaced by a new QnA model')
  Future<List<QnaMessage>> getConversation({
    required String matchId,
  });

  @Deprecated('Will be replaced by a new QnA model')
  Future<void> finishMatch({
    required String matchId,
    required String userId,
    required bool accepted,
  });

  // 봉사활동
  Future<VolunteerActivity> recommendVolunteer({
    required String matchId,
    required String userId,
  });
}
