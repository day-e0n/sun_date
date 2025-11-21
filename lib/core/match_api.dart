// core/match_api.dart
import 'models.dart';

abstract class MatchApi {
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

  // 탭 1: 매칭 후보 리스트
  Future<List<UserProfile>> listCandidates({
    required String userId,
    VolunteerCategory? categoryFilter,
  });

  // 탭 2/3: 내가 참여 중인 매칭 리스트
  Future<List<MatchSession>> listMyMatches({
    required String userId,
  });

  // 자동 매칭 요청
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

  // 매칭 종료
  Future<void> finishMatch({
    required String matchId,
    required String userId,
    required bool accepted,
  });

  // 봉사 추천
  Future<VolunteerActivity> recommendVolunteer({
    required String matchId,
    required String userId,
  });
}