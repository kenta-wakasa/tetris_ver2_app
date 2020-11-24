import 'package:flutter/material.dart';

class RenderMino extends CustomPainter {
  final double _basicLength = 20;
  final int _verticalLength = 20;
  final int _horizontalLength = 10;

  List<List<int>> currentMino = [];
  List<List<int>> futureMino = [];
  List<List<int>> fixedMino = [];

  RenderMino({
    @required this.currentMino,
    @required this.futureMino,
    @required this.fixedMino,
  });

  /// 座標
  /// 左上が原点(0, 0)
  /// x軸は右方向に正
  /// y軸は下方向に正
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    /// draw fixedMino
    paint.color = Colors.brown;
    fixedMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(
              _basicLength * element[0],
              _basicLength * element[1],
              _basicLength,
              _basicLength,
            ),
            paint);
      },
    );

    /// draw outer frame
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          _basicLength * _horizontalLength,
          _basicLength * _verticalLength,
        ),
        paint);

    /// draw grid
    paint.strokeWidth = .5;

    // draw vertical grid
    for (int index = 0; index < 10; index++) {
      canvas.drawLine(
          Offset(
            _basicLength * index,
            0,
          ),
          Offset(
            _basicLength * index,
            _basicLength * _verticalLength,
          ),
          paint);
    }

    // draw horizontal grid
    for (int index = 0; index < 20; index++) {
      canvas.drawLine(
          Offset(
            _basicLength * 0,
            _basicLength * index,
          ),
          Offset(
            _basicLength * _horizontalLength,
            _basicLength * index,
          ),
          paint);
    }

    /// draw currentMino
    paint.style = PaintingStyle.fill;
    paint.color = Colors.redAccent;
    currentMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(
              _basicLength * element[0],
              _basicLength * element[1],
              _basicLength,
              _basicLength,
            ),
            paint);
      },
    );

    /// draw futureMino
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    futureMino.forEach(
      (element) {
        canvas.drawRect(
            Rect.fromLTWH(
              _basicLength * element[0],
              _basicLength * element[1],
              _basicLength,
              _basicLength,
            ),
            paint);
      },
    );
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
