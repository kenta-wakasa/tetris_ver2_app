import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'play_model.dart';
import 'render_hold.dart';
import 'render_next.dart';
import 'render_mino.dart';
import 'start_page.dart';

class PlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// ジェスチャー操作で使用する変数を定義
    final _size = MediaQuery.of(context).size;
    final _centerPos = _size.width / 2;
    final _dragThreshold = 20;
    final _flickThreshold = 30;
    final fps = 30;
    double _deltaLeft = 0;
    double _deltaRight = 0;
    double _deltaDown = 0;
    bool _usedHardDrop = false;
    bool _usedHold = false;

    return ChangeNotifierProvider<PlayModel>(
      create: (_) => PlayModel()..mainLoop(fps),
      child: Consumer<PlayModel>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
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

                  /// タップ時に初期化
                  onPanDown: (_) {
                    _usedHardDrop = false;
                    _usedHold = false;
                    _deltaRight = 0;
                    _deltaLeft = 0;
                    _deltaDown = 0;
                  },

                  /// タップで回転処理
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

                /// 描画部分
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// HOLDの描画
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOLD'),
                            CustomPaint(
                              painter: RenderHold(
                                usedHold: model.usedHold,
                                minoTypeInHold: model.minoTypeInHold,
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
                            Text(""),
                            CustomPaint(
                              painter: RenderMino(
                                currentMino: model.currentMino,
                                futureMino: model.futureMino,
                                fixedMino: model.fixedMino,
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
                            Text('NEXT'),
                            CustomPaint(
                              painter: RenderNext(
                                minoTypeInNextList: model.minoTypeInNextList,
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
                                ? "${model.countDownNum}"
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
                      Text(
                        "TIME    " +
                            model.remainingTimeMin.toString() +
                            ":" +
                            model.remainingTimeSec.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          fontFeatures: [FontFeature.tabularFigures()], // 等幅になる
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        "LINES " +
                            model.deletedLinesCount.toString().padLeft(4, '0'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        "BEST  " +
                            model.deletedLinesCountBest
                                .toString()
                                .padLeft(4, '0'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(
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
                              Text(
                                'Game Over',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 36),
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Text(
                                '${model.deletedLinesCount}ライン達成!!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 24),
                              ),
                              SizedBox(
                                height: 240,
                              ),
                              SizedBox(
                                width: 240,
                                child: RaisedButton(
                                  color: Colors.redAccent,
                                  child: Text(
                                    'もう一度あそぶ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                width: 240,
                                child: RaisedButton(
                                  color: Colors.redAccent,
                                  child: Text(
                                    'タイトル画面にもどる',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StartPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
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
