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

  UserProfile({
    required this.nickname,
    required this.studentId,
    required this.age,
    required this.gender,
    required this.mbti,
    required this.region,
    required this.preferredCategories,
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'studentId': studentId,
        'age': age,
        'gender': gender.name,
        'mbti': mbti,
        'region': region,
        'preferredCategories': preferredCategories.map((e) => e.name).toList(),

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
  final String category;          // 봉사분야
  final String title;             // 활동명
  final String agencyName;        // 모집기관
  final String dateAndTime;       // 봉사기간 및 시간 (CSV 컬럼 병합됨)
  final String days;              // 활동요일 (CSV 추가)
  final String location;          // 봉사장소
  // currentParticipants는 CSV에 없으므로 더미 데이터나 랜덤값 사용 권장
  final String description;       // 활동내용
  final List<String> requirements;// 요구사항

  VolunteerActivity({
    required this.id,
    required this.category,
    required this.title,
    required this.agencyName,
    required this.dateAndTime,
    required this.days,
    required this.location,
    required this.description,
    required this.requirements,
  });

  // CSV에서 날짜와 시간을 분리해서 보여주기 위한 헬퍼 Getter
  String get date => dateAndTime.split(',')[0].trim();
  String get time => dateAndTime.split(',').length > 1 ? dateAndTime.split(',')[1].trim() : '';
}

// [이동] AgencyTab에서 이동해옴
enum MatchStatus { waiting, matched, rejected }

// [이동] AgencyTab에서 이동해옴
class AppliedActivity {
  final VolunteerActivity activity;
  MatchStatus status;
  final DateTime appliedAt;

  AppliedActivity({
    required this.activity,
    this.status = MatchStatus.waiting,
    required this.appliedAt,
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
