import 'dart:math';

import 'package:flutter/material.dart';

enum MinoType { none, iMino, oMino, tMino, jMino, lMino, sMino, zMino }
enum MinoAngle { deg000, deg090, deg180, deg270 }

class Mino {
  /// typeとangle, x座標とy座標を渡すと
  /// Minoの現在値を取得できる
  static List<Point> getMino({
    @required MinoType minoType,
    MinoAngle minoAngle = MinoAngle.deg000,
    int dx = 0,
    int dy = 0,
  }) {
    var _mino = <Point>[];
    final _minoWithOffset = <Point>[];

    /// Mino の初期位置を定義する
    /// 図は I_Mino, Rot_000 の場合
    /// ==========================
    ///    0 1 2 3 4 5 6 7 8 9
    /// -2
    /// -1       * * * *
    ///  0
    ///  1
    ///  2
    ///  3
    ///  .
    ///  .
    ///  .
    /// 〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜

    switch (minoType) {

      /// I_Mino
      case MinoType.iMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -1),
              const Point(4, -1),
              const Point(5, -1),
              const Point(6, -1),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
              const Point(4, 1),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(3, 0),
              const Point(4, 0),
              const Point(5, 0),
              const Point(6, 0),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(5, -2),
              const Point(5, -1),
              const Point(5, 0),
              const Point(5, 1),
            ];
            break;
        }
        break;

      /// O_Mino
      case MinoType.oMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(4, -1),
              const Point(4, -2),
              const Point(5, -1),
              const Point(5, -2),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(4, -1),
              const Point(4, -2),
              const Point(5, -1),
              const Point(5, -2),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(4, -1),
              const Point(4, -2),
              const Point(5, -1),
              const Point(5, -2),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -1),
              const Point(4, -2),
              const Point(5, -1),
              const Point(5, -2),
            ];
            break;
        }
        break;

      /// T_Mino
      case MinoType.tMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -1),
              const Point(4, -1),
              const Point(4, -2),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(3, -1),
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, -0),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(4, 0),
              const Point(3, -1),
              const Point(4, -1),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, -1),
            ];
            break;
        }
        break;

      /// J_Mino
      case MinoType.jMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -2),
              const Point(3, -1),
              const Point(4, -1),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(3, 0),
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(3, -1),
              const Point(4, -1),
              const Point(5, -1),
              const Point(5, 0),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, -2),
            ];
            break;
        }
        break;

      /// L_Mino
      case MinoType.lMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -1),
              const Point(4, -1),
              const Point(5, -1),
              const Point(5, -2),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(3, -2),
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(3, -1),
              const Point(3, 0),
              const Point(4, -1),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -2),
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, 0),
            ];
            break;
        }
        break;

      /// S_Mino
      case MinoType.sMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -1),
              const Point(4, -2),
              const Point(4, -1),
              const Point(5, -2),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(3, -2),
              const Point(3, -1),
              const Point(4, -1),
              const Point(4, 0),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(3, 0),
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -2),
              const Point(4, -1),
              const Point(5, -1),
              const Point(5, 0),
            ];
            break;
        }
        break;

      /// Z_Mino
      case MinoType.zMino:
        switch (minoAngle) {
          case MinoAngle.deg000:
            _mino = [
              const Point(3, -2),
              const Point(4, -2),
              const Point(4, -1),
              const Point(5, -1),
            ];
            break;
          case MinoAngle.deg090:
            _mino = [
              const Point(3, -1),
              const Point(3, 0),
              const Point(4, -2),
              const Point(4, -1),
            ];
            break;
          case MinoAngle.deg180:
            _mino = [
              const Point(3, -1),
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, 0),
            ];
            break;
          case MinoAngle.deg270:
            _mino = [
              const Point(4, -1),
              const Point(4, 0),
              const Point(5, -2),
              const Point(5, -1),
            ];
            break;
        }
        break;

      case MinoType.none:
        return _mino;
        break;
    }

    /// オフセットを指定
    for (final point in _mino) {
      _minoWithOffset.add(Point(point.x + dx, point.y + dy));
    }
    return _minoWithOffset;
  }
}
