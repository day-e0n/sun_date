// lib/core/nickname_service.dart
import 'package:random_nickname/random_nickname.dart';

class NicknameService {
  /// 패키지를 사용해서 한국어 닉네임 생성
  String generateRandomNickname() {
    // 형용사(감정) + 동물 조합
    final base = randomNickname([korAdjectiveEmotion, korNounAnimal]);
    // 뒤에 숫자 두 자리 붙이고 싶으면:
    final number = (100 + DateTime.now().millisecond % 900).toString();
    return '$base$number'; // 예: 행복한 강아지742
  }
}