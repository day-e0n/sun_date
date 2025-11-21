enum Gender { male, female}

enum VolunteerCategory { animal, nursingHome, environment, education, other}

enum TimeSlot { morning, afternoon, evening }

class UserProfile {
  final String id;
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
    required this.id,
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
}

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