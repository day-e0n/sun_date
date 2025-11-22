import 'models.dart';

abstract class MatchApi {
  // 인증
  Future<UserProfile> signUp({
    required String nickname,
    required String studentId, // 이 값은 재학증명서 처리 후 백엔드에서 생성될 수 있음
    required int age, // 이 값도 마찬가지
    required String password, // 비밀번호 추가
    required Gender gender,
    required String mbti,
    required String region,
    required List<VolunteerCategory> preferredCategories,
    required List<TimeSlot> preferredTimeSlots,
    required String preferredRegion,
    // required String proofOfEnrollment, // 재학증명서 파일 경로 또는 base64
  });

  Future<UserProfile> login({
    required String studentId,
    required String password,
  });

  @Deprecated('Use signUp instead')
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
  });

  // 매칭
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  });

  Future<List<MatchSession>> listMyMatches({
    required String userId,
  });

  Future<MatchSession> requestMatch({required String userId});

  // QnA
  Future<void> sendQuestion({
    required String matchId,
    required String fromUserId,
    required String content,
  });

  Future<void> sendAnswer({
    required String matchId,
    required String fromUserId,
    required String content,
  });

  Future<List<QnaMessage>> getConversation({
    required String matchId,
  });

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
