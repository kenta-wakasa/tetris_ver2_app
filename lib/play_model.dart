import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'mino.dart';

class PlayModel extends ChangeNotifier {
  final int _verticalLength = 20;
  final int _horizontalLength = 10;
  Timer _countDownTimer;
  Timer _mainTimer;
  Timer _waitTimer;
  int count = 3;
  int xPos = 0;
  int yPos = 0;
  int yPosFuture = 0;
  int angle = 0;
  int index = -1;
  int indexMino = 0;
  int groundCount = 0;
  int indexHold = -1;
  int countDeletedLine = 0;
  bool usedHold = false;
  bool gameOver = false;
  bool wait = false;
  List<int> nextMinoList = [-1, -1, -1, -1, -1, -1];
  List<Point> currentMino = [];
  List<Point> futureMino = [];
  List<Point> fixedMino = [];

  int countFrameForDropMino = 0;
  int countFrameForLockMino = 0;
  bool isGrounded = false; // ミノがfixedミノと接地しているか
  bool minoIsMoving = false;
  bool mainLoopIsCancelled = false;
  List<int> minoOrderList = [];
  int minoOrderIndex = 0;
  final _numGenerateMino = 7000; // はじめに生成するミノの個数
  int currentMinoType = 0;

  /// 質問：disposeはどこで呼ばれるのでしょう？
  @override
  void dispose() {
    super.dispose();
    mainLoopIsCancelled = false;
    print('dispose!');
  }

  /// frameごとに処理を実行する
  Future<void> mainLoop(int fps) async {
    /// 初期化処理
    mainLoopIsCancelled = false;
    countFrameForDropMino = 0;
    yPos = 0;
    _generateMinoIndexList();
    await _countDown();
    _generateMino();

    /// メインループ
    final sw = Stopwatch()..start();
    int frame = 0; // フレーム番号
    while (!mainLoopIsCancelled) {
      frame++;

      /// テストために100フレーム目で停止させる。
      if (frame == 300) {
        mainLoopIsCancelled = true;
      }

      /// ミノが接地していないなら1秒後に落下させる
      if (!isGrounded) {
        countFrameForDropMino++;
        if (countFrameForDropMino % (fps * 1) == 0) {
          moveMino(0, 1);
          print('${countFrameForDropMino}drop');
        }
        countFrameForLockMino = 0;
      } else {
        /// 以下の条件を満たすときミノを固定する
        /// 1: ミノが接地している
        /// 2: 0.5秒間操作がない
        if (!minoIsMoving) {
          countFrameForLockMino++;
          if (countFrameForLockMino % (fps * 0.5).toInt() == 0) {
            lockMino();
          }
        } else {
          countFrameForLockMino = 0;
          minoIsMoving = false;
        }
        countFrameForDropMino = 0;
      }

      var next = 1000000 * frame ~/ fps;
      await Future.delayed(
        Duration(microseconds: next - sw.elapsedMicroseconds),
      );
      notifyListeners();
    }
  }

  void _generateMino() {
    currentMinoType = minoOrderList[minoOrderIndex % _numGenerateMino];
    currentMino = Mino.getMino(minoType: MinoType.values[currentMinoType]);
    minoOrderIndex++;
  }

  /// [_numGenerateMino]の数だけミノリスト生成する
  void _generateMinoIndexList() {
    while (minoOrderList.length < _numGenerateMino) {
      final seedMinoIndexList = [0, 1, 2, 3, 4, 5, 6];
      seedMinoIndexList.shuffle();
      minoOrderList.addAll(seedMinoIndexList);
    }
  }

  // 現在の位置から与えられた dx, dy だけ移動する
  void moveMino(int dx, int dy) {
    // TODO: 衝突判定

    // 移動先が衝突していなければ
    xPos += dx;
    yPos += dy;
    currentMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[0],
      dx: xPos,
      dy: yPos,
    );
  }

  void lockMino() {
    print('lockMino!');
  }

  Future<void> _countDown() async {
    final int fps = 1;
    count = 3;
    notifyListeners();
    while (count > -1) {
      await Future.delayed(Duration(seconds: 1));
      count--;
      notifyListeners();
    }
  }

  _startMain() {
    // if (_mainTimer == null || _mainTimer?.isActive == false) {
    //   _mainTimer = Timer.periodic(
    //     Duration(milliseconds: 1000),
    //     (Timer t) {
    //       if (!_verifyGround()) moveDown();
    //     },
    //   );
    // }
  }

  startWaitTime() {
    // _waitTimer = Timer.periodic(
    //   Duration(milliseconds: 500),
    //   (Timer t) {
    //     for (Point e in currentMino) {
    //       fixedMino.add(
    //         Point(e.x, e.y),
    //       );
    //     }
    //     _deleteMino();
    //     wait = false;
    //     _waitTimer?.cancel();
    //     _generateMino();
    //     if (_gameOver()) {
    //     } else {
    //       _startMain();
    //     }
    //   },
    // );
  }

  reset() {
    // yPos = 0;
    // xPos = 0;
    // index = -1;
    // indexHold = -1;
    // angle = 0;
    // groundCount = 0;
    // countDeletedLine = 0;
    // nextMinoList.clear();
    // fixedMino.clear();
    // currentMino.clear();
    // futureMino.clear();
    // _mainTimer?.cancel();
    // _waitTimer?.cancel();
    // wait = false;
    // usedHold = false;
    // gameOver = false;
    // notifyListeners();
  }

  moveLeft() {
    // xPos -= 1;
    // _updateCurrentMino();
    // if (_onCollisionEnter(currentMino)) {
    //   xPos += 1;
    //   _updateCurrentMino();
    // }
    // _verifyGround();
    // notifyListeners();
  }

  moveRight() {
    // xPos += 1;
    // _updateCurrentMino();
    // if (_onCollisionEnter(currentMino)) {
    //   xPos -= 1;
    //   _updateCurrentMino();
    // }
    // _verifyGround();
    // notifyListeners();
  }

  moveDown() {
    // // まず設置しているかを判定する。
    // yPos += 1;
    // _updateCurrentMino();
    // _verifyGround();
    // notifyListeners();
  }

  // 接地していたらwaitTimerを起動しtrueを返す
  bool _verifyGround() {
    // bool _ground = false;
    // _waitTimer?.cancel();
    // yPos++;
    // _updateCurrentMino();
    // // 設置していたら0.5秒間の待ち時間を起動する
    // if (_onCollisionEnter(currentMino)) {
    //   groundCount++;
    //   // 回転と移動操作があった場合は待ち時間をリセットする
    //   // ただし15回まで
    //   if (groundCount < 16) {
    //     _mainTimer?.cancel();
    //     wait = true;
    //     startWaitTime();
    //   } else {
    //     yPos--;
    //     _updateCurrentMino();
    //     for (List<int> e in currentMino) {
    //       fixedMino.add([e[0], e[1]]);
    //     }
    //     _deleteMino();
    //     wait = false;
    //     _waitTimer?.cancel();
    //     _generateMino();
    //     _gameOver();
    //     return true;
    //   }
    //   _ground = true;
    // } else {
    //   wait = false;
    //   _startMain();
    // }
    // yPos--;
    // _updateCurrentMino();
    // return _ground;
  }

  bool moveXY(int dx, int dy) {
    // xPos += dx;
    // yPos += dy;
    // _updateCurrentMino();
    // if (_onCollisionEnter(currentMino)) {
    //   xPos -= dx;
    //   yPos -= dy;
    //   _updateCurrentMino();
    //   notifyListeners();
    //   return false;
    // } else {
    //   _verifyGround();
    //   notifyListeners();
    //   return true;
    // }
  }

  rotateLeft() {
    //   final _temporaryAngle = angle;
    //   angle = (angle + (1 * 90)) % 360;
    //   _updateCurrentMino();
    //   // 回転したとき他の障害部に当たった場合
    //   // SRS(スーパーローテーションシステム)に従いミノを移動させる
    //   // 参考: https://tetrisch.github.io/main/srs.html
    //   if (_onCollisionEnter(currentMino)) {
    //     // iMinoかどうかで分岐
    //     if (indexMino == 0) {
    //       // angleで分岐
    //       switch (angle) {
    //         case 0:
    //           if (moveXY(2, 0)) return;
    //           if (moveXY(-1, 0)) return 0;
    //           if (moveXY(2, -1)) return 0;
    //           if (moveXY(-1, 2)) return 0;
    //           break;
    //         case 90:
    //           if (moveXY(-1, 0)) return 0;
    //           if (moveXY(2, 0)) return 0;
    //           if (moveXY(-1, -2)) return 0;
    //           if (moveXY(2, 1)) return 0;
    //           break;
    //         case 180:
    //           if (moveXY(1, 0)) return 0;
    //           if (moveXY(-2, 0)) return 0;
    //           if (moveXY(-2, 1)) return 0;
    //           if (moveXY(1, -2)) return 0;
    //           break;
    //         case 270:
    //           if (moveXY(1, 0)) return 0;
    //           if (moveXY(-2, 0)) return 0;
    //           if (moveXY(1, 2)) return 0;
    //           if (moveXY(-2, -1)) return 0;
    //           break;
    //       }
    //     } else {
    //       // angleで分岐
    //       switch (angle) {
    //         case 0:
    //           if (moveXY(1, 0)) return;
    //           if (moveXY(1, 1)) return 0;
    //           if (moveXY(0, -2)) return 0;
    //           if (moveXY(1, -2)) return 0;
    //           break;
    //         case 90:
    //           if (moveXY(1, 0)) return 0;
    //           if (moveXY(1, -1)) return 0;
    //           if (moveXY(0, 2)) return 0;
    //           if (moveXY(1, 2)) return 0;
    //           break;
    //         case 180:
    //           if (moveXY(-1, 0)) return 0;
    //           if (moveXY(-1, 1)) return 0;
    //           if (moveXY(0, -2)) return 0;
    //           if (moveXY(-1, -2)) return 0;
    //           break;
    //         case 270:
    //           if (moveXY(-1, 0)) return 0;
    //           if (moveXY(-1, -1)) return 0;
    //           if (moveXY(0, 2)) return 0;
    //           if (moveXY(-1, 2)) return 0;
    //           break;
    //       }
    //     }
    //     // どこにも動かせなかった場合角度を戻す
    //     angle = _temporaryAngle;
    //     _updateCurrentMino();
    //     _verifyGround();
    //     notifyListeners();
    //   } else {
    //     _verifyGround();
    //     notifyListeners();
    //   }
  }

  rotateRight() {
    // final _temporaryAngle = angle;
    // angle = (angle + (3 * 90)) % 360;
    // _updateCurrentMino();
    // // 回転したとき他の障害部に当たった場合
    // // SRS(スーパーローテーションシステム)に従いミノを移動させる
    // // 参考: https://tetrisch.github.io/main/srs.html
    // if (_onCollisionEnter(currentMino)) {
    //   // iMinoかどうかで分岐
    //   if (indexMino == 0) {
    //     // angleで分岐
    //     switch (angle) {
    //       case 0:
    //         if (moveXY(-2, 0)) return 0;
    //         if (moveXY(1, 0)) return 0;
    //         if (moveXY(1, 2)) return 0;
    //         if (moveXY(-2, -1)) return 0;
    //         break;
    //       case 90:
    //         if (moveXY(2, 0)) return 0;
    //         if (moveXY(-1, 0)) return 0;
    //         if (moveXY(2, -1)) return 0;
    //         if (moveXY(-1, 2)) return 0;
    //         break;
    //       case 180:
    //         if (moveXY(-1, 0)) return 0;
    //         if (moveXY(2, 0)) return 0;
    //         if (moveXY(-1, -2)) return 0;
    //         if (moveXY(2, -1)) return 0;
    //         break;
    //       case 270:
    //         if (moveXY(2, 0)) return 0;
    //         if (moveXY(-1, 0)) return 0;
    //         if (moveXY(2, 1)) return 0;
    //         if (moveXY(1, -2)) return 0;
    //         break;
    //     }
    //   } else {
    //     // angleで分岐
    //     switch (angle) {
    //       case 0:
    //         if (moveXY(-1, 0)) return 0;
    //         if (moveXY(-1, 1)) return 0;
    //         if (moveXY(0, -2)) return 0;
    //         if (moveXY(-1, -2)) return 0;
    //         break;
    //       case 90:
    //         if (moveXY(1, 0)) return 0;
    //         if (moveXY(1, -1)) return 0;
    //         if (moveXY(0, 2)) return 0;
    //         if (moveXY(1, 2)) return 0;
    //         break;
    //       case 180:
    //         if (moveXY(1, 0)) return 0;
    //         if (moveXY(1, 1)) return 0;
    //         if (moveXY(0, -2)) return 0;
    //         if (moveXY(1, -2)) return 0;
    //         break;
    //       case 270:
    //         if (moveXY(-1, 0)) return 0;
    //         if (moveXY(-1, -1)) return 0;
    //         if (moveXY(0, 2)) return 0;
    //         if (moveXY(-1, 2)) return 0;
    //         break;
    //     }
    //   }
    //   // どこにも動かせなかった場合角度を戻す
    //   angle = _temporaryAngle;
    //   _updateCurrentMino();
    //   _verifyGround();
    //   notifyListeners();
    // } else {
    //   _verifyGround();
    //   notifyListeners();
    // }
  }

  hardDrop() {
    // for (List<int> e in futureMino) {
    //   fixedMino.add([e[0], e[1]]);
    // }
    // _generateMino();
    // _deleteMino();
    // _updateCurrentMino();
    // wait = false;
    // _waitTimer?.cancel();
    // _startMain();
    // _gameOver();
    // notifyListeners();
  }

  holdMino() {
    // if (usedHold) {
    // } else {
    //   int _indexMino;
    //   _indexMino = indexMino;
    //   if (-1 < indexHold) {
    //     indexMino = indexHold;
    //     indexHold = _indexMino;
    //     yPos = 0;
    //     xPos = 0;
    //     angle = 0;
    //     _updateCurrentMino();
    //     notifyListeners();
    //   } else {
    //     indexHold = _indexMino;
    //     _generateMino();
    //   }
    //   usedHold = true;
    // }
  }

// game over 判定
  bool _gameOver() {
    // if (fixedMino.where((element) => element[1] == -1).isNotEmpty) {
    //   _mainTimer?.cancel();
    //   _waitTimer?.cancel();
    //   gameOver = true;
    // }
    // return gameOver;
  }

// predict drop position
  _predictDropPos() {
    // if (futureMino.isEmpty) {
    //   futureMino = [
    //     [0, 0],
    //     [0, 0],
    //     [0, 0],
    //     [0, 0],
    //   ];
    // }
    // for (yPosFuture = yPos; yPosFuture < 21; yPosFuture++) {
    //   Mino.mino[indexMino][angle].asMap().forEach(
    //     (index, value) {
    //       futureMino[index][0] = value[0] + xPos;
    //       futureMino[index][1] = value[1] + yPosFuture;
    //     },
    //   );
    //   // 衝突が判定されたらひとつ手前を描画してやめる
    //   if (_onCollisionEnter(futureMino)) {
    //     futureMino.forEach((element) {
    //       element[1]--;
    //     });
    //     notifyListeners();
    //     return 0;
    //   }
    // }
  }

  /// 衝突判定
  /// minoが衝突していればtrueを返す
  bool _onCollisionEnter(List<Point> mino) {
    for (final Point point in mino) {
      if (point.x < 0 ||
          point.x < _horizontalLength ||
          _verticalLength < point.y) {
        return true;
      }
      for (final Point fixedPoint in fixedMino) {
        if (fixedPoint.x == point.x && fixedPoint.y == point.y) {
          return true;
        }
      }
    }
    return false;
  }

  /// 消滅判定
  /// fixedMinoが横一列に並んだときに消去する
  _deleteMino() {
    //   List<int> _countCell = List.filled(20, 0);
    //
    //   for(final Point){
    //
    //   }
    //
    //   _countCell.asMap().forEach(
    //     (index, value) {
    //       // verify if there are 10 mino in row
    //       if (fixedMino.where((element) => element[1] == index).length == 10) {
    //         // delete row
    //         fixedMino.removeWhere((element) => element[1] == index);
    //         countDeletedLine++;
    //         // drop upper mino
    //         fixedMino.where((element) => element[1] < index).forEach((element) {
    //           element[1]++;
    //         });
    //       }
    //     },
    //   );
  }
}
