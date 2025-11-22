// lib/ui/onboarding/onboarding_flow_screen.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:random_nickname/random_nickname.dart';

import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';
import 'package:sundate/core/nickname_service.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final MatchApi api;

  const OnboardingFlowScreen({
    super.key,
    required this.api,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _pageController = PageController();
  int _step = 0;

  // 입력 컨트롤러
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  final _nicknameCtrl = TextEditingController();
  final _nicknameService = NicknameService();

  Gender _gender = Gender.female;

  String? _pickedFileName;
  String? _pickedFilePath;
  String? _authToken;

  final List<String> _mbtiOptions = const [
    'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
    'ISTP', 'ISFP', 'INFP', 'INTP',
    'ESTP', 'ESFP', 'ENFP', 'ENTP',
    'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
  ];
  String _selectedMbti = 'INFP';

  String _selectedProvince = '경기도';
  String _selectedCity = '용인시';

  bool _saving = false;

  // 지역 정보
  final Map<String, List<String>> _regions = {
    '서울특별시': [
      '강남구', '강동구', '강북구', '강서구',
      '관악구', '광진구', '구로구', '금천구',
      '노원구', '도봉구', '동대문구', '동작구',
      '마포구', '서대문구', '서초구', '성동구',
      '성북구', '송파구', '양천구', '영등포구',
      '용산구', '은평구', '종로구', '중구', '중랑구',
    ],
    '부산광역시': [
      '강서구', '금정구', '기장군', '남구',
      '동구', '동래구', '부산진구', '북구',
      '사상구', '사하구', '서구', '수영구',
      '연제구', '영도구', '중구', '해운대구',
    ],
    '대구광역시': [
      '남구', '달서구', '달성군', '동구',
      '북구', '서구', '수성구', '중구',
    ],
    '인천광역시': [
      '강화군', '계양구', '남동구', '동구',
      '미추홀구', '부평구', '서구', '연수구',
      '옹진군', '중구',
    ],
    '광주광역시': [
      '광산구', '남구', '동구', '북구', '서구',
    ],
    '대전광역시': [
      '대덕구', '동구', '서구', '유성구', '중구',
    ],
    '울산광역시': [
      '남구', '동구', '북구', '울주군', '중구',
    ],
    '세종특별자치시': [
      '세종시 전체(행정동 구분 없음)',
    ],
    '경기도': [
      '가평군', '고양시', '과천시', '광명시', '광주시',
      '구리시', '군포시', '김포시', '남양주시',
      '동두천시', '부천시', '성남시', '수원시',
      '시흥시', '안산시', '안성시', '안양시',
      '양주시', '양평군', '여주시', '연천군',
      '오산시', '용인시', '의왕시', '의정부시',
      '이천시', '파주시', '평택시', '포천시',
      '하남시', '화성시',
    ],
    '강원특별자치도': [
      '강릉시', '동해시', '삼척시', '속초시',
      '원주시', '춘천시', '태백시',
      '고성군', '양구군', '양양군', '영월군',
      '인제군', '정선군', '철원군', '평창군',
      '홍천군', '화천군', '횡성군',
    ],
    '충청북도': [
      '괴산군', '단양군', '보은군', '영동군',
      '옥천군', '음성군', '제천시',
      '증평군', '진천군', '청주시', '충주시',
    ],
    '충청남도': [
      '계룡시', '공주시', '논산시', '당진시',
      '보령시', '부여군', '서산시', '서천군',
      '아산시', '예산군', '천안시', '청양군',
      '태안군', '홍성군',
    ],
    '전북특별자치도': [
      '고창군', '군산시', '김제시', '남원시',
      '무주군', '부안군', '순창군', '완주군',
      '익산시', '임실군', '장수군', '전주시',
      '정읍시', '진안군',
    ],
    '전라남도': [
      '강진군', '고흥군', '곡성군', '광양시',
      '구례군', '나주시', '담양군', '목포시',
      '무안군', '보성군', '순천시', '신안군',
      '여수시', '영광군', '영암군', '완도군',
      '장성군', '장흥군', '진도군', '함평군',
      '해남군', '화순군',
    ],
    '경상북도': [
      '경산시', '경주시', '고령군', '구미시',
      '군위군', '김천시', '문경시', '봉화군',
      '상주시', '성주군', '안동시', '영덕군',
      '영양군', '영주시', '영천시', '예천군',
      '울릉군', '울진군', '의성군', '청도군',
      '청송군', '칠곡군', '포항시',
    ],
    '경상남도': [
      '거제시', '거창군', '고성군', '김해시',
      '남해군', '밀양시', '사천시', '산청군',
      '양산시', '의령군', '진주시', '창녕군',
      '창원시', '통영시', '하동군', '함안군',
      '함양군', '합천군',
    ],
    '제주특별자치도': [
      '제주시', '서귀포시',
    ],
  };

  // Step 6: 선호 카테고리
  final Set<VolunteerCategory> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedCity = _regions[_selectedProvince]?.first ?? '';
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
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFileName = result.files.single.name;
          _pickedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      _showError('파일을 선택하는 중 오류가 발생했습니다: $e');
    }
  }

  String _genderToString(Gender g) {
    switch (g) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
    }
  }

  Future<Map<String, dynamic>> _verifyDocument(
      String token, String filePath) async {
    final uri =
    Uri.parse('http://220.149.241.209:8000/api/verify-document/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        filePath,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
          '재학증명서 검증 실패 (status: ${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('예상과 다른 verify-document 응답 형식: ${response.body}');
    }
    return decoded;
  }

  Future<void> _next() async {
    // 단계별 검증
    switch (_step) {
      case 0:
        final studentId = _studentIdCtrl.text.trim();
        final password = _passwordCtrl.text.trim();
        final passwordConfirm = _passwordConfirmCtrl.text.trim();

        if (!RegExp(r'^\d{8}$').hasMatch(studentId)) {
          _showError('형식에 맞지 않습니다. 8자리 학번을 입력하세요.');
          return;
        }
        if (password.length < 6) {
          _showError('비밀번호는 6자리 이상이어야 합니다.');
          return;
        }
        if (password != passwordConfirm) {
          _showError('비밀번호가 일치하지 않습니다.');
          return;
        }
        break;
      case 1:
        if (_nicknameCtrl.text.trim().isEmpty) {
          _showError('닉네임을 입력해 주세요.');
          return;
        }
        break;
      case 2:
        if (_pickedFilePath == null) {
          _showError('재학증명서를 업로드해 주세요.');
          return;
        }
        break;
      default:
        break;
    }

    if (_step == 5) {
      await _submitProfile();
      return;
    }

    if (_step < 5) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
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
      if (_pickedFilePath == null) {
        _showError('재학증명서를 업로드해 주세요.');
        return;
      }

      // 1) 회원가입
      final studentId = int.parse(_studentIdCtrl.text.trim());

      final signupResp = await http.post(
        Uri.parse("http://220.149.241.209:8000/api/signup/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": studentId,
          "password": _passwordCtrl.text.trim(),
        }),
      );

      if (signupResp.statusCode != 200 && signupResp.statusCode != 201) {
        _showError("회원가입 실패: ${signupResp.body}");
        return;
      }

      final signupData = jsonDecode(signupResp.body);
      final token = signupData["token"] as String?;
      if (token == null || token.isEmpty) {
        _showError("회원가입 응답에 token이 없습니다.");
        return;
      }
      _authToken = token;

      // 2) 프로필 업데이트
      final profileResp = await http.put(
        Uri.parse("http://220.149.241.209:8000/api/user-profile/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nickname": _nicknameCtrl.text.trim(),
          "age": 20,
          "sex": _genderToString(_gender),
          "mbti": _selectedMbti,
          "location": "$_selectedProvince $_selectedCity",
        }),
      );

      if (profileResp.statusCode != 200) {
        _showError("프로필 업데이트 실패: ${profileResp.body}");
        return;
      }

      // 3) 재학증명서 검증
      final verifyResult = await _verifyDocument(token, _pickedFilePath!);
      final status = verifyResult['status'] as String? ?? 'failed';
      final message = verifyResult['message'] as String? ?? '';
      final discrepancies =
          (verifyResult['discrepancies'] as List?)?.cast<String>() ?? const [];

      if (status != 'success') {
        final reason = [
          message,
          if (discrepancies.isNotEmpty) '사유: ${discrepancies.join(", ")}',
        ].where((e) => e.isNotEmpty).join('\n');
        _showError('재학증명서 검증 실패\n$reason');
        return;
      }

      if (!mounted) return;
      context.go(
        '/login',
        extra: {'message': '회원가입 및 재학증명서 검증이 완료되었습니다. 로그인해 주세요.'},
      );
    } catch (e) {
      _showError('회원가입/검증 중 오류: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_step + 1) / 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
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
                _buildAuthStep(),
                _buildNicknameStep(),
                _buildProofOfEnrollmentStep(),
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
              child: Text(_step == 5 ? '가입 완료' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // ============= 각 스텝 UI =============

  Widget _buildAuthStep() {
    return _StepWrapper(
      title: '로그인 정보를 입력해 주세요.',
      subtitle: '선데이트 활동에 필요한 계정을 만들어요.',
      child: Column(
        children: [
          TextField(
            controller: _studentIdCtrl,
            decoration: const InputDecoration(
              labelText: '학번 (ID로 사용)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(labelText: '비밀번호'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordConfirmCtrl,
            decoration: const InputDecoration(labelText: '비밀번호 확인'),
            obscureText: true,
          ),
        ],
      ),
    );
  }

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
                onPressed: _initNickname,
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

  Widget _buildProofOfEnrollmentStep() {
    return _StepWrapper(
      title: '학생 신분 인증을 위해\n재학증명서를 업로드해 주세요.',
      subtitle: '재학증명서는 신원 확인 용도로만 사용되며, 확인 즉시 파기돼요.',
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('PDF 파일 선택'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          if (_pickedFileName != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _pickedFileName!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

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

  Widget _buildMbtiStep() {
    return _StepWrapper(
      title: 'MBTI를 알려주세요.',
      subtitle: '대화 스타일을 이해하는 데 도움이 돼요.',
      child: DropdownButtonFormField<String>(
        value: _selectedMbti,
        items: _mbtiOptions
            .map(
              (mbti) => DropdownMenuItem(
            value: mbti,
            child: Text(mbti),
          ),
        )
            .toList(),
        onChanged: (v) => setState(() => _selectedMbti = v ?? _selectedMbti),
        decoration: const InputDecoration(labelText: 'MBTI'),
      ),
    );
  }

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
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in provinces)
              ChoiceChip(label: Text(p), selected: p == _selectedProvince, onSelected: (_) => setState(() => _selectedProvince = p))
          ]),
          const SizedBox(height: 16),
          const Text('시 / 군'),
          DropdownButton<String>(
              value: _selectedCity,
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCity = v!))
        ]));
  }

  Widget _buildPreferredCategoriesStep() {
    return _StepWrapper(
        title: '어떤 종류의 봉사활동을 선호하시나요?',
        subtitle: '관심 있는 분야를 선택해 주세요. 여러 개 선택할 수 있어요.',
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: VolunteerCategory.values.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return ChoiceChip(
              label: Text(_categoryLabel(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
    );
  }

  String _categoryLabel(VolunteerCategory c) {
    switch (c) {
      case VolunteerCategory.animal:
        return '동물 돌봄';
      case VolunteerCategory.nursingHome:
        return '이웃 돌봄';
      case VolunteerCategory.environment:
        return '환경보호';
      case VolunteerCategory.education:
        return '교육·멘토링';
      default:
        return '기타';
    }
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}