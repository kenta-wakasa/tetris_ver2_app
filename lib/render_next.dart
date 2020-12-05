import 'package:flutter/material.dart';
import 'mino.dart';

class RenderNext extends CustomPainter {
  RenderNext({
    @required this.nextMinoTypeList,
  });

  final _basicLength = 10.0;
  final _sideLength = 6;
  final _nextLenght = 6; // nextの表示個数
  final _xOffset = -2;
  final _yOffset = 4;
  List<MinoType> nextMinoTypeList = List.filled(6, MinoType.none);

  // 実際の描画処理を行うメソッド
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    /// draw outer frame
    for (var i = 0; i < _nextLenght; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          _basicLength * i * _sideLength,
          _basicLength * _sideLength,
          _basicLength * _sideLength,
        ),
        paint,
      );
    }

    /// draw next mino
    paint.style = PaintingStyle.fill;

    var _index = 0;
    for (final minoType in nextMinoTypeList) {
      final tmpMino = Mino.getMino(minoType: minoType);
      for (final point in tmpMino) {
        canvas.drawRect(
          Rect.fromLTWH(
              _basicLength * (_xOffset + point.x),
              _basicLength * (_yOffset + point.y + _index * _nextLenght),
              _basicLength,
              _basicLength),
          paint,
        );
      }
      _index++;
    }
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
