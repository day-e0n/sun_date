import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sundate/core/router.dart';
import 'package:sundate/core/mock_match_api.dart';

void main() {
  final api = MockMatchApi();
  final router = createRouter(api);

  runApp(SunDateApp(router: router));
}

class SunDateApp extends StatelessWidget {
  final GoRouter router;

  const SunDateApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '선데이트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        textTheme: GoogleFonts.notoSansKrTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
