import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'start_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 縦方向に画面固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TETRIS',
      theme: ThemeData(
        primarySwatch: Colors.red,
        accentColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.amberAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        buttonTheme: const ButtonThemeData(
          textTheme: ButtonTextTheme.accent,
          shape: RoundedRectangleBorder(
            // Dialog以外のボタンの角に影響を与えることができる
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: StartPage(),
    );
  }
}
