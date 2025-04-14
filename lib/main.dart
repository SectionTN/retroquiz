import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:retroquiz/screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
  SystemUiMode.edgeToEdge,
  overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  runApp(ProviderScope(child: const RetroQuiz()));
}

class RetroQuiz extends ConsumerWidget {
  const RetroQuiz({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'RetroQuiz',
      theme: flutterNesTheme().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFFFFFFF),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
