// lib/ui/onboarding/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:random_nickname/random_nickname.dart';

import '../../core/match_api.dart';
import '../../core/models.dart';
import '../../core/nickname_service.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final MatchApi api;
  final void Function(UserProfile profile) onCompleted;

  const OnboardingFlowScreen({
    super.key,
    required this.api,
    required this.onCompleted,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _pageController = PageController();
  int _step = 0; // 0:닉네임 1:학번 2:나이 3:성별 4:MBTI 5:지역

  // 닉네임
  final _nicknameCtrl = TextEditingController();

  // 학번
  final _studentIdCtrl = TextEditingController();

  final _nicknameService = NicknameService();
  // 나이
  final List<int> _ageOptions = List<int>.generate(20, (i) => 18 + i);
  int _selectedAge = 22;

  // 성별
  Gender _gender = Gender.female;

  // MBTI
  final _mbtiCtrl = TextEditingController(text: 'INFP');

  // 지역: 광역/도 + 시/군
  final Map<String, List<String>> _regions = {
    '서울특별시': ['강남구', '관악구', '마포구', '송파구'],
    '경기도': ['용인시', '수원시', '성남시', '고양시'],
    '강원도': ['춘천시', '원주시', '강릉시'],
    '충청북도': ['청주시', '충주시'],
    '충청남도': ['천안시', '아산시'],
    '전라북도': ['전주시', '군산시'],
    '전라남도': ['여수시', '순천시'],
    '경상북도': ['포항시', '경주시'],
    '경상남도': ['창원시', '김해시'],
    '제주특별자치도': ['제주시', '서귀포시'],
  };

  String _selectedProvince = '경기도';
  String _selectedCity = '용인시';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = _regions[_selectedProvince]!.first;
    _initNickname();
  }

  Future<void> _initNickname() async {
    final nickname = _nicknameService.generateRandomNickname();
    setState(() {
      _nicknameCtrl.text = nickname;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameCtrl.dispose();
    _studentIdCtrl.dispose();
    _mbtiCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _next() async {
    // 단계별 최소 검증
    switch (_step) {
      case 0:
        if (_nicknameCtrl.text.trim().isEmpty) {
          _showError('닉네임을 입력해 주세요.');
          return;
        }
        break;
      case 1:
        if (_studentIdCtrl.text.trim().isEmpty) {
          _showError('학번을 입력해 주세요.');
          return;
        }
        break;
      case 4:
        if (_mbtiCtrl.text.trim().isEmpty) {
          _showError('MBTI를 입력해 주세요.');
          return;
        }
        break;
      default:
        break;
    }

    if (_step < 5) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    await _submitProfile();
  }

  void _prev() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submitProfile() async {
    setState(() => _saving = true);
    try {
      final profile = await widget.api.createProfile(
        nickname: _nicknameCtrl.text.trim(),
        studentId: _studentIdCtrl.text.trim(),
        age: _selectedAge,
        gender: _gender,
        mbti: _mbtiCtrl.text.trim(),
        region: '$_selectedProvince $_selectedCity',
        // 선호 봉사(지금은 최소값만, 나중에 별 단계 빼서 확장 가능)
        preferredCategories: const [VolunteerCategory.animal],
        preferredTimeSlots: const [TimeSlot.afternoon],
        preferredRegion: _selectedProvince,
      );
      if (!mounted) return;
      widget.onCompleted(profile);
    } catch (e) {
      _showError('프로필 생성 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('선데이트 온보딩'),
        leading: _step > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prev,
        )
            : null,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNicknameStep(),
                _buildStudentIdStep(),
                _buildAgeStep(),
                _buildGenderStep(),
                _buildMbtiStep(),
                _buildRegionStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving ? null : _next,
              child: Text(_step == 5 ? '완료' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // 0. 닉네임
  Widget _buildNicknameStep() {
    return _StepWrapper(
      title: '처음 오셨군요, 반가워요!\n닉네임을 만들어볼까요?',
      subtitle: '프로필에 표시되는 이름으로, 언제든 변경할 수 있어요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nicknameCtrl,
            decoration: InputDecoration(
              labelText: '닉네임',
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {

                  final nickname = _nicknameService.generateRandomNickname();
                  if (!mounted) return;
                  setState(() {
                    _nicknameCtrl.text = nickname;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '예: 하품하는강아지123, 돈많은까마귀456',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 1. 학번
  Widget _buildStudentIdStep() {
    return _StepWrapper(
      title: '학번을 알려주세요.',
      subtitle: '재학 여부 확인과 학교 기반 매칭에 사용돼요.',
      child: TextField(
        controller: _studentIdCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '학번'),
      ),
    );
  }

  // 2. 나이
  Widget _buildAgeStep() {
    return _StepWrapper(
      title: '나이를 알려주세요.',
      subtitle: '봉사 매칭을 위한 기본 정보로 사용돼요.',
      child: DropdownButtonFormField<int>(
        value: _selectedAge,
        items: _ageOptions
            .map((a) => DropdownMenuItem(
          value: a,
          child: Text('$a세'),
        ))
            .toList(),
        onChanged: (v) => setState(() => _selectedAge = v ?? _selectedAge),
        decoration: const InputDecoration(labelText: '나이'),
      ),
    );
  }

  // 3. 성별
  Widget _buildGenderStep() {
    return _StepWrapper(
      title: '성별을 선택해 주세요.',
      subtitle: '성별 정보는 상대에게 일부 공개될 수 있어요.',
      child: Column(
        children: [
          RadioListTile<Gender>(
            title: const Text('여성'),
            value: Gender.female,
            groupValue: _gender,
            onChanged: (g) => setState(() => _gender = g!),
          ),
          RadioListTile<Gender>(
            title: const Text('남성'),
            value: Gender.male,
            groupValue: _gender,
            onChanged: (g) => setState(() => _gender = g!),
          ),
        ],
      ),
    );
  }

  // 4. MBTI
  Widget _buildMbtiStep() {
    return _StepWrapper(
      title: 'MBTI를 알려주세요.',
      subtitle: '대화 스타일을 이해하는 데 도움이 돼요.',
      child: TextField(
        controller: _mbtiCtrl,
        decoration:
        const InputDecoration(labelText: 'MBTI (예: INFP)'),
      ),
    );
  }

  // 5. 지역
  Widget _buildRegionStep() {
    final provinces = _regions.keys.toList();
    final cities = _regions[_selectedProvince]!;

    if (!cities.contains(_selectedCity)) {
      _selectedCity = cities.first;
    }

    return _StepWrapper(
      title: '주로 활동하는 지역은 어디인가요?',
      subtitle: '선택한 지역의 봉사 파트너와 활동을 추천해 드려요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('광역시 / 도'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provinces.map((p) {
              final selected = p == _selectedProvince;
              return ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedProvince = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('시 / 군'),
          DropdownButton<String>(
            value: _selectedCity,
            items: cities
                .map(
                  (c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _selectedCity = v!),
          ),
        ],
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _StepWrapper({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}