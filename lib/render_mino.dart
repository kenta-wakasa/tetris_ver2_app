import 'dart:math';

import 'package:flutter/material.dart';

class RenderMino extends CustomPainter {
  final double _basicLength = 20; // 1 グリッドの長さ
  final int _verticalLength = 20;
  final int _horizontalLength = 10;

  List<Point> currentMino = [];
  List<Point> futureMino = [];
  List<Point> fixedMino = [];

  RenderMino({
    @required this.currentMino,
    @required this.futureMino,
    @required this.fixedMino,
  });

  /// Mino を描画するための helper
  void _paintMino(Canvas canvas, Paint paint, List<Point> mino) {
    for (final Point point in mino) {
      canvas.drawRect(
        Rect.fromLTWH(
          _basicLength * point.x,
          _basicLength * point.y,
          _basicLength,
          _basicLength,
        ),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    /// フレームとグリッドの描画 ///

    /// draw outer frame
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _basicLength * _horizontalLength,
          _basicLength * _verticalLength),
      paint,
    );

    /// draw grid
    paint.strokeWidth = .5;

    // draw vertical grid
    for (int index = 0; index < _horizontalLength; index++) {
      canvas.drawLine(
        Offset(_basicLength * index, 0),
        Offset(_basicLength * index, _basicLength * _verticalLength),
        paint,
      );
    }

    // draw horizontal grid
    for (int index = 0; index < _verticalLength; index++) {
      canvas.drawLine(
        Offset(_basicLength * 0, _basicLength * index),
        Offset(_basicLength * _horizontalLength, _basicLength * index),
        paint,
      );
    }

    /// 3種類の Mino の描画 ///
    /// currentMino: 現在操作している Mino
    /// futureMino: currentMino の落下位置
    /// fixedMino: 固定された Mino を示す

    /// draw currentMino
    paint.style = PaintingStyle.fill;
    paint.color = Colors.redAccent;
    _paintMino(canvas, paint, currentMino);

    /// draw futureMino
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    _paintMino(canvas, paint, futureMino);

    /// draw fixedMino
    paint.style = PaintingStyle.fill;
    paint.color = Colors.brown;
    _paintMino(canvas, paint, fixedMino);
  }

  // 再描画のタイミングで呼ばれるメソッド
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
