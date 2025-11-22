import 'package:flutter/material.dart';
import 'package:sundate/core/match_api.dart';
import 'package:sundate/core/models.dart';
import 'package:sundate/ui/tabs/incoming_qna_tab.dart';
import 'package:sundate/ui/tabs/outgoing_qna_tab.dart';

class QnaBoxTab extends StatefulWidget {
  final MatchApi api;
  final UserProfile me;

  const QnaBoxTab({super.key, required this.api, required this.me});

  @override
  State<QnaBoxTab> createState() => _QnaBoxTabState();
}

class _QnaBoxTabState extends State<QnaBoxTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('질문함'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '답변할 질문'),
            Tab(text: '보낸 질문'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IncomingQnaTab(api: widget.api, me: widget.me),
          OutgoingQnaTab(api: widget.api, me: widget.me),
        ],
      ),
    );
  }
}
