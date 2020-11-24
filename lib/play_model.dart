import 'dart:async';
import 'package:flutter/material.dart';
import 'mino.dart';

class PlayModel extends ChangeNotifier {
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
  List<int> orderMino = List(14);
  List<int> orderMinoFront = [0, 1, 2, 3, 4, 5, 6];
  List<int> orderMinoBack = [0, 1, 2, 3, 4, 5, 6];
  List<List<int>> currentMino = [];
  List<List<int>> futureMino = [];
  List<List<int>> fixedMino = [];

  countDown() {
    count = 3;
    _countDownTimer = Timer.periodic(
      Duration(seconds: 1),
      (Timer t) {
        count--;
        if (count == -1) {
          _countDownTimer.cancel();
          _generateMino();
          _startMain();
        }
        notifyListeners();
      },
    );
  }

  _startMain() {
    if (_mainTimer == null || _mainTimer?.isActive == false) {
      _mainTimer = Timer.periodic(
        Duration(milliseconds: 1000),
        (Timer t) {
          if (!_verifyGround()) moveDown();
        },
      );
    }
  }

  startWaitTime() {
    _waitTimer = Timer.periodic(
      Duration(milliseconds: 500),
      (Timer t) {
        for (List<int> e in currentMino) {
          fixedMino.add([e[0], e[1]]);
        }
        _deleteMino();
        wait = false;
        _waitTimer?.cancel();
        _generateMino();
        if (_gameOver()) {
        } else {
          _startMain();
        }
      },
    );
  }

  reset() {
    yPos = 0;
    xPos = 0;
    index = -1;
    indexHold = -1;
    angle = 0;
    groundCount = 0;
    countDeletedLine = 0;
    nextMinoList.clear();
    fixedMino.clear();
    currentMino.clear();
    futureMino.clear();
    _mainTimer?.cancel();
    _waitTimer?.cancel();
    wait = false;
    usedHold = false;
    gameOver = false;
    notifyListeners();
  }

  moveLeft() {
    xPos -= 1;
    _updateCurrentMino();
    if (_onCollisionEnter(currentMino)) {
      xPos += 1;
      _updateCurrentMino();
    }
    _verifyGround();
    notifyListeners();
  }

  moveRight() {
    xPos += 1;
    _updateCurrentMino();
    if (_onCollisionEnter(currentMino)) {
      xPos -= 1;
      _updateCurrentMino();
    }
    _verifyGround();
    notifyListeners();
  }

  moveDown() {
    // まず設置しているかを判定する。
    yPos += 1;
    _updateCurrentMino();
    _verifyGround();
    notifyListeners();
  }

  // 接地していたらwaitTimerを起動しtrueを返す
  bool _verifyGround() {
    bool _ground = false;
    _waitTimer?.cancel();
    yPos++;
    _updateCurrentMino();
    // 設置していたら0.5秒間の待ち時間を起動する
    if (_onCollisionEnter(currentMino)) {
      groundCount++;
      // 回転と移動操作があった場合は待ち時間をリセットする
      // ただし15回まで
      if (groundCount < 16) {
        _mainTimer?.cancel();
        wait = true;
        startWaitTime();
      } else {
        yPos--;
        _updateCurrentMino();
        for (List<int> e in currentMino) {
          fixedMino.add([e[0], e[1]]);
        }
        _deleteMino();
        wait = false;
        _waitTimer?.cancel();
        _generateMino();
        _gameOver();
        return true;
      }
      _ground = true;
    } else {
      wait = false;
      _startMain();
    }
    yPos--;
    _updateCurrentMino();
    return _ground;
  }

  bool moveXY(int dx, int dy) {
    xPos += dx;
    yPos += dy;
    _updateCurrentMino();
    if (_onCollisionEnter(currentMino)) {
      xPos -= dx;
      yPos -= dy;
      _updateCurrentMino();
      notifyListeners();
      return false;
    } else {
      _verifyGround();
      notifyListeners();
      return true;
    }
  }

  rotateLeft() {
    final _temporaryAngle = angle;
    angle = (angle + (1 * 90)) % 360;
    _updateCurrentMino();
    // 回転したとき他の障害部に当たった場合
    // SRS(スーパーローテーションシステム)に従いミノを移動させる
    // 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(currentMino)) {
      // iMinoかどうかで分岐
      if (indexMino == 0) {
        // angleで分岐
        switch (angle) {
          case 0:
            if (moveXY(2, 0)) return 0;
            if (moveXY(-1, 0)) return 0;
            if (moveXY(2, -1)) return 0;
            if (moveXY(-1, 2)) return 0;
            break;
          case 90:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(2, 0)) return 0;
            if (moveXY(-1, -2)) return 0;
            if (moveXY(2, 1)) return 0;
            break;
          case 180:
            if (moveXY(1, 0)) return 0;
            if (moveXY(-2, 0)) return 0;
            if (moveXY(-2, 1)) return 0;
            if (moveXY(1, -2)) return 0;
            break;
          case 270:
            if (moveXY(1, 0)) return 0;
            if (moveXY(-2, 0)) return 0;
            if (moveXY(1, 2)) return 0;
            if (moveXY(-2, -1)) return 0;
            break;
        }
      } else {
        // angleで分岐
        switch (angle) {
          case 0:
            if (moveXY(1, 0)) return 0;
            if (moveXY(1, 1)) return 0;
            if (moveXY(0, -2)) return 0;
            if (moveXY(1, -2)) return 0;
            break;
          case 90:
            if (moveXY(1, 0)) return 0;
            if (moveXY(1, -1)) return 0;
            if (moveXY(0, 2)) return 0;
            if (moveXY(1, 2)) return 0;
            break;
          case 180:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(-1, 1)) return 0;
            if (moveXY(0, -2)) return 0;
            if (moveXY(-1, -2)) return 0;
            break;
          case 270:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(-1, -1)) return 0;
            if (moveXY(0, 2)) return 0;
            if (moveXY(-1, 2)) return 0;
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      angle = _temporaryAngle;
      _updateCurrentMino();
      _verifyGround();
      notifyListeners();
    } else {
      _verifyGround();
      notifyListeners();
    }
  }

  rotateRight() {
    final _temporaryAngle = angle;
    angle = (angle + (3 * 90)) % 360;
    _updateCurrentMino();
    // 回転したとき他の障害部に当たった場合
    // SRS(スーパーローテーションシステム)に従いミノを移動させる
    // 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(currentMino)) {
      // iMinoかどうかで分岐
      if (indexMino == 0) {
        // angleで分岐
        switch (angle) {
          case 0:
            if (moveXY(-2, 0)) return 0;
            if (moveXY(1, 0)) return 0;
            if (moveXY(1, 2)) return 0;
            if (moveXY(-2, -1)) return 0;
            break;
          case 90:
            if (moveXY(2, 0)) return 0;
            if (moveXY(-1, 0)) return 0;
            if (moveXY(2, -1)) return 0;
            if (moveXY(-1, 2)) return 0;
            break;
          case 180:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(2, 0)) return 0;
            if (moveXY(-1, -2)) return 0;
            if (moveXY(2, -1)) return 0;
            break;
          case 270:
            if (moveXY(2, 0)) return 0;
            if (moveXY(-1, 0)) return 0;
            if (moveXY(2, 1)) return 0;
            if (moveXY(1, -2)) return 0;
            break;
        }
      } else {
        // angleで分岐
        switch (angle) {
          case 0:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(-1, 1)) return 0;
            if (moveXY(0, -2)) return 0;
            if (moveXY(-1, -2)) return 0;
            break;
          case 90:
            if (moveXY(1, 0)) return 0;
            if (moveXY(1, -1)) return 0;
            if (moveXY(0, 2)) return 0;
            if (moveXY(1, 2)) return 0;
            break;
          case 180:
            if (moveXY(1, 0)) return 0;
            if (moveXY(1, 1)) return 0;
            if (moveXY(0, -2)) return 0;
            if (moveXY(1, -2)) return 0;
            break;
          case 270:
            if (moveXY(-1, 0)) return 0;
            if (moveXY(-1, -1)) return 0;
            if (moveXY(0, 2)) return 0;
            if (moveXY(-1, 2)) return 0;
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      angle = _temporaryAngle;
      _updateCurrentMino();
      _verifyGround();
      notifyListeners();
    } else {
      _verifyGround();
      notifyListeners();
    }
  }

  hardDrop() {
    for (List<int> e in futureMino) {
      fixedMino.add([e[0], e[1]]);
    }
    _generateMino();
    _deleteMino();
    _updateCurrentMino();
    wait = false;
    _waitTimer?.cancel();
    _startMain();
    _gameOver();
    notifyListeners();
  }

  holdMino() {
    if (usedHold) {
    } else {
      int _indexMino;
      _indexMino = indexMino;
      if (-1 < indexHold) {
        indexMino = indexHold;
        indexHold = _indexMino;
        yPos = 0;
        xPos = 0;
        angle = 0;
        _updateCurrentMino();
        notifyListeners();
      } else {
        indexHold = _indexMino;
        _generateMino();
      }
      usedHold = true;
    }
  }

  // game over 判定
  bool _gameOver() {
    if (fixedMino.where((element) => element[1] == -1).isNotEmpty) {
      _mainTimer?.cancel();
      _waitTimer?.cancel();
      gameOver = true;
    }
    return gameOver;
  }

  _generateMino() {
    // 初期化
    if (index == -1) {
      orderMinoFront.shuffle();
      orderMino = [...orderMinoFront, ...orderMinoBack];
      index++;
    }
    // 0番目のときに 7~13番目をシャッフル
    if ((index % 14) == 0) {
      orderMinoBack.shuffle();
      orderMino = [...orderMinoFront, ...orderMinoBack];
    }
    // 7番目のときに 0~6番目をシャッフル
    if ((index % 14) == 7) {
      orderMinoFront.shuffle();
      orderMino = [...orderMinoFront, ...orderMinoBack];
    }
    yPos = 0;
    xPos = 0;
    angle = 0;
    indexMino = orderMino[index % 14];
    nextMinoList = [
      orderMino[(index + 1) % 14],
      orderMino[(index + 2) % 14],
      orderMino[(index + 3) % 14],
      orderMino[(index + 4) % 14],
      orderMino[(index + 5) % 14],
      orderMino[(index + 6) % 14],
    ];
    index++;
    usedHold = false;
    wait = false;
    groundCount = 0;
    _updateCurrentMino();
    notifyListeners();
  }

  // コリジョン情報更新
  _updateCurrentMino() {
    if (currentMino.isEmpty) {
      currentMino = [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
      ];
    }
    Mino.mino[indexMino][angle].asMap().forEach(
      (index, value) {
        currentMino[index][0] = value[0] + xPos;
        currentMino[index][1] = value[1] + yPos;
      },
    );

    _predictDropPos();
  }

  // predict drop position
  _predictDropPos() {
    if (futureMino.isEmpty) {
      futureMino = [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0],
      ];
    }
    for (yPosFuture = yPos; yPosFuture < 21; yPosFuture++) {
      Mino.mino[indexMino][angle].asMap().forEach(
        (index, value) {
          futureMino[index][0] = value[0] + xPos;
          futureMino[index][1] = value[1] + yPosFuture;
        },
      );
      // 衝突が判定されたらひとつ手前を描画してやめる
      if (_onCollisionEnter(futureMino)) {
        futureMino.forEach((element) {
          element[1]--;
        });
        notifyListeners();
        return 0;
      }
    }
  }

  // 衝突判定
  bool _onCollisionEnter(List<List<int>> mino) {
    for (final eMino in mino) {
      if (eMino[0] < -5 || 4 < eMino[0] || 19 < eMino[1]) {
        return true;
      }
      for (final eFixed in fixedMino) {
        if (eFixed[0] == eMino[0] && eFixed[1] == eMino[1]) {
          return true;
        }
      }
    }
    return false;
  }

  // 消滅判定
  _deleteMino() {
    List<int> _countCell = List.filled(20, 0);
    _countCell.asMap().forEach(
      (index, value) {
        // verify if there are 10 mino in row
        if (fixedMino.where((element) => element[1] == index).length == 10) {
          // delete row
          fixedMino.removeWhere((element) => element[1] == index);
          countDeletedLine++;
          // drop upper mino
          fixedMino.where((element) => element[1] < index).forEach((element) {
            element[1]++;
          });
        }
      },
    );
  }
}
