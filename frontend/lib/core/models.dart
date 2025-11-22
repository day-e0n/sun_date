// lib/core/models.dart
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

  /// 앱 내부에서 저장하는 형태(JSON)으로 내보내기
  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'studentId': studentId,
    'age': age,
    'gender': gender.name, // 'male' / 'female'
    'mbti': mbti,
    'region': region,
    'preferredCategories': preferredCategories.map((e) => e.name).toList(),
  };

  /// 서버 형식(user-profile 응답) + 앱 로컬 형식을 모두 처리하는 fromJson
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 1) studentId: 앱 로컬은 'studentId', 서버는 'student_id'
    final rawStudentId = json['studentId'] ?? json['student_id'];
    final studentId = rawStudentId?.toString() ?? '';

    // 2) nickname: null이면 빈 문자열
    final nickname = (json['nickname'] ?? '') as String;

    // 3) age: null/string/int 모두 수용
    final dynamic rawAge = json['age'];
    int age;
    if (rawAge is int) {
      age = rawAge;
    } else if (rawAge is String && rawAge.isNotEmpty) {
      age = int.tryParse(rawAge) ?? 0;
    } else {
      age = 0; // 기본값
    }

    // 4) gender: 앱 로컬은 'gender', 서버는 'sex'
    final rawGender = (json['gender'] ?? json['sex'] ?? 'female') as String;
    final gender = _genderFromString(rawGender);

    // 5) mbti: null이면 빈 문자열
    final mbti = (json['mbti'] ?? '') as String;

    // 6) region: 앱 로컬은 'region', 서버는 'location'
    final region = (json['region'] ?? json['location'] ?? '') as String;

    // 7) preferredCategories:
    //    - 앱 로컬: preferredCategories: ['animal', ...]
    //    - 서버: volunteer_field: "동물" / "환경보호" ...
    List<VolunteerCategory> preferredCategories = [];

    if (json['preferredCategories'] is List) {
      final list = json['preferredCategories'] as List;
      preferredCategories = list
          .where((e) => e != null)
          .map((e) => _categoryFromEnumName(e.toString()))
          .toList();
    } else if (json['volunteer_field'] is String) {
      final cat =
      _categoryFromServerString(json['volunteer_field'] as String);
      preferredCategories = [cat];
    }

    return UserProfile(
      nickname: nickname,
      studentId: studentId,
      age: age,
      gender: gender,
      mbti: mbti,
      region: region,
      preferredCategories: preferredCategories,
    );
  }

  // ---- 내부 헬퍼 ----

  static Gender _genderFromString(String s) {
    switch (s) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
      // 서버에서 "" / null 같은 값이 왔을 때 기본값
        return Gender.female;
    }
  }

  /// 앱 내부 enum 이름("animal", "nursingHome" ...)으로부터 매핑
  static VolunteerCategory _categoryFromEnumName(String name) {
    try {
      return VolunteerCategory.values.byName(name);
    } catch (_) {
      return VolunteerCategory.other;
    }
  }

  /// 서버 volunteer_field 문자열("동물", "환경보호" ...)으로부터 매핑
  static VolunteerCategory _categoryFromServerString(String s) {
    switch (s) {
      case '동물':
      case '동물 돌봄':
        return VolunteerCategory.animal;
      case '이웃 돌봄':
        return VolunteerCategory.nursingHome;
      case '환경보호':
        return VolunteerCategory.environment;
      case '교육·멘토링':
        return VolunteerCategory.education;
      default:
        return VolunteerCategory.other;
    }
  }
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
  final String category; // 봉사분야
  final String title; // 활동명
  final String agencyName; // 모집기관
  final String dateAndTime; // 봉사기간 및 시간 (CSV 컬럼 병합됨)
  final String days; // 활동요일 (CSV 추가)
  final String location; // 봉사장소
  // currentParticipants는 CSV에 없으므로 더미 데이터나 랜덤값 사용 권장
  final String description; // 활동내용
  final List<String> requirements; // 요구사항

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
  String get time =>
      dateAndTime.split(',').length > 1 ? dateAndTime.split(',')[1].trim() : '';
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
  SentQuestionStatus status; // 변경 가능
  List<String>? answers; // 답변이 없을 수 있으므로 nullable

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