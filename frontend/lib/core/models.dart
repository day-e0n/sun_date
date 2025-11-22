import 'dart:convert';

enum Gender { male, female }

enum VolunteerCategory { animal, nursingHome, environment, education, other }

enum TimeSlot { morning, afternoon, evening }

class UserProfile {
  final String nickname;
  final String studentId;
  final int age;
  final Gender gender;
  final String mbti;
  final String region;
  final List<VolunteerCategory> preferredCategories;
  final List<TimeSlot> preferredTimeSlots;
  final String preferredRegion;

  UserProfile({
    required this.nickname,
    required this.studentId,
    required this.age,
    required this.gender,
    required this.mbti,
    required this.region,
    required this.preferredCategories,
    required this.preferredTimeSlots,
    required this.preferredRegion,
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'studentId': studentId,
        'age': age,
        'gender': gender.name,
        'mbti': mbti,
        'region': region,
        'preferredCategories': preferredCategories.map((e) => e.name).toList(),
        'preferredTimeSlots': preferredTimeSlots.map((e) => e.name).toList(),
        'preferredRegion': preferredRegion,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'],
        studentId: json['studentId'],
        age: json['age'],
        gender: Gender.values.byName(json['gender']),
        mbti: json['mbti'],
        region: json['region'],
        preferredCategories: (json['preferredCategories'] as List)
            .map((e) => VolunteerCategory.values.byName(e))
            .toList(),
        preferredTimeSlots: (json['preferredTimeSlots'] as List)
            .map((e) => TimeSlot.values.byName(e))
            .toList(),
        preferredRegion: json['preferredRegion'],
      );
}

// --- Deprecated Models (will be removed later) ---
class MatchSession {
  final String id;
  final String selfUserId;
  final String partnerUserId;

  MatchSession({
    required this.id,
    required this.selfUserId,
    required this.partnerUserId,
  });
}

enum MessageSender { self, partner }

class QnaMessage {
  final String id;
  final String matchId;
  final MessageSender sender;
  final String content;
  final DateTime createdAt;

  QnaMessage({
    required this.id,
    required this.matchId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });
}
// --- End of Deprecated Models ---

class VolunteerActivity {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final VolunteerCategory category;

  VolunteerActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.category,
  });
}

enum SentQuestionStatus { pending, answered, expired }

class SentQuestion {
  final String id;
  final String senderId; // 보낸 사람 (나)
  final String receiverId; // 받는 사람 (상대)
  final String receiverName; // 상대 닉네임 (UI 표시용)
  final List<String> questions; // 보낸 질문 3개
  final DateTime createdAt; // 보낸 시각
  SentQuestionStatus status; // 변경 가능해야 하므로 final 제거
  List<String>? answers; // 답변이 없을 수 있으므로 nullable, 변경 가능

  SentQuestion({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    required this.questions,
    required this.createdAt,
    required this.status,
    this.answers,
  });
}
