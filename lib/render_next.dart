import 'package:flutter/material.dart';
import 'mino.dart';

class RenderNext extends CustomPainter {
  final double _basicLength = 10;
  final int _sideLength = 6;
  final int _nextLenght = 6; // nextの表示個数
  final int _xOffset = -2;
  final int _yOffset = 4;
  List<MinoType> minoTypeInNextList = List.filled(6, MinoType.None);
  RenderNext({
    @required this.minoTypeInNextList,
  });

  // 実際の描画処理を行うメソッド
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = Colors.brown;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;

    /// draw outer frame
    for (int index = 0; index < _nextLenght; index++) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          _basicLength * index * _sideLength,
          _basicLength * _sideLength,
          _basicLength * _sideLength,
        ),
        paint,
      );
    }

    /// draw next mino
    paint.style = PaintingStyle.fill;

    int _index = 0;
    for (final MinoType minoType in minoTypeInNextList) {
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
