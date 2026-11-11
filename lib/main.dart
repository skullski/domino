import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_menu.dart';

void main() {
  runApp(const DominoApp());
}

class DominoApp extends StatelessWidget {
  const DominoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainMenu(),
    );
  }
}
// test
