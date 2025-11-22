// lib/core/match_api.dart
import 'package:sundate/core/models.dart';

abstract class MatchApi {
  // 회원가입 (실제 서버에서는 /signup + /user-profile 로 나뉘지만,
  // Mock에서는 한 번에 UserProfile 생성용으로 사용)
  Future<UserProfile> signUp({
    required String nickname,
    required String studentId,
    required int age,
    required String password,
    required String sex, // "male" / "female" 같은 문자열
    required String mbti,
    required String region, // UserProfile.location 으로 매핑
    required List<VolunteerCategory> preferredCategories,
    required List<TimeSlot> preferredTimeSlots,
    required String preferredRegion,
  });

  // 로그인 (Mock에서는 studentId/password로 UserProfile 반환)
  Future<UserProfile> login({
    required String studentId,
    required String password,
  });

  // 프로필 조회
  Future<UserProfile?> getUserProfile(String userId);

  // 매칭 후보 리스트
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  });

  // 상대에게 질문 3개를 담은 매칭 요청 보내기
  Future<void> sendMatchRequest({
    required String fromUserId,
    required UserProfile toUser,
    required List<String> questions,
  });

  // 내가 보낸 질문 목록
  Future<List<SentQuestion>> listSentQuestions({required String userId});

  // 내가 받은 질문 목록
  Future<List<SentQuestion>> listReceivedQuestions({required String userId});

  // 특정 질문에 대한 답변 제출
  Future<void> submitAnswer({
    required String questionId,
    required List<String> answers,
  });

  // --- 이하 QnA 기반 이전 매칭 모델 (Deprecated) ---

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

  // 봉사활동 추천
  Future<VolunteerActivity> recommendVolunteer({
    required String matchId,
    required String userId,
  });
}