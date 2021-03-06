import 'package:flutter/material.dart';
import 'mino.dart';

class RenderHold extends CustomPainter {
  RenderHold({
    @required this.holdMinoType,
    @required this.usedHold,
  });

  final _basicLength = 10.0;
  final _sideLength = 6;
  final _xOffset = -2;
  final _yOffset = 4;

  MinoType holdMinoType = MinoType.none;

  bool usedHold = false;

  // 実際の描画処理を行うメソッド
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
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

    final tmpMino = Mino.getMino(
      minoType: holdMinoType,
    );

    for (final point in tmpMino) {
      canvas.drawRect(
        Rect.fromLTWH(
          _basicLength * (_xOffset + point.x),
          _basicLength * (_yOffset + point.y),
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
