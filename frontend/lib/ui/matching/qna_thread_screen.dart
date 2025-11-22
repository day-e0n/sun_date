import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';

// ... (말풍선 위젯 _ChatBubble은 이전과 동일)

class QnaThreadScreen extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;
  final SentQuestion question;

  const QnaThreadScreen({
    super.key,
    required this.api,
    required this.me,
    required this.question,
  });

  @override
  State<QnaThreadScreen> createState() => _QnaThreadScreenState();
}

class _QnaThreadScreenState extends State<QnaThreadScreen> {
  late final List<TextEditingController> _answerControllers;
  bool _isSubmitting = false;

  UserProfile? _opponentProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _answerControllers = List.generate(
      widget.question.questions.length,
      (index) => TextEditingController(),
    );
    _loadOpponentProfile();
  }

  Future<void> _loadOpponentProfile() async {
    final isMyQuestion = widget.question.senderId == widget.me.studentId;
    final opponentNickname = isMyQuestion ? widget.question.receiverName : widget.question.senderName;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://220.149.241.209:8000/api/users/$opponentNickname/questions/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        // For now, we'll create a partial UserProfile object.
        final profileResponse = await http.get(
          Uri.parse('http://220.149.241.209:8000/api/user-profile/'), // This should be a specific user profile endpoint
          headers: {
            'Authorization': 'Token $token',
          },
        );
        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(utf8.decode(profileResponse.bodyBytes));
          if (mounted) {
            setState(() {
              _opponentProfile = UserProfile.fromJson(profileData);
              _isLoadingProfile = false;
            });
          }
        } else {
          throw Exception('Failed to load opponent profile');
        }
      } else {
        throw Exception('Failed to load opponent questions');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final answers = List.generate(widget.question.questions.length, (index) {
        return {
          'question_owner_nickname': widget.question.senderName,
          'question_number': index + 1,
          'answer_text': _answerControllers[index].text,
        };
      });

      final response = await http.post(
        Uri.parse('http://220.149.241.209:8000/api/answer-question/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(answers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('답변이 성공적으로 전송되었습니다!')),
          );
          // Update the question status locally
          setState(() {
            widget.question.status = SentQuestionStatus.answered;
          });
          context.pop(); // Go back to the previous screen
        }
      } else {
        throw Exception('Failed to submit answers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyQuestion = widget.question.senderId == widget.me.studentId;
    final isMyTurnToAnswer =
        !isMyQuestion && widget.question.status == SentQuestionStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${isMyQuestion ? widget.question.receiverName : widget.question.senderName}님과의 대화'),
      ),
      body: Column(
        children: [
          if (_isLoadingProfile)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_opponentProfile != null)
            _buildProfileHeader(_opponentProfile!),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.question.questions.length,
              itemBuilder: (context, index) {
                // Basic chat bubble layout
                return Column(
                  children: [
                    // Question bubble
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ChatBubble(
                        message: widget.question.questions[index],
                        isMe: false,
                      ),
                    ),
                    // Answer bubble (if answered)
                    if (widget.question.status == SentQuestionStatus.answered &&
                        widget.question.answers != null &&
                        widget.question.answers!.length > index) 
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ChatBubble(
                          message: widget.question.answers![index],
                          isMe: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (isMyTurnToAnswer && !_isSubmitting)
            _buildAnswerInputArea(context),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader(UserProfile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, child: Icon(Icons.person, size: 28)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('${profile.age}세, ${profile.location}, ${profile.mbti}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.question.questions.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _answerControllers[index],
                decoration: InputDecoration(
                  hintText: '질문 ${index + 1}에 대한 답변...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50), // 버튼 높이 키우기
            ),
            child: const Text('답변 보내기', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// A basic chat bubble widget
class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
