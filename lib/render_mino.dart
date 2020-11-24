import 'package:flutter/material.dart';

class RenderMino extends CustomPainter {
  final double basis = 20;

  List<List<int>> currentMino = [];
  List<List<int>> futureMino = [];
  List<List<int>> fixedMino = [];

  RenderMino({
    @required this.currentMino,
    @required this.futureMino,
    @required this.fixedMino,
  });

  // 実際の描画処理を行うメソッド
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // draw fixedMino
    paint.color = Colors.brown;
    fixedMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(element[0] * basis, element[1] * basis, basis, basis),
            paint);
      },
    );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawRect(
        Rect.fromLTWH(-5.0 * basis, 0, 10 * basis, 20 * basis), paint);
    paint.strokeWidth = .5;

    // draw vertical grid
    for (int index = -4; index < 5; index++) {
      canvas.drawLine(
          Offset(index * basis, 0), Offset(index * basis, 20 * basis), paint);
    }
    // draw horizontal grid
    for (int index = 1; index < 20; index++) {
      canvas.drawLine(Offset(-5 * basis, index * basis),
          Offset(5 * basis, index * basis), paint);
    }

    // draw currentMino
    paint.style = PaintingStyle.fill;
    paint.color = Colors.redAccent;
    currentMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(element[0] * basis, element[1] * basis, basis, basis),
            paint);
      },
    );

    // draw futureMino
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    futureMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(element[0] * basis, element[1] * basis, basis, basis),
            paint);
      },
    );
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
