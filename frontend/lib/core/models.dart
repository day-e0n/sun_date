import 'dart:convert';

enum VolunteerCategory { animal, nursingHome, environment, education, other }

enum TimeSlot { morning, afternoon, evening }

class UserProfile {
  final String studentId;
  final String nickname;
  final int age;
  final String sex;
  final String mbti;
  final String location;
  final String? volunteerField;
  final String? question1;
  final String? question2;
  final String? question3;
  final String? selfAnswer1;
  final String? selfAnswer2;
  final String? selfAnswer3;

  UserProfile({
    required this.studentId,
    required this.nickname,
    required this.age,
    required this.sex,
    required this.mbti,
    required this.location,
    this.volunteerField,
    this.question1,
    this.question2,
    this.question3,
    this.selfAnswer1,
    this.selfAnswer2,
    this.selfAnswer3,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        studentId: json['student_id'] ?? '',
        nickname: json['nickname'] ?? '',
        age: json['age'] ?? 0,
        sex: json['sex'] ?? 'unknown',
        mbti: json['mbti'] ?? '',
        location: json['location'] ?? '',
        volunteerField: json['volunteer_field'],
        question1: json['question1'],
        question2: json['question2'],
        question3: json['question3'],
        selfAnswer1: json['self_answer1'],
        selfAnswer2: json['self_answer2'],
        selfAnswer3: json['self_answer3'],
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'nickname': nickname,
        'age': age,
        'sex': sex,
        'mbti': mbti,
        'location': location,
        'volunteer_field': volunteerField,
        'question1': question1,
        'question2': question2,
        'question3': question3,
        'self_answer1': selfAnswer1,
        'self_answer2': selfAnswer2,
        'self_answer3': selfAnswer3,
      };
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

enum MatchStatus { waiting, matched, rejected }

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

enum SentQuestionStatus { pending, answered, expired, declined }

class SentQuestion {
  final String id;
  final String senderId;
  final String senderName; // 보낸 사람 닉네임 (UI 표시용)
  final String receiverId;
  final String receiverName;
  final List<String> questions;
  final DateTime createdAt;
  SentQuestionStatus status;
  List<String>? answers;

  SentQuestion({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.questions,
    required this.createdAt,
    required this.status,
    this.answers,
  });
}
