import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mino.dart';

class PlayModel extends ChangeNotifier {
  /// プレイエリアの大きさ
  final int _verticalLength = 20; // プレイエリアの縦の長さ
  final int _horizontalLength = 10; // プレイエリアの横の長さ

  /// 時間制御に関する変数
  final double _thresholdSecForDropMino = 1.0; // Mino が落下するまでの秒数
  final double _thresholdSecForfixMino = 0.5; // Mino が固定されるまでの秒数
  final int _limitTimeSec = 180; // 制限時間 ( 秒 )
  int _remainingTime = 0; // 残り時間
  int remainingTimeSec = 0; // 残り時間 秒の部分
  int remainingTimeMin = 0; // 残り時間 分の部分
  final int _countDownStartNum = 3; // カウントダウンの秒数
  int countDownNum = 3;

  /// Mino が出る順番に関する変数
  final int _generateMinoNum = 1400; // はじめに生成する Mino の個数
  List<MinoType> _minoOrderList = []; // Mino がでる順番
  int _minoOrderIndex = 0; // 現在の Mino が何番目か

  /// Next と Hold
  List<MinoType> nextMinoTypeList = List.filled(6, MinoType.None);
  MinoType holdMinoType;

  /// 消した行数に関する変数
  int deletedLinesCount = 0;
  int deletedLinesCountBest = 0;

  /// currentMino に関する変数
  MinoType _currentMinoType = MinoType.None;
  MinoAngle _currentMinoAngle = MinoAngle.Rot_000;
  int _currentMinoXPos = 0;
  int _currentMinoYPos = 0;

  /// プレイエリアに描画される3つの Mino について
  /// currentMino: 現在操作している Mino
  /// futureMino: currentMino の落下位置
  /// fixedMino: 固定された Mino を示す
  List<Point> currentMino = [];
  List<Point> futureMino = [];
  List<Point> fixedMino = [];

  /// 各種 フラグ
  bool gameOver = false; // GameOverになったか
  bool usedHold = false; // Holdを使ったか
  bool _currentMinoIsGrounding = false; //  Mino が接地しているか
  bool _minoIsMoving = false; //  Mino が動いたか

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
    nextMinoTypeList = List.filled(6, MinoType.None);
    holdMinoType = MinoType.None;
    deletedLinesCount = 0;
    countDownNum = _countDownStartNum;
    _remainingTime = _limitTimeSec;
    remainingTimeMin = _remainingTime ~/ 60;
    remainingTimeSec = _remainingTime % 60;
    _minoOrderList.clear();
    fixedMino.clear();
    currentMino.clear();
    futureMino.clear();
  }

  /// [_generateMinoNum]の個数だけ[_minoOrderList]生成する
  void _generateMinoOrderList() {
    while (_minoOrderList.length < _generateMinoNum) {
      final seedMinoIndexList = [
        MinoType.I_Mino,
        MinoType.O_Mino,
        MinoType.T_Mino,
        MinoType.J_Mino,
        MinoType.L_Mino,
        MinoType.S_Mino,
        MinoType.Z_Mino,
      ];
      seedMinoIndexList.shuffle();
      _minoOrderList.addAll(seedMinoIndexList);
    }
  }

  /// ゲーム開始時のカウントダウンを行う
  /// カウントダウン終了後 Mino を生成する
  Future<void> _countDown() async {
    // 1秒ごとにカウントを減らす
    while (countDownNum > -1) {
      notifyListeners();
      await Future.delayed(Duration(seconds: 1));
      countDownNum--;
    }
    _generateMino();
  }

  /// === ↓↓↓ メインループ開始 ↓↓↓ === ///
  Future<void> mainLoop(int fps) async {
    /// 初期化処理
    initialize();
    // ベストスコアを取り出す
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    deletedLinesCountBest = prefs.get('deletedLinesCountBest') ?? 0;
    //  Mino の順番を予め生成する
    _generateMinoOrderList();
    await _countDown(); // カウントダウン後に最初の Mino を 生成する

    /// frame ごとに処理を実行する
    final sw = Stopwatch()..start();
    int frame = 0; // フレーム番号

    // Mino が 落下するまでのフレーム数
    final int _thresholdFrameForDropMino =
        (fps * _thresholdSecForDropMino).toInt();
    int _frameCountForDropMino = 0; // Mino が接地していない状態の経過フレーム

    // Mino が 固定するまでのフレーム数
    final _thresholdFrameForFixMino = (fps * _thresholdSecForfixMino).toInt();
    int _frameCountForFixMino = 0; // Mino が接地している状態での経過フレーム
    // gameOverになるまでループし続ける
    while (!gameOver) {
      frame++;

      ///  Mino が接地していないなら 1.0 秒後に落下させる
      if (!_currentMinoIsGrounding) {
        _frameCountForDropMino++;
        _frameCountForFixMino = 0;
        if (_frameCountForDropMino % _thresholdFrameForDropMino == 0) {
          moveMino(0, 1); // Mino を1行下げる
        }
      } else {
        /// 以下の条件を満たすとき Mino を固定する
        /// 1:  Mino が接地している
        /// 2: 0.5 秒間プレイヤーの操作がない (== minoIsMoving が false )
        if (!_minoIsMoving) {
          _frameCountForFixMino++;
          _frameCountForDropMino = 0;
          if (_frameCountForFixMino % _thresholdFrameForFixMino == 0) {
            _fixMino();
            _deleteLine();
            _checkGameOver();
            _generateMino();
          }

          /// Mino が動いた場合はフレームのカウントを0に戻す
        } else {
          _frameCountForFixMino = 0;
          _minoIsMoving = false;
        }
      }

      /// 残り時間を減らす
      if (frame % fps == 0) {
        _remainingTime--;
        remainingTimeMin = _remainingTime ~/ 60;
        remainingTimeSec = _remainingTime % 60;
      }

      /// 時間切れ
      if (_remainingTime == 0) {
        gameOver = true;
      }

      var next = 1000000 * frame ~/ fps;
      await Future.delayed(
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
    _currentMinoAngle = MinoAngle.Rot_000;
    _currentMinoXPos = 0;
    _currentMinoYPos = 0;
    usedHold = false;
    _updateCurrentMino();

    // Next Mino を更新する
    _minoOrderIndex++;
    for (int i = 0; i < nextMinoTypeList.length; i++) {
      nextMinoTypeList[i] = _minoOrderList[(_minoOrderIndex + i)];
    }
  }

  /// 現在の MinoType, xPos, yPos, angle をもとに最新の Mino に更新する
  /// 落下位置の取得, 接地判定も行う
  void _updateCurrentMino() {
    currentMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );
    _checkCurrentMinoIsGrounding(); // 接地判定
    _findDropPos(); // 落下位置の取得

    _minoIsMoving = true; // currentMino の更新を Mino が動いたとしている
    notifyListeners();
  }

  /// currentMino の接地判定
  void _checkCurrentMinoIsGrounding() {
    // currentMinoYPos + 1 の場合に衝突しているかを調べる
    final List<Point> tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos + 1,
    );
    if (_onCollisionEnter(tmpMino)) {
      _currentMinoIsGrounding = true;
    } else {
      _currentMinoIsGrounding = false;
    }
  }

  /// currentMino の落下位置をもとめる
  void _findDropPos() {
    // ひとつずつ currentMino を下げて 衝突するかを調べる
    for (int dy = 1; dy <= _verticalLength + 1; dy++) {
      final List<Point> tmpMino = Mino.getMino(
        minoType: _currentMinoType,
        minoAngle: _currentMinoAngle,
        dx: _currentMinoXPos,
        dy: _currentMinoYPos + dy,
      );
      // 衝突したらひとつ前の dy - 1 を返す
      if (_onCollisionEnter(tmpMino)) {
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
  void _fixMino() {
    // 単純に add するとポインタが渡されてしまうことに注意
    // [...list] で deep_copy が可能 (詳細は spread operator で検索)
    fixedMino.addAll([...currentMino]);
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

  /// ラインを消去する
  /// fixedMinoが横一列に並んだときに消去する
  void _deleteLine() {
    // 各列で 10 個 point が存在する列を消す
    // 長さ 20 の 0 詰めしたリストに個数を格納していく
    // pointCountList[n]　==  n 列目に存在する point の個数
    List<int> pointCountList = List.filled(20, 0);

    /// n 行目に存在する poin を数える
    for (final Point point in fixedMino) {
      if (point.y >= 0 && point.y < 20) {
        pointCountList[point.y]++;
      }
    }

    /// 上から1行ずつ消去可能な行があるか調べていく
    for (int index = 0; index < pointCountList.length; index++) {
      // 消去可能な行があった場合
      if (pointCountList[index] == 10) {
        deletedLinesCount++; // 消去したライン数をカウントアップしていく
        fixedMino.removeWhere((point) => point.y == index); // 行を消去
        // index より上の行に存在する point を1行下げる
        // for (final point in fixedMino) で書けそうだが　point の更新が上手くいかなかった
        for (int i = 0; i < fixedMino.length; i++) {
          // y は下方向に正であることに注意
          if (fixedMino[i].y < index) {
            // Point の x, y は書き換え不能なため fixedMino[i].y += 1 とは書けない
            // 改めて Point を生成して上書きする
            fixedMino[i] = Point(fixedMino[i].x, fixedMino[i].y + 1);
          }
        }
      }
    }
  }

  /// gameOver 判定
  void _checkGameOver() {
    // y == -1 にひとつでもfixedMinoがあれば gameOver
    if (fixedMino.where((point) => point.y == -1).isNotEmpty) {
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
    final List<Point> tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos + dx,
      dy: _currentMinoYPos + dy,
    );
    // 移動先が衝突していなければ
    // ・currentMino を更新する
    // ・true を返す
    if (!_onCollisionEnter(tmpMino)) {
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
    final MinoAngle tmpAngle = _currentMinoAngle; // 回転前の角度を一時的に保持する
    _currentMinoAngle =
        MinoAngle.values[(_currentMinoAngle.index + 3) % 4]; // 反時計回りに270度回転と同義
    final List<Point> tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 回転したとき衝突判定があっ他場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.I_Mino) {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
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
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
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
      _currentMinoAngle = tmpAngle;

      /// 衝突しなかった場合
    } else {
      _updateCurrentMino();
    }
  }

  /// 反時計回りに90度回転
  void rotateAntiClockwise() {
    final MinoAngle tmpAngle = _currentMinoAngle; // 回転前の角度を一時的に保持する
    _currentMinoAngle =
        MinoAngle.values[(_currentMinoAngle.index + 1) % 4]; // +1 が反時計回りに1回転
    final List<Point> tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 回転したとき衝突判定があっ他場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.I_Mino) {
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
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
        // 回転後の角度によって移動させる順番が分岐する
        // 順に移動させられるかを確認し
        // 移動できた時点で return で終了する
        switch (_currentMinoAngle) {
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
      _currentMinoAngle = tmpAngle;

      /// 衝突しなかった場合
    } else {
      _updateCurrentMino();
    }
  }

  /// 下フリック操作で一気に Mino を落下させる
  hardDrop() {
    currentMino = [...futureMino]; // 一気にMinoを落下させる
    _fixMino();
    _deleteLine();
    _checkGameOver();
    _generateMino();
  }

  /// 上フリックで Mino を Hold する
  /// すでに Hold している Mino がある場合は入れ替える
  holdMino() {
    // Minoが生成されてからまだ一度も Hold が使われていない場合
    if (!usedHold) {
      // すでに Hold されている Mino がある場合
      // currentMino と holdMino を入れ替える
      if (holdMinoType != MinoType.None) {
        MinoType tmpMinoType = _currentMinoType; // 一時的に保持
        _currentMinoType = holdMinoType;
        holdMinoType = tmpMinoType;
        _currentMinoAngle = MinoAngle.Rot_000;
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
