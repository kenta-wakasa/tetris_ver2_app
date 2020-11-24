import 'package:flutter/material.dart';

enum MinoType {
  I_Mino,
  O_Mino,
  T_Mino,
  J_Mino,
  L_Mino,
  S_Mino,
  Z_Mino,
}

enum MinoAngle {
  Rot_000,
  Rot_090,
  Rot_180,
  Rot_270,
}

class Point {
  int x = 0;
  int y = 0;
  Point({
    @required this.x,
    @required this.y,
  });
}

class Mino {
  /// typeとangle, x座標とy座標を渡しすと
  /// Minoの現在値を取得できる
  static Set<Point> getMino({
    @required MinoType minoType,
    @required MinoAngle minoAngle,
    int dx = 0,
    int dy = 0,
  }) {
    Set<Point> _mino = {};

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
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
              Point(x: 6, y: -1),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 4, y: 1),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 3, y: 0),
              Point(x: 4, y: 0),
              Point(x: 5, y: 0),
              Point(x: 6, y: 0),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 5, y: -1),
              Point(x: 5, y: -1),
              Point(x: 5, y: -1),
              Point(x: 5, y: -1),
            };
            break;
        }
        break;

      /// O_Mino
      case MinoType.O_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 4, y: -1),
              Point(x: 4, y: -2),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 4, y: -1),
              Point(x: 4, y: -2),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 4, y: -1),
              Point(x: 4, y: -2),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -1),
              Point(x: 4, y: -2),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
        }
        break;

      /// T_Mino
      case MinoType.T_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 4, y: -2),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: -0),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 4, y: 0),
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: -1),
            };
            break;
        }
        break;

      /// J_Mino
      case MinoType.J_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 3, y: -2),
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 3, y: 0),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: -2),
            };
            break;
        }
        break;

      /// L_Mino
      case MinoType.L_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 3, y: -2),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 3, y: 0),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: 0),
            };
            break;
        }
        break;

      /// S_Mino
      case MinoType.S_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 5, y: -2),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 3, y: -2),
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 3, y: 0),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
              Point(x: 4, y: 0),
            };
            break;
        }
        break;

      /// Z_Mino
      case MinoType.Z_Mino:
        switch (minoAngle) {
          case MinoAngle.Rot_000:
            _mino = {
              Point(x: 3, y: -2),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
              Point(x: 5, y: -1),
            };
            break;
          case MinoAngle.Rot_090:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 3, y: 0),
              Point(x: 4, y: -2),
              Point(x: 4, y: -1),
            };
            break;
          case MinoAngle.Rot_180:
            _mino = {
              Point(x: 3, y: -1),
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: 0),
            };
            break;
          case MinoAngle.Rot_270:
            _mino = {
              Point(x: 4, y: -1),
              Point(x: 4, y: 0),
              Point(x: 5, y: -2),
              Point(x: 5, y: -1),
            };
            break;
        }
        break;

      /// どれでもない場合はnullを返す
      default:
        return _mino;
        break;
    }

    /// オフセットを指定
    for (final Point element in _mino) {
      element.x += dx;
      element.y += dy;
    }
    return _mino;
  }

  static const List<Map<int, List<List<int>>>> mino = [
    // iMino
    {
      0: [
        [-2, -1],
        [-1, -1],
        [0, -1],
        [1, -1],
      ],
      90: [
        [-1, -2],
        [-1, -1],
        [-1, 0],
        [-1, 1],
      ],
      180: [
        [-2, 0],
        [-1, 0],
        [0, 0],
        [1, 0],
      ],
      270: [
        [0, -2],
        [0, -1],
        [0, 0],
        [0, 1],
      ],
    },
    // oMino
    {
      0: [
        [-1, -2],
        [0, -2],
        [-1, -1],
        [0, -1],
      ],
      90: [
        [-1, -2],
        [0, -2],
        [-1, -1],
        [0, -1],
      ],
      180: [
        [-1, -2],
        [0, -2],
        [-1, -1],
        [0, -1],
      ],
      270: [
        [-1, -2],
        [0, -2],
        [-1, -1],
        [0, -1],
      ],
    },
    // tMino
    {
      0: [
        [-1, -2],
        [-2, -1],
        [-1, -1],
        [0, -1],
      ],
      90: [
        [-1, -2],
        [-2, -1],
        [-1, -1],
        [-1, 0],
      ],
      180: [
        [-2, -1],
        [-1, -1],
        [0, -1],
        [-1, 0],
      ],
      270: [
        [-1, -2],
        [-1, -1],
        [0, -1],
        [-1, 0],
      ],
    },
    // jMino
    {
      0: [
        [-2, -2],
        [-2, -1],
        [-1, -1],
        [0, -1]
      ],
      90: [
        [-1, -2],
        [-1, -1],
        [-2, 0],
        [-1, 0]
      ],
      180: [
        [-2, -1],
        [-1, -1],
        [0, -1],
        [0, 0]
      ],
      270: [
        [-1, -2],
        [0, -2],
        [-1, -1],
        [-1, 0]
      ],
    },
    // lMino
    {
      0: [
        [0, -2],
        [-2, -1],
        [-1, -1],
        [0, -1]
      ],
      90: [
        [-2, -2],
        [-1, -2],
        [-1, -1],
        [-1, 0]
      ],
      180: [
        [-2, -1],
        [-1, -1],
        [0, -1],
        [-2, 0]
      ],
      270: [
        [-1, -2],
        [-1, -1],
        [-1, 0],
        [0, 0]
      ],
    },
    // sMino
    {
      0: [
        [-1, -2],
        [0, -2],
        [-2, -1],
        [-1, -1],
      ],
      90: [
        [-2, -2],
        [-2, -1],
        [-1, -1],
        [-1, 0],
      ],
      180: [
        [-1, -1],
        [0, -1],
        [-2, 0],
        [-1, 0],
      ],
      270: [
        [-1, -2],
        [-1, -1],
        [0, -1],
        [0, 0],
      ],
    },
    // zMino
    {
      0: [
        [-2, -2],
        [-1, -2],
        [-1, -1],
        [0, -1],
      ],
      90: [
        [-1, -2],
        [-2, -1],
        [-1, -1],
        [-2, 0],
      ],
      180: [
        [-2, -1],
        [-1, -1],
        [-1, 0],
        [-0, 0],
      ],
      270: [
        [0, -2],
        [-1, -1],
        [0, -1],
        [-1, 0],
      ],
    },
  ];
}
