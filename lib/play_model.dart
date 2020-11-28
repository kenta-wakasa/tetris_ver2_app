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

  int frameCountForDropMino = 0;
  int frameCountForFixCurrentMino = 0;
  bool currentMinoIsGrounding = false; // ミノが接地しているか
  bool minoIsMoving = false;
  bool mainLoopIsCancelled = true;
  List<int> minoOrderList = [];
  int minoOrderIndex = 0;
  final _numGenerateMino = 7000; // はじめに生成するミノの個数

  int currentMinoType = 0;
  int currentMinoAngle = 0;
  int currentMinoXPos = 0;
  int currentMinoYPos = 0;

  /// 質問：disposeはどこで呼ばれるのでしょう？
  @override
  void dispose() {
    super.dispose();
    mainLoopIsCancelled = true;
    print('dispose!');
  }

  /// frameごとに処理を実行する
  Future<void> mainLoop(int fps) async {
    /// 初期化処理
    mainLoopIsCancelled = false;
    frameCountForDropMino = 0;
    frameCountForFixCurrentMino = 0;
    fixedMino.clear();
    currentMino.clear();
    futureMino.clear();

    _generateMinoOrderList(); // ミノの順番を予め生成する
    await _countDown();
    _generateMino();

    /// メインループ
    final sw = Stopwatch()..start();
    int frame = 0; // フレーム番号

    while (!mainLoopIsCancelled) {
      frame++;

      /// ミノが接地していないなら1秒後に落下させる
      if (!currentMinoIsGrounding) {
        frameCountForDropMino++;
        if (frameCountForDropMino % (fps * 1) == 0) {
          moveMino(0, 1);
        }
        frameCountForFixCurrentMino = 0;
      } else {
        /// 以下の条件を満たすときミノを固定する
        /// 1: ミノが接地している
        /// 2: 0.5秒間プレイヤーの操作がない
        if (!minoIsMoving) {
          frameCountForFixCurrentMino++;
          if (frameCountForFixCurrentMino % (fps * 0.5).toInt() == 0) {
            _fixCurrentMino();
            _generateMino();
          }
        } else {
          frameCountForFixCurrentMino = 0;
          minoIsMoving = false;
        }
        frameCountForDropMino = 0;
      }

      var next = 1000000 * frame ~/ fps;
      await Future.delayed(
        Duration(microseconds: next - sw.elapsedMicroseconds),
      );
    }
    notifyListeners();
  }

  /// 新しいミノを生成する
  void _generateMino() {
    currentMinoType = minoOrderList[minoOrderIndex % _numGenerateMino];
    minoOrderIndex++;
    currentMinoAngle = 0;
    currentMinoXPos = 0;
    currentMinoYPos = 0;
    _updateCurrentMino();
  }

  /// [_numGenerateMino]の数だけミノリスト生成する
  void _generateMinoOrderList() {
    while (minoOrderList.length < _numGenerateMino) {
      final seedMinoIndexList = [0, 1, 2, 3, 4, 5, 6];
      seedMinoIndexList.shuffle();
      minoOrderList.addAll(seedMinoIndexList);
    }
  }

  // 現在の位置から与えられた dx, dy だけ移動する
  // 移動できた場合は true を返す
  bool moveMino(int dx, int dy) {
    // 衝突判定のための一時変数
    final List<Point> tmpMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[currentMinoAngle],
      dx: currentMinoXPos + dx,
      dy: currentMinoYPos + dy,
    );
    // 移動先が衝突していなければ
    // currentMinoを更新する
    if (!_onCollisionEnter(tmpMino)) {
      currentMinoXPos += dx;
      currentMinoYPos += dy;
      _updateCurrentMino();
      return true;
    } else {
      return false;
    }
  }

  /// currentMino を固定する
  void _fixCurrentMino() {
    // 単純に add するとポインタが渡されてしまうことに注意
    // [...list] で deep_copy が可能 (詳細は spread operator で検索)
    fixedMino.addAll([...currentMino]);
  }

  /// 現在の MinoType, xPos, yPos, angle をもとに最新のミノに更新する
  /// 落下位置の取得, 接地判定も行う
  void _updateCurrentMino() {
    currentMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[currentMinoAngle],
      dx: currentMinoXPos,
      dy: currentMinoYPos,
    );
    _findDropPos(); // 落下位置の取得
    _checkCurrentMinoIsGrounding(); // 接地判定
    notifyListeners();
  }

  /// ゲーム開始時のカウントダウンを行う
  Future<void> _countDown() async {
    final int fps = 1;
    count = 3;
    notifyListeners();
    // 1秒ごとにカウントを減らす
    while (count > -1) {
      await Future.delayed(Duration(seconds: 1));
      count--;
      notifyListeners();
    }
  }

  /// 衝突判定
  /// minoが衝突していればtrueを返す
  bool _onCollisionEnter(List<Point> mino) {
    for (final Point point in mino) {
      // 場外判定
      if (point.x < 0 ||
          point.x > _horizontalLength - 1 ||
          point.y > _verticalLength - 1) {
        return true;
      }
      // 固定されたMinoとの衝突判定
      for (final Point fixedPoint in fixedMino) {
        if (fixedPoint.x == point.x && fixedPoint.y == point.y) {
          return true;
        }
      }
    }
    return false;
  }

  /// currentMino の接地判定
  void _checkCurrentMinoIsGrounding() {
    // currentMinoYPos + 1 が衝突しているかを調べる
    final List<Point> tmpMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[currentMinoAngle],
      dx: currentMinoXPos,
      dy: currentMinoYPos + 1,
    );
    if (_onCollisionEnter(tmpMino)) {
      currentMinoIsGrounding = true;
    } else {
      currentMinoIsGrounding = false;
    }
  }

  /// currentMino の落下位置をもとめる
  void _findDropPos() {
    // ひとつずつ currentMino を下げて 衝突するかを調べる
    for (int dy = 1; dy <= _verticalLength + 1; dy++) {
      final List<Point> tmpMino = Mino.getMino(
        minoType: MinoType.values[currentMinoType],
        minoAngle: MinoAngle.values[currentMinoAngle],
        dx: currentMinoXPos,
        dy: currentMinoYPos + dy,
      );
      // 衝突したらひとつ前の dy - 1 を返す
      if (_onCollisionEnter(tmpMino)) {
        futureMino = Mino.getMino(
          minoType: MinoType.values[currentMinoType],
          minoAngle: MinoAngle.values[currentMinoAngle],
          dx: currentMinoXPos,
          dy: currentMinoYPos + (dy - 1),
        );
        return;
      }
    }
  }

  /// 時計回りに90度回転
  void rotateClockwise() {
    final int tmpAngle = currentMinoAngle; // 回転前の角度を一時的に保持する
    currentMinoAngle = (currentMinoAngle + 3) % 4; // 反時計回りに270度回転と同義
    final List<Point> tmpMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[currentMinoAngle],
      dx: currentMinoXPos,
      dy: currentMinoYPos,
    );

    /// 回転したとき他の障害部に当たった場合
    /// SRS(スーパーローテーションシステム)に従いミノを移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (currentMinoType == MinoType.I_Mino.index) {
        // angleで分岐
        switch (MinoAngle.values[currentMinoAngle]) {
          case MinoAngle.Rot_000:
            if (moveMino(-2, 0)) return;
            if (moveMino(1, 0)) return;
            if (moveMino(1, 2)) return;
            if (moveMino(-2, -1)) return;
            break;
          case MinoAngle.Rot_090:
            if (moveMino(2, 0)) return;
            if (moveMino(-1, 0)) return;
            if (moveMino(2, -1)) return;
            if (moveMino(-1, 2)) return;
            break;
          case MinoAngle.Rot_180:
            if (moveMino(-1, 0)) return;
            if (moveMino(2, 0)) return;
            if (moveMino(-1, -2)) return;
            if (moveMino(2, -1)) return;
            break;
          case MinoAngle.Rot_270:
            if (moveMino(2, 0)) return;
            if (moveMino(-1, 0)) return;
            if (moveMino(2, 1)) return;
            if (moveMino(1, -2)) return;
            break;
        }

        /// I_Mino 以外
      } else {
        // angleで分岐
        switch (MinoAngle.values[currentMinoAngle]) {
          case MinoAngle.Rot_000:
            if (moveMino(-1, 0)) return;
            if (moveMino(-1, 1)) return;
            if (moveMino(0, -2)) return;
            if (moveMino(-1, -2)) return;
            break;
          case MinoAngle.Rot_090:
            if (moveMino(1, 0)) return;
            if (moveMino(1, -1)) return;
            if (moveMino(0, 2)) return;
            if (moveMino(1, 2)) return;
            break;
          case MinoAngle.Rot_180:
            if (moveMino(1, 0)) return;
            if (moveMino(1, 1)) return;
            if (moveMino(0, -2)) return;
            if (moveMino(1, -2)) return;
            break;
          case MinoAngle.Rot_270:
            if (moveMino(-1, 0)) return;
            if (moveMino(-1, -1)) return;
            if (moveMino(0, 2)) return;
            if (moveMino(-1, 2)) return;
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      currentMinoAngle = tmpAngle;
    }
    _updateCurrentMino();
  }

  /// 反時計回りに90度回転
  void rotateAntiClockwise() {
    final int tmpAngle = currentMinoAngle; // 回転前の角度を一時的に保持する
    currentMinoAngle = (currentMinoAngle + 1) % 4; // 反時計回りに270度回転と同義
    final List<Point> tmpMino = Mino.getMino(
      minoType: MinoType.values[currentMinoType],
      minoAngle: MinoAngle.values[currentMinoAngle],
      dx: currentMinoXPos,
      dy: currentMinoYPos,
    );

    /// 回転したとき他の障害部に当たった場合
    /// SRS(スーパーローテーションシステム)に従いミノを移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (currentMinoType == MinoType.I_Mino.index) {
        // angleで分岐
        switch (MinoAngle.values[currentMinoAngle]) {
          case MinoAngle.Rot_000:
            if (moveMino(2, 0)) return;
            if (moveMino(-1, 0)) return;
            if (moveMino(2, -1)) return;
            if (moveMino(-1, 2)) return;
            break;
          case MinoAngle.Rot_090:
            if (moveMino(-1, 0)) return;
            if (moveMino(2, 0)) return;
            if (moveMino(-1, -2)) return;
            if (moveMino(2, 1)) return;
            break;
          case MinoAngle.Rot_180:
            if (moveMino(1, 0)) return;
            if (moveMino(-2, 0)) return;
            if (moveMino(-2, 1)) return;
            if (moveMino(1, -2)) return;
            break;
          case MinoAngle.Rot_270:
            if (moveMino(1, 0)) return;
            if (moveMino(-2, 0)) return;
            if (moveMino(1, 2)) return;
            if (moveMino(-2, -1)) return;
            break;
        }

        /// I_Mino 以外
      } else {
        // angleで分岐
        switch (MinoAngle.values[currentMinoAngle]) {
          case MinoAngle.Rot_000:
            if (moveMino(1, 0)) return;
            if (moveMino(1, 1)) return;
            if (moveMino(0, -2)) return;
            if (moveMino(1, -2)) return;
            break;
          case MinoAngle.Rot_090:
            if (moveMino(1, 0)) return;
            if (moveMino(1, -1)) return;
            if (moveMino(0, 2)) return;
            if (moveMino(1, 2)) return;
            break;
          case MinoAngle.Rot_180:
            if (moveMino(-1, 0)) return;
            if (moveMino(-1, 1)) return;
            if (moveMino(0, -2)) return;
            if (moveMino(-1, -2)) return;
            break;
          case MinoAngle.Rot_270:
            if (moveMino(-1, 0)) return;
            if (moveMino(-1, -1)) return;
            if (moveMino(0, 2)) return;
            if (moveMino(-1, 2)) return;
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      currentMinoAngle = tmpAngle;
    }
    _updateCurrentMino();
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
    //         case MinoAngle.Rot_000:
    //           if (moveMino(2, 0)) return;
    //           if (moveMino(-1, 0)) return;
    //           if (moveMino(2, -1)) return;
    //           if (moveMino(-1, 2)) return;
    //           break;
    //         case MinoAngle.Rot_090:
    //           if (moveMino(-1, 0)) return;
    //           if (moveMino(2, 0)) return;
    //           if (moveMino(-1, -2)) return;
    //           if (moveMino(2, 1)) return;
    //           break;
    //         case MinoAngle.Rot_180:
    //           if (moveMino(1, 0)) return;
    //           if (moveMino(-2, 0)) return;
    //           if (moveMino(-2, 1)) return;
    //           if (moveMino(1, -2)) return;
    //           break;
    //         case MinoAngle.Rot_270:
    //           if (moveMino(1, 0)) return;
    //           if (moveMino(-2, 0)) return;
    //           if (moveMino(1, 2)) return;
    //           if (moveMino(-2, -1)) return;
    //           break;
    //       }
    //     } else {
    //       // angleで分岐
    //       switch (angle) {
    //         case MinoAngle.Rot_000:
    //           if (moveMino(1, 0)) return;
    //           if (moveMino(1, 1)) return;
    //           if (moveMino(0, -2)) return;
    //           if (moveMino(1, -2)) return;
    //           break;
    //         case MinoAngle.Rot_090:
    //           if (moveMino(1, 0)) return;
    //           if (moveMino(1, -1)) return;
    //           if (moveMino(0, 2)) return;
    //           if (moveMino(1, 2)) return;
    //           break;
    //         case MinoAngle.Rot_180:
    //           if (moveMino(-1, 0)) return;
    //           if (moveMino(-1, 1)) return;
    //           if (moveMino(0, -2)) return;
    //           if (moveMino(-1, -2)) return;
    //           break;
    //         case MinoAngle.Rot_270:
    //           if (moveMino(-1, 0)) return;
    //           if (moveMino(-1, -1)) return;
    //           if (moveMino(0, 2)) return;
    //           if (moveMino(-1, 2)) return;
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
    //       case MinoAngle.Rot_000:
    //         if (moveMino(-2, 0)) return;
    //         if (moveMino(1, 0)) return;
    //         if (moveMino(1, 2)) return;
    //         if (moveMino(-2, -1)) return;
    //         break;
    //       case MinoAngle.Rot_090:
    //         if (moveMino(2, 0)) return;
    //         if (moveMino(-1, 0)) return;
    //         if (moveMino(2, -1)) return;
    //         if (moveMino(-1, 2)) return;
    //         break;
    //       case MinoAngle.Rot_180:
    //         if (moveMino(-1, 0)) return;
    //         if (moveMino(2, 0)) return;
    //         if (moveMino(-1, -2)) return;
    //         if (moveMino(2, -1)) return;
    //         break;
    //       case MinoAngle.Rot_270:
    //         if (moveMino(2, 0)) return;
    //         if (moveMino(-1, 0)) return;
    //         if (moveMino(2, 1)) return;
    //         if (moveMino(1, -2)) return;
    //         break;
    //     }
    //   } else {
    //     // angleで分岐
    //     switch (angle) {
    //       case MinoAngle.Rot_000:
    //         if (moveMino(-1, 0)) return;
    //         if (moveMino(-1, 1)) return;
    //         if (moveMino(0, -2)) return;
    //         if (moveMino(-1, -2)) return;
    //         break;
    //       case MinoAngle.Rot_090:
    //         if (moveMino(1, 0)) return;
    //         if (moveMino(1, -1)) return;
    //         if (moveMino(0, 2)) return;
    //         if (moveMino(1, 2)) return;
    //         break;
    //       case MinoAngle.Rot_180:
    //         if (moveMino(1, 0)) return;
    //         if (moveMino(1, 1)) return;
    //         if (moveMino(0, -2)) return;
    //         if (moveMino(1, -2)) return;
    //         break;
    //       case MinoAngle.Rot_270:
    //         if (moveMino(-1, 0)) return;
    //         if (moveMino(-1, -1)) return;
    //         if (moveMino(0, 2)) return;
    //         if (moveMino(-1, 2)) return;
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
