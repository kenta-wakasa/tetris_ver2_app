import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tetris_ver2_app/start_page.dart';

void main() async {
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
        buttonTheme: ButtonThemeData(
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
