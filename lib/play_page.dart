import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'play_model.dart';
import 'render_hold.dart';
import 'render_mino.dart';
import 'render_next.dart';
import 'start_page.dart';

class PlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// ジェスチャー操作で使用する変数を定義
    final _size = MediaQuery.of(context).size;
    final _centerPos = _size.width / 2;
    const _dragThreshold = 20;
    const _flickThreshold = 30;
    const fps = 30;
    var _deltaLeft = 0.0;
    var _deltaRight = 0.0;
    var _deltaDown = 0.0;
    var _usedHardDrop = false;
    var _usedHold = false;

    return ChangeNotifierProvider<PlayModel>(
      create: (_) => PlayModel()..mainLoop(fps),
      child: Consumer<PlayModel>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'TETRIS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Stack(
              children: [
                /// ジェスチャーによるミノの操作
                GestureDetector(
                  // ドラッグのスタートをタップした直後に設定
                  dragStartBehavior: DragStartBehavior.down,

                  /// タップダウン時に初期化
                  onPanDown: (_) {
                    _usedHardDrop = false;
                    _usedHold = false;
                    _deltaRight = 0.0;
                    _deltaLeft = 0.0;
                    _deltaDown = 0.0;
                  },

                  /// タップアップで 回転処理
                  /// 左側をタップで 反時計回り回転
                  /// 右側をタップで 時計回り回転
                  onTapUp: (details) {
                    if (details.globalPosition.dx < _centerPos) {
                      model.rotateAntiClockwise();
                    } else {
                      model.rotateClockwise();
                    }
                  },

                  onPanUpdate: (details) {
                    // ドラッグした長さを足し込み閾値を超えると移動する
                    /// ドラッグで左右移動
                    if (details.delta.dx > 0) {
                      _deltaRight += details.delta.dx;
                      if (_dragThreshold < _deltaRight) {
                        model.moveMino(1, 0);
                        _deltaRight = 0;
                      }
                    } else {
                      _deltaLeft += details.delta.dx.abs();
                      if (_dragThreshold < _deltaLeft) {
                        model.moveMino(-1, 0);
                        _deltaLeft = 0;
                      }
                    }

                    /// 下方向ドラッグで soft drop 処理
                    if (details.delta.dy > 0) {
                      _deltaDown += details.delta.dy;
                      if (_deltaDown > _dragThreshold && !_usedHardDrop) {
                        model.moveMino(0, 1);
                        _deltaDown = 0;
                      }
                    }

                    /// 下フリックで hard drop 処理
                    if (details.delta.dy > _flickThreshold && !_usedHardDrop) {
                      _usedHardDrop = true;
                      _deltaDown = 0;
                      model.hardDrop();
                    }

                    /// 上フリックで hold 処理
                    if (-details.delta.dy > _flickThreshold && !_usedHold) {
                      _usedHold = true;
                      _deltaDown = 0;
                      model.holdMino();
                    }
                  },
                  child: Container(
                    color: Colors.white.withOpacity(0),
                  ),
                ),

                /// 残り時間の表示
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: _size.width,
                    child: Text(
                      // ignore: lines_longer_than_80_chars
                      'TIME    ${model.remainingTimeMin}:${model.remainingTimeSec.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        fontFeatures: [FontFeature.tabularFigures()], // 等幅になる
                      ),
                    ),
                  ),
                ),

                /// Mino の描画
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// HOLDの描画
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HOLD'),
                            CustomPaint(
                              painter: RenderHold(
                                usedHold: model.usedHold,
                                holdMinoType: model.holdMinoType,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Playエリアの描画
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(''),
                            CustomPaint(
                              painter: RenderMino(
                                currentMino: model.currentMino,
                                futureMino: model.futureMino,
                                frozenMino: model.frozenMino,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// NEXTの描画
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NEXT'),
                            CustomPaint(
                              painter: RenderNext(
                                nextMinoTypeList: model.nextMinoTypeList,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// カウントダウン画面
                model.countDownNum > -1
                    ? Container(
                        color: Colors.brown.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            // 0以外なら数字を 0ならGO!! を表示
                            model.countDownNum != 0
                                ? '${model.countDownNum}'
                                : 'GO!!',
                            style: TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[900],
                            ),
                          ),
                        ),
                      )
                    : Container(),

                /// 消したラインの数を表示
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        // ignore: lines_longer_than_80_chars
                        'LINES ${model.deletedLinesCount.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        // ignore: lines_longer_than_80_chars
                        'BEST  ${model.deletedLinesCountBest.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                    ],
                  ),
                ),

                /// GameOver画面
                model.gameOver
                    ? Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          color: Colors.brown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Game Over',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 36),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Text(
                                '${model.deletedLinesCount}ライン達成!!',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 24),
                              ),
                              const SizedBox(
                                height: 240,
                              ),
                              SizedBox(
                                width: 240,
                                child: RaisedButton(
                                  color: Colors.redAccent,
                                  child: const Text(
                                    'もう一度あそぶ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement<void, void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                width: 240,
                                child: RaisedButton(
                                  color: Colors.redAccent,
                                  child: const Text(
                                    'タイトル画面にもどる',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement<void, void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StartPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 56,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          );
        },
      ),
    );
  }
}
