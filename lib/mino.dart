import 'dart:math';

import 'package:flutter/material.dart';

enum MinoType { None, I_Mino, O_Mino, T_Mino, J_Mino, L_Mino, S_Mino, Z_Mino }
enum MinoAngle { Rot_000, Rot_090, Rot_180, Rot_270 }

class Mino {
  /// typeとangle, x座標とy座標を渡すと
  /// Minoの現在値を取得できる
  static List<Point> getMino({
    @required MinoType minoType,
    MinoAngle minoAngle = MinoAngle.Rot_000,
    int dx = 0,
    int dy = 0,
  }) {
    List<Point> _mino = [];
    List<Point> _minoWithOffset = [];

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
      case MinoType.I_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -1), Point(4, -1), Point(5, -1), Point(6, -1)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(4, -2), Point(4, -1), Point(4, 0), Point(4, 1)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(3, 0), Point(4, 0), Point(5, 0), Point(6, 0)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(5, -2), Point(5, -1), Point(5, 0), Point(5, 1)];
            break;
        }
        break;

      /// O_Mino
      case MinoType.O_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(4, -1), Point(4, -2), Point(5, -1), Point(5, -2)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(4, -1), Point(4, -2), Point(5, -1), Point(5, -2)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(4, -1), Point(4, -2), Point(5, -1), Point(5, -2)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -1), Point(4, -2), Point(5, -1), Point(5, -2)];
            break;
        }
        break;

      /// T_Mino
      case MinoType.T_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -1), Point(4, -1), Point(4, -2), Point(5, -1)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(3, -1), Point(4, -2), Point(4, -1), Point(4, -0)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(4, 0), Point(3, -1), Point(4, -1), Point(5, -1)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -2), Point(4, -1), Point(4, 0), Point(5, -1)];
            break;
        }
        break;

      /// J_Mino
      case MinoType.J_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -2), Point(3, -1), Point(4, -1), Point(5, -1)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(3, 0), Point(4, -2), Point(4, -1), Point(4, 0)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(3, -1), Point(4, -1), Point(5, -1), Point(5, 0)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -2), Point(4, -1), Point(4, 0), Point(5, -2)];
            break;
        }
        break;

      /// L_Mino
      case MinoType.L_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -1), Point(4, -1), Point(5, -1), Point(5, -2)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(3, -2), Point(4, -2), Point(4, -1), Point(4, 0)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(3, -1), Point(3, 0), Point(4, -1), Point(5, -1)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -2), Point(4, -1), Point(4, 0), Point(5, 0)];
            break;
        }
        break;

      /// S_Mino
      case MinoType.S_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -1), Point(4, -2), Point(4, -1), Point(5, -2)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(3, -2), Point(3, -1), Point(4, -1), Point(4, 0)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(3, 0), Point(4, -1), Point(4, 0), Point(5, -1)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -2), Point(4, -1), Point(5, -1), Point(5, 0)];
            break;
        }
        break;

      /// Z_Mino
      case MinoType.Z_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = [Point(3, -2), Point(4, -2), Point(4, -1), Point(5, -1)];
            break;
          case MinoAngle.Rot_090:
            _mino = [Point(3, -1), Point(3, 0), Point(4, -2), Point(4, -1)];
            break;
          case MinoAngle.Rot_180:
            _mino = [Point(3, -1), Point(4, -1), Point(4, 0), Point(5, 0)];
            break;
          case MinoAngle.Rot_270:
            _mino = [Point(4, -1), Point(4, 0), Point(5, -2), Point(5, -1)];
            break;
        }
        break;

      /// どれでもない場合
      default:
        return _mino;
        break;
    }

    /// オフセットを指定
    for (final Point point in _mino) {
      _minoWithOffset.add(Point(point.x + dx, point.y + dy));
    }
    return _minoWithOffset;
  }
}
