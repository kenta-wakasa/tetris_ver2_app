import 'package:flutter/material.dart';
import 'mino.dart';

class RenderNext extends CustomPainter {
  final double basis = 10;
  List<int> nextMinoList;
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
    for (int index = 0; index < 6; index++) {
      canvas.drawRect(
          Rect.fromLTWH(0, index * 6 * basis, 6 * basis, 6 * basis), paint);
    }

    paint.style = PaintingStyle.fill;

    nextMinoList.asMap().forEach((index, value) {
      if (-1 < value) {
        Mino.mino[value][0].forEach(
          (e) {
            canvas.drawRect(
                Rect.fromLTWH((3 + e[0]) * basis,
                    (4 + e[1] + index * 6) * basis, 1 * basis, 1 * basis),
                paint);
          },
        );
      }
    });
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
