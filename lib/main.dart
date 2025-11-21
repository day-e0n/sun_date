import 'package:flutter/material.dart';
import 'core/mock_match_api.dart';
import 'ui/app_shell.dart';

void main() {
  final api = MockMatchApi();
  runApp(SunDateApp(api: api));
}

class SunDateApp extends StatelessWidget {
  final MockMatchApi api;
  const SunDateApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '선데이트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: AppShell(api: api),
    );
  }
}