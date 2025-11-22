import 'package:flutter/material.dart';
import '../../core/match_api.dart';
import '../../core/models.dart';

class MatchListTab extends StatelessWidget {
  final MatchApi api;
  final UserProfile currentUser;

  const MatchListTab({super.key, required this.api, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement match list UI
    return const Scaffold(
      body: Center(
        child: Text('Match List Tab'),
      ),
    );
  }
}
