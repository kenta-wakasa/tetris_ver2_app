import 'dart:math';

import 'package:flutter/material.dart';
import 'mino.dart';

class RenderHold extends CustomPainter {
  final double _basicLength = 10;
  final int _sideLength = 6;
  final int _xOffset = -2;
  final int _yOffset = 4;
  List<Point> _minoList = [];
  int indexHold = -1;
  bool usedHold = false;

  RenderHold({
    @required this.indexHold,
    @required this.usedHold,
  });

  // 実際の描画処理を行うメソッド
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = Colors.brown;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        _basicLength * _sideLength,
        _basicLength * _sideLength,
      ),
      paint,
    );

    /// draw hold Mino
    // 一度holdを使った場合は色を変える
    if (usedHold) {
      paint.color = Colors.grey;
    } else {
      paint.color = Colors.brown;
    }
    paint.style = PaintingStyle.fill;
    try {
      _minoList = Mino.getMino(
        minoType: MinoType.values[indexHold],
      );
    } on RangeError catch (e) {
      // print('登録されていないMinoタイプです。');
    }
    for (final element in _minoList) {
      canvas.drawRect(
        Rect.fromLTWH(
          _basicLength * (_xOffset + element.x),
          _basicLength * (_yOffset + element.y),
          _basicLength,
          _basicLength,
        ),
        paint,
      );
    }
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
