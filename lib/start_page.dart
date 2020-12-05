import 'package:flutter/material.dart';
import 'package:tetris_ver2_app/play_page.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    const _defPadding = 48.0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_defPadding),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: _size.width,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const FittedBox(
                    child: Text('TETRIS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ),
              SizedBox(
                width: _size.width,
                child: RaisedButton(
                  child: const Text(
                    'テトリスであそぶ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement<void, void>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
