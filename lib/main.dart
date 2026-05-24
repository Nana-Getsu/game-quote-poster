import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'models/poster_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => PosterConfig(),
      child: const GameQuotePosterApp(),
    ),
  );
}

class GameQuotePosterApp extends StatelessWidget {
  const GameQuotePosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '游戏截图名句提取',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamilyFallback: const ['Microsoft YaHei', 'SimHei', 'SimSun'],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamilyFallback: const ['Microsoft YaHei', 'SimHei', 'SimSun'],
      ),
      home: const HomeScreen(),
    );
  }
}
