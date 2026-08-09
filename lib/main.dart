Enterimport 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CryptoAiAnalyzerApp());
}

class CryptoAiAnalyzerApp extends StatelessWidget {
  const CryptoAiAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4BF),
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF161B22),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
