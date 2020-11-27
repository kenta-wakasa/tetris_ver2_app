import 'dart:math';

import 'package:flutter/material.dart';
import 'mino.dart';

class RenderNext extends CustomPainter {
  final double _basicLength = 10;
  final int _sideLength = 6;
  final int _nextLenght = 6; // nextの表示個数
  final int _xOffset = -2;
  final int _yOffset = 4;
  List<Point> _minoList = [];
  List<int> nextMinoList = [];
  RenderNext({
    @required this.nextMinoList,
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
    for (final element in nextMinoList) {
      try {
        _minoList = Mino.getMino(minoType: MinoType.values[element]);
        for (final point in _minoList) {
          canvas.drawRect(
            Rect.fromLTWH(
                _basicLength * (_xOffset + point.x),
                _basicLength * (_yOffset + point.y + _index * _nextLenght),
                _basicLength,
                _basicLength),
            paint,
          );
        }
        // 登録されていないタイプのミノがきたら弾く
      } on RangeError catch (e) {
        // print('登録されていないMinoタイプです。');
      }
      _index++;
    }
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
