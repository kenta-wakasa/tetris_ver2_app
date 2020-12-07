import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mino.dart';

class PlayModel extends ChangeNotifier {
  /// プレイエリアの大きさ
  final _verticalLength = 20; // プレイエリアの縦の長さ
  final _horizontalLength = 10; // プレイエリアの横の長さ

  /// 時間制御に関する変数
  final _thresholdSecForDropMino = 1.0; // Mino が落下するまでの秒数
  final _thresholdSecForfixMino = 0.5; // Mino が固定されるまでの秒数
  final _limitTimeSec = 180; // 制限時間 ( 秒 )
  int _remainingTime = 0; // 残り時間
  int remainingTimeSec = 0; // 残り時間 秒の部分
  int remainingTimeMin = 0; // 残り時間 分の部分
  final _countDownStartNum = 3; // カウントダウンの秒数
  int countDownNum = 3;

  /// Mino が出る順番に関する変数
  final _generateMinoNum = 1400; // はじめに生成する Mino の個数
  final List<MinoType> _minoOrderList = []; // Mino がでる順番
  int _minoOrderIndex = 0; // 現在の Mino が何番目か

  /// Next と Hold
  List<MinoType> nextMinoTypeList = List.filled(6, MinoType.none);
  MinoType holdMinoType;

  /// 消した行数に関する変数
  int deletedLinesCount = 0;
  int deletedLinesCountBest = 0;

  /// currentMino に関する変数
  MinoType _currentMinoType = MinoType.none;
  MinoAngle _currentMinoAngle = MinoAngle.deg000;
  int _currentMinoXPos = 0;
  int _currentMinoYPos = 0;

  /// プレイエリアに描画される3つの Mino について
  /// currentMino: 現在操作している Mino
  /// futureMino: currentMino の落下位置
  /// frozenMino: 固定された Mino を示す
  List<Point> currentMino = [];
  List<Point> futureMino = [];
  List<Point> frozenMino = [];

  /// 各種 フラグ
  bool gameOver = false; // GameOverになったか
  bool usedHold = false; // Holdを使ったか
  bool _isGrounded = false; //  Mino が接地しているか
  bool _isUpdated = false; //  Mino が動いたか

  /// このmodelが廃棄されるときに呼ばれる
  @override
  void dispose() {
    super.dispose();
    initialize();
    gameOver = true;
  }

  /// 初期化処理
  void initialize() {
    gameOver = false;
    usedHold = false;
    _minoOrderIndex = 0;
    nextMinoTypeList = List.filled(6, MinoType.none);
    holdMinoType = MinoType.none;
    deletedLinesCount = 0;
    countDownNum = _countDownStartNum;
    _remainingTime = _limitTimeSec;
    remainingTimeMin = _remainingTime ~/ 60;
    remainingTimeSec = _remainingTime % 60;
    _minoOrderList.clear();
    frozenMino.clear();
    currentMino.clear();
    futureMino.clear();
  }

  /// [_generateMinoNum]の個数だけ[_minoOrderList]生成する
  void _generateMinoOrderList() {
    while (_minoOrderList.length < _generateMinoNum) {
      final seedMinoIndexList = [
        MinoType.iMino,
        MinoType.oMino,
        MinoType.tMino,
        MinoType.jMino,
        MinoType.lMino,
        MinoType.sMino,
        MinoType.zMino,
      ]..shuffle();
      _minoOrderList.addAll(seedMinoIndexList);
    }
  }

  /// ゲーム開始時のカウントダウンを行う
  /// カウントダウン終了後 Mino を生成する
  Future<void> _countDown() async {
    // 1秒ごとにカウントを減らす
    while (countDownNum > -1) {
      notifyListeners();
      await Future<void>.delayed(const Duration(seconds: 1));
      countDownNum--;
    }
    _generateMino();
  }

  /// === ↓↓↓ メインループ開始 ↓↓↓ === ///
  Future<void> mainLoop(int fps) async {
    /// 初期化処理
    initialize();

    /// ベストスコアを取り出す
    final prefs = await SharedPreferences.getInstance();
    deletedLinesCountBest = prefs.getInt('deletedLinesCountBest') ?? 0;

    /// Mino が 落下するまでの待ちフレーム数  =  fps  *  指定した秒数
    final _thresholdFrameForDropMino = (fps * _thresholdSecForDropMino).toInt();
    var _frameCountForDropMino = 0; // Mino が接地していない状態の経過フレーム

    /// Mino が 固定するまでの待ちフレーム数   = fps  *  指定した秒数
    final _thresholdFrameForFixMino = (fps * _thresholdSecForfixMino).toInt();
    var _frameCountForFixMino = 0; // Mino が接地している状態での経過フレーム

    _generateMinoOrderList(); //  Mino の順番を予め生成する
    await _countDown(); // カウントダウン後に最初の Mino を 生成する

    /// カウントダウン終了からループ処理開始
    final sw = Stopwatch()..start();
    var frame = 0; // フレーム番号
    /// gameOverになるまでループし続ける
    while (!gameOver) {
      frame++;

      ///  Mino が接地していないなら 1.0 秒後に落下させる
      if (!_isGrounded) {
        _frameCountForFixMino = 0;
        _frameCountForDropMino++;
        if (_frameCountForDropMino % _thresholdFrameForDropMino == 0) {
          moveMino(0, 1); // Mino を1行下げる
        }
      } else {
        _frameCountForDropMino = 0;

        /// 以下の条件を満たすとき Mino を固定する
        /// 1: Mino が接地している
        /// 2: 0.5 秒間プレイヤーの操作がない (== _isUpdated が false )
        if (!_isUpdated) {
          _frameCountForFixMino++;
          if (_frameCountForFixMino % _thresholdFrameForFixMino == 0) {
            _freezeMino();
            _deleteLine();
            _checkGameOver();
            _generateMino();
          }

          /// Mino が動いた場合はフレームのカウントを0に戻す
        } else {
          _frameCountForFixMino = 0;
          _isUpdated = false;
        }
      }

      /// 残り時間を減らす
      if (frame % fps == 0) {
        _remainingTime--;
        remainingTimeMin = _remainingTime ~/ 60; // 分の部分
        remainingTimeSec = _remainingTime % 60; // 秒の部分
      }

      /// 時間切れ
      if (_remainingTime == 0) {
        gameOver = true;
      }

      final next = 1000000 * frame ~/ fps;
      await Future<void>.delayed(
        Duration(microseconds: next - sw.elapsedMicroseconds),
      );
    }

    /// BEST の更新
    if (deletedLinesCount > deletedLinesCountBest) {
      prefs.setInt('deletedLinesCountBest', deletedLinesCount);
    }

    notifyListeners();
  }

  /// === ↑↑↑ メインループ終了 ↑↑↑ === ///

  /// 新しい Mino を生成する
  void _generateMino() {
    _currentMinoType = _minoOrderList[_minoOrderIndex];
    _currentMinoAngle = MinoAngle.deg000;
    _currentMinoXPos = 0;
    _currentMinoYPos = 0;
    usedHold = false;
    _updateCurrentMino();

    // Next Mino を更新する
    _minoOrderIndex++;
    for (var i = 0; i < nextMinoTypeList.length; i++) {
      nextMinoTypeList[i] = _minoOrderList[_minoOrderIndex + i];
    }
  }

  /// 現在の MinoType, MinoAngle, xPos, yPos, をもとに最新の Mino に更新する
  void _updateCurrentMino() {
    currentMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 落下位置の取得, 接地判定も行う
    _checkCurrentMinoIsGrounded(); // 接地判定
    _findDropPos(); // 落下位置の取得

    _isUpdated = true; // currentMinoが更新された
    notifyListeners();
  }

  /// currentMino の接地判定
  void _checkCurrentMinoIsGrounded() {
    // currentMinoYPos + 1 の場合に衝突しているかを調べる
    final tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos + 1,
    );
    _isGrounded = _hasCollision(tmpMino);
  }

  /// currentMino の落下位置をもとめる
  void _findDropPos() {
    // ひとつずつ currentMino を下げて 衝突するかを調べる
    for (var dy = 1; dy <= _verticalLength + 1; dy++) {
      final tmpMino = Mino.getMino(
        minoType: _currentMinoType,
        minoAngle: _currentMinoAngle,
        dx: _currentMinoXPos,
        dy: _currentMinoYPos + dy,
      );
      // 衝突したらひとつ前の dy - 1 を返す
      if (_hasCollision(tmpMino)) {
        futureMino = Mino.getMino(
          minoType: _currentMinoType,
          minoAngle: _currentMinoAngle,
          dx: _currentMinoXPos,
          dy: _currentMinoYPos + (dy - 1),
        );
        return;
      }
    }
  }

  /// currentMino を固定する
  void _freezeMino() {
    frozenMino.addAll(currentMino);
  }

  /// 衝突判定
  /// minoが衝突していればtrueを返す
  bool _hasCollision(List<Point> mino) {
    for (final point in mino) {
      // 場外判定
      if (point.x < 0 ||
          point.x > _horizontalLength - 1 ||
          point.y > _verticalLength - 1) {
        return true;
      }
      // 固定されたMinoとの衝突判定
      for (final frozenPoint in frozenMino) {
        if (frozenPoint == point) {
          return true;
        }
      }
    }
    return false;
  }

  /// ラインを消去する
  /// frozenMinoが横一列に並んだときに消去する
  void _deleteLine() {
    // 各列で 10 個 point が存在する列を消す
    // 長さ 20 の 0 詰めしたリストに個数を格納していく
    // pointCountList[n]　==  n 列目に存在する point の個数
    final pointCountList = List.filled(_verticalLength, 0);

    /// n 行目に存在する poin を数える
    for (final point in frozenMino) {
      if (point.y >= 0 && point.y < _verticalLength) {
        pointCountList[point.y.toInt()]++;
      }
    }

    /// 上から1行ずつ消去可能な行があるか調べていく
    for (var index = 0; index < pointCountList.length; index++) {
      // 消去可能な行があった場合
      if (pointCountList[index] == _horizontalLength) {
        deletedLinesCount++; // 消去したライン数をカウントアップしていく
        frozenMino.removeWhere((point) => point.y == index); // 行を消去
        // index より上の行に存在する point を1行下げる
        // for (final point in frozenMino) で書けそうだが　point の更新が上手くいかなかった
        for (var i = 0; i < frozenMino.length; i++) {
          // y は下方向に正であることに注意
          if (frozenMino[i].y < index) {
            // Point の x, y は書き換え不能なため frozenMino[i].y += 1 とは書けない
            // 改めて Point を生成して上書きする
            frozenMino[i] = Point(frozenMino[i].x, frozenMino[i].y + 1);
          }
        }
      }
    }
  }

  /// gameOver 判定
  void _checkGameOver() {
    // y == -1 にひとつでもfrozenMinoがあれば gameOver
    if (frozenMino.where((point) => point.y == -1).isNotEmpty) {
      gameOver = true;
      notifyListeners();
    } else {
      gameOver = false;
    }
  }

  /// === 以下プレイヤーが操作で使う関数 === ///

  /// 現在の位置から与えられた dx, dy だけ移動する
  /// 移動できた場合は true を返す
  bool moveMino(int dx, int dy) {
    // 衝突判定のための一時変数
    final tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos + dx,
      dy: _currentMinoYPos + dy,
    );
    // 移動先が衝突していなければ
    // ・currentMino を更新する
    // ・true を返す
    if (!_hasCollision(tmpMino)) {
      _currentMinoXPos += dx;
      _currentMinoYPos += dy;
      _updateCurrentMino();
      return true;
      // 移動先が衝突していれば
      // ・currenMino は更新しない
      // ・false を返す
    } else {
      return false;
    }
  }

  /// Mino の回転についての関数はひとつにまとめられそうだが
  /// SRS(スーパーローテーションシステム)は
  /// 時計回りと半時計周りで挙動が異なるため分割している

  /// 時計回りに90度回転
  void rotateClockwise() {
    final tmpAngle = _currentMinoAngle; // 回転前の角度を一時的に保持する
    _currentMinoAngle =
        MinoAngle.values[(_currentMinoAngle.index + 3) % 4]; // 反時計回りに270度回転と同義
    final tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 回転したとき衝突判定があっ他場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_hasCollision(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.iMino) {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
          case MinoAngle.deg000:
            // ignore: lines_longer_than_80_chars
            if (moveMino(-2, 0) ||
                moveMino(1, 0) ||
                moveMino(1, 2) ||
                moveMino(-2, -1)) {
              return;
            }
            break;
          case MinoAngle.deg090:
            if (moveMino(2, 0) ||
                moveMino(-1, 0) ||
                moveMino(2, -1) ||
                moveMino(-1, 2)) {
              return;
            }
            break;
          case MinoAngle.deg180:
            if (moveMino(-1, 0) ||
                moveMino(2, 0) ||
                moveMino(-1, -2) ||
                moveMino(2, -1)) {
              return;
            }
            break;
          case MinoAngle.deg270:
            if (moveMino(2, 0) ||
                moveMino(-1, 0) ||
                moveMino(2, 1) ||
                moveMino(1, -2)) {
              return;
            }
            break;
        }

        /// I_Mino 以外
      } else {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
          case MinoAngle.deg000:
            if (moveMino(-1, 0) ||
                moveMino(-1, 1) ||
                moveMino(0, -2) ||
                moveMino(-1, -2)) {
              return;
            }
            break;
          case MinoAngle.deg090:
            if (moveMino(1, 0) ||
                moveMino(1, -1) ||
                moveMino(0, 2) ||
                moveMino(1, 2)) {
              return;
            }
            break;
          case MinoAngle.deg180:
            if (moveMino(1, 0) ||
                moveMino(1, 1) ||
                moveMino(0, -2) ||
                moveMino(1, -2)) {
              return;
            }
            break;
          case MinoAngle.deg270:
            if (moveMino(-1, 0) ||
                moveMino(-1, -1) ||
                moveMino(0, 2) ||
                moveMino(-1, 2)) {
              return;
            }
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      _currentMinoAngle = tmpAngle;

      /// 衝突しなかった場合
    } else {
      _updateCurrentMino();
    }
  }

  /// 反時計回りに90度回転
  void rotateAntiClockwise() {
    final tmpAngle = _currentMinoAngle; // 回転前の角度を一時的に保持する
    _currentMinoAngle =
        MinoAngle.values[(_currentMinoAngle.index + 1) % 4]; // +1 が反時計回りに1回転
    final tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 回転したとき衝突判定があっ他場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_hasCollision(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.iMino) {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
          case MinoAngle.deg000:
            if (moveMino(2, 0) ||
                moveMino(-1, 0) ||
                moveMino(2, -1) ||
                moveMino(-1, 2)) {
              return;
            }
            break;
          case MinoAngle.deg090:
            if (moveMino(-1, 0) ||
                moveMino(2, 0) ||
                moveMino(-1, -2) ||
                moveMino(2, 1)) {
              return;
            }
            break;
          case MinoAngle.deg180:
            if (moveMino(1, 0) ||
                moveMino(-2, 0) ||
                moveMino(-2, 1) ||
                moveMino(1, -2)) {
              return;
            }
            break;
          case MinoAngle.deg270:
            if (moveMino(1, 0) ||
                moveMino(-2, 0) ||
                moveMino(1, 2) ||
                moveMino(-2, -1)) {
              return;
            }
            break;
        }

        /// I_Mino 以外
      } else {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
          case MinoAngle.deg000:
            if (moveMino(1, 0) ||
                moveMino(1, 1) ||
                moveMino(0, -2) ||
                moveMino(1, -2)) {
              return;
            }
            break;
          case MinoAngle.deg090:
            if (moveMino(1, 0) ||
                moveMino(1, -1) ||
                moveMino(0, 2) ||
                moveMino(1, 2)) {
              return;
            }
            break;
          case MinoAngle.deg180:
            if (moveMino(-1, 0) ||
                moveMino(-1, 1) ||
                moveMino(0, -2) ||
                moveMino(-1, -2)) {
              return;
            }
            break;
          case MinoAngle.deg270:
            if (moveMino(-1, 0) ||
                moveMino(-1, -1) ||
                moveMino(0, 2) ||
                moveMino(-1, 2)) {
              return;
            }
            break;
        }
      }
      // どこにも動かせなかった場合角度を戻す
      _currentMinoAngle = tmpAngle;

      /// 衝突しなかった場合
    } else {
      _updateCurrentMino();
    }
  }

  /// 下フリック操作で一気に Mino を落下させる
  void hardDrop() {
    currentMino = List.of(futureMino); // 一気にMinoを落下させる
    _freezeMino();
    _deleteLine();
    _checkGameOver();
    _generateMino();
  }

  /// 上フリックで Mino を Hold する
  /// すでに Hold している Mino がある場合は入れ替える
  void holdMino() {
    // Minoが生成されてからまだ一度も Hold が使われていない場合
    if (!usedHold) {
      // すでに Hold されている Mino がある場合
      // currentMino と holdMino を入れ替える
      if (holdMinoType != MinoType.none) {
        final tmpMinoType = _currentMinoType; // 一時的に保持
        _currentMinoType = holdMinoType;
        holdMinoType = tmpMinoType;
        _currentMinoAngle = MinoAngle.deg000;
        _currentMinoXPos = 0;
        _currentMinoYPos = 0;
        _updateCurrentMino();

        // まだ一度も Hold していない場合
        // currentMino を holdMino に追加し
        // 新しい Mino を生成する
      } else {
        holdMinoType = _currentMinoType;
        _generateMino();
      }
      usedHold = true;
    }
  }
}
