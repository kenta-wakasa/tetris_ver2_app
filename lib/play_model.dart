import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mino.dart';

class PlayModel extends ChangeNotifier {
  final int _verticalLength = 20; // プレイエリアの縦の長さ
  final int _horizontalLength = 10; // プレイエリアの横の長さ
  final int _countDownStartNum = 3; // カウントダウンの秒数
  final int _generateMinoNum = 1400; // はじめに生成する Mino の個数
  final double _thresholdSecForDropMino = 1.0; // ミノが落下するまでの秒数
  final double _thresholdSecForFixCurrentMino = 0.5; // ミノが固定されるまでの秒数
  final int _limitTimeSec = 180; // 制限時間(秒)

  int remainingTime = 0; // 残り時間
  int remainingTimeSec = 0; // 残り時間 秒の部分
  int remainingTimeMin = 0; // 残り時間 分の部分

  int _frameCountForDropMino = 0;
  int _frameCountForFixCurrentMino = 0;

  List<MinoType> _minoOrderList = [];
  int _minoOrderIndex = 0;

  List<MinoType> minoTypeInNextList = List.filled(6, MinoType.None);
  MinoType minoTypeInHold;
  int countDownNum = 3;
  int deletedLinesCount = 0;
  int deletedLinesCountBest = 0;

  MinoType _currentMinoType = MinoType.None;
  MinoAngle _currentMinoAngle = MinoAngle.Rot_000;
  int _currentMinoXPos = 0;
  int _currentMinoYPos = 0;

  List<Point> currentMino = [];
  List<Point> futureMino = [];
  List<Point> fixedMino = [];

  bool usedHold = false;
  bool gameOver = false;
  bool _currentMinoIsGrounding = false; //  Mino が接地しているか
  bool _minoIsMoving = false; //  Mino が動いたか

  /// 初期化処理
  void initialize() {
    gameOver = false;
    usedHold = false;
    _minoOrderIndex = 0;
    _frameCountForDropMino = 0;
    _frameCountForFixCurrentMino = 0;
    minoTypeInNextList = List.filled(6, MinoType.None);
    minoTypeInHold = MinoType.None;
    deletedLinesCount = 0;
    countDownNum = _countDownStartNum;
    remainingTime = _limitTimeSec;
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

  /// このmodelが廃棄されるときに呼ばれる
  @override
  void dispose() {
    super.dispose();
    initialize();
    gameOver = true;
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

  /// frameごとに処理を実行する
  Future<void> mainLoop(int fps) async {
    /// 初期化処理
    initialize();
    // ベストスコアを取り出す
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    deletedLinesCountBest = prefs.get('deletedLinesCountBest') ?? 0;
    //  Mino の順番を予め生成する
    _generateMinoOrderList();
    await _countDown();

    /// メインループ
    final sw = Stopwatch()..start();
    int frame = 0; // フレーム番号
    // gameOverになるまでループし続ける
    while (!gameOver) {
      frame++;

      ///  Mino が接地していないなら1秒後に落下させる
      if (!_currentMinoIsGrounding) {
        _frameCountForDropMino++;
        final int _thresholdFrameForDropMino =
            (fps * _thresholdSecForDropMino).toInt();
        if (_frameCountForDropMino % _thresholdFrameForDropMino == 0) {
          moveMino(0, 1); // ミノを1行下げる
        }
        _frameCountForFixCurrentMino = 0;
      } else {
        /// 以下の条件を満たすとき Mino を固定する
        /// 1:  Mino が接地している
        /// 2: 0.5秒間プレイヤーの操作がない ( minoIsMoving が false )
        if (!_minoIsMoving) {
          _frameCountForFixCurrentMino++;
          final _thresholdFrameForFixCurrentMino =
              (fps * _thresholdSecForFixCurrentMino).toInt();
          if (_frameCountForFixCurrentMino % _thresholdFrameForFixCurrentMino ==
              0) {
            _fixCurrentMino();
            _deleteLine();
            _checkGameOver();
            _generateMino();
          }
        } else {
          _frameCountForFixCurrentMino = 0;
          _minoIsMoving = false;
        }
        _frameCountForDropMino = 0;
      }

      /// 残り時間を減らす
      if (frame % fps == 0) {
        remainingTime--;
        remainingTimeMin = remainingTime ~/ 60;
        remainingTimeSec = remainingTime % 60;
      }

      /// 時間切れ
      if (remainingTime == 0) {
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

  /// 新しい Mino を生成する
  void _generateMino() {
    _currentMinoType = _minoOrderList[_minoOrderIndex];
    _currentMinoAngle = MinoAngle.Rot_000;
    _currentMinoXPos = 0;
    _currentMinoYPos = 0;
    usedHold = false;
    _updateCurrentMino();

    _minoOrderIndex++;
    // Nextミノを更新する
    for (int i = 0; i < minoTypeInNextList.length; i++) {
      minoTypeInNextList[i] = _minoOrderList[(_minoOrderIndex + i)];
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
    _findDropPos(); // 落下位置の取得
    _checkCurrentMinoIsGrounding(); // 接地判定

    _minoIsMoving = true;
    notifyListeners();
  }

  /// currentMino を固定する
  void _fixCurrentMino() {
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

  /// ラインを消去する
  /// fixedMinoが横一列に並んだときに消去する
  void _deleteLine() {
    // 各列で 10 個 point が存在する列を消す
    // 長さ 20 の 0 詰めしたリストに個数を格納していく
    // pointCountList[n]　=  n 列目に存在する point の個数
    List<int> pointCountList = List.filled(20, 0);
    for (final Point point in fixedMino) {
      if (point.y >= 0 && point.y < 20) {
        pointCountList[point.y]++;
      }
    }
    for (int index = 0; index < pointCountList.length; index++) {
      if (pointCountList[index] == 10) {
        deletedLinesCount++;
        // 行を削除
        fixedMino.removeWhere((point) => point.y == index);
        // indexより上の行に存在する point を1行下げる
        for (int i = 0; i < fixedMino.length; i++) {
          if (fixedMino[i].y < index) {
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
    // currentMinoを更新する
    if (!_onCollisionEnter(tmpMino)) {
      _currentMinoXPos += dx;
      _currentMinoYPos += dy;
      _updateCurrentMino();
      return true;
    } else {
      return false;
    }
  }

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

    /// 回転したとき他の障害部に当たった場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.I_Mino) {
        // angleで分岐
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
        // angleで分岐
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
    }
    _updateCurrentMino();
  }

  /// 反時計回りに90度回転
  void rotateAntiClockwise() {
    final MinoAngle tmpAngle = _currentMinoAngle; // 回転前の角度を一時的に保持する
    _currentMinoAngle =
        MinoAngle.values[(_currentMinoAngle.index + 1) % 4]; // 反時計回りに270度回転と同義
    final List<Point> tmpMino = Mino.getMino(
      minoType: _currentMinoType,
      minoAngle: _currentMinoAngle,
      dx: _currentMinoXPos,
      dy: _currentMinoYPos,
    );

    /// 回転したとき他の障害部に当たった場合
    /// SRS(スーパーローテーションシステム)に従い Mino を移動させる
    /// 参考: https://tetrisch.github.io/main/srs.html
    if (_onCollisionEnter(tmpMino)) {
      /// I_Mino の場合
      if (_currentMinoType == MinoType.I_Mino) {
        // angleで分岐
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
        // angleで分岐
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
    }
    _updateCurrentMino();
  }

  /// 下フリック操作で一気に Mino を落下させる
  hardDrop() {
    currentMino = [...futureMino];
    _fixCurrentMino();
    _deleteLine();
    _checkGameOver();
    _generateMino();
  }

  holdMino() {
    // Minoが生成されてからまだ一度も hold が使われていない場合
    if (!usedHold) {
      MinoType tmpMinoType = _currentMinoType;

      /// すでに Hold されている Mino がある場合
      if (minoTypeInHold != MinoType.None) {
        _currentMinoType = minoTypeInHold;
        minoTypeInHold = tmpMinoType;
        _currentMinoAngle = MinoAngle.Rot_000;
        _currentMinoXPos = 0;
        _currentMinoYPos = 0;
        _updateCurrentMino();

        /// まだ一度も Hold していない場合
      } else {
        minoTypeInHold = tmpMinoType;
        _generateMino();
      }

      usedHold = true;
    }
  }
}
