import 'package:flutter/material.dart';
import 'mino.dart';

class RenderHold extends CustomPainter {
  final double basis = 10;
  int indexHold = 0;
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6 * basis, 6 * basis), paint);

    // draw holdMino
    if (usedHold) {
      paint.color = Colors.grey;
    } else {
      paint.color = Colors.brown;
    }
    if (-1 < indexHold) {
      paint.style = PaintingStyle.fill;
      Mino.mino[indexHold][0].forEach((element) {
        canvas.drawRect(
            Rect.fromLTWH((3 + element[0]) * basis, (4 + element[1]) * basis,
                1 * basis, 1 * basis),
            paint);
      });
    }
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
