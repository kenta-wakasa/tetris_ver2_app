import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'play_model.dart';
import 'render_hold.dart';
import 'render_next.dart';
import 'start_page.dart';
import 'render_mino.dart';

class PlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    final _centerPos = _size.width / 2;
    final _dragThreshold = 20;
    final _flickThreshold = 30;
    double _deltaLeft = 0;
    double _deltaRight = 0;
    double _deltaDown = 0;
    bool _hardDrop = false;
    bool _holdMino = false;
    return ChangeNotifierProvider<PlayModel>(
      create: (_) => PlayModel(),
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
                // タップでミノの回転
                // ドラッグでミノの移動
                // 下フリックでHardDrop
                // 上フリックでHoldMino
                GestureDetector(
                  // ドラッグのスタートをタップした直後に設定
                  dragStartBehavior: DragStartBehavior.down,

                  /// タップ時に初期化
                  onPanDown: (_) {
                    _hardDrop = false;
                    _holdMino = false;
                    _deltaRight = 0;
                    _deltaLeft = 0;
                    _deltaDown = 0;
                  },

                  /// 回転処理
                  onTapUp: (details) {
                    if (details.globalPosition.dx < _centerPos) {
                      model.rotateLeft();
                    } else {
                      model.rotateRight();
                    }
                  },

                  onPanUpdate: (details) {
                    // ドラッグした長さを足し込み閾値を超えると移動する
                    /// 左右移動
                    if (details.delta.dx > 0) {
                      _deltaRight += details.delta.dx;
                      if (_dragThreshold < _deltaRight) {
                        model.moveRight();
                        _deltaRight = 0;
                      }
                    } else {
                      _deltaLeft += details.delta.dx.abs();
                      if (_dragThreshold < _deltaLeft) {
                        model.moveLeft();
                        _deltaLeft = 0;
                      }
                    }

                    /// soft drop 処理
                    if (details.delta.dy > 0) {
                      _deltaDown += details.delta.dy;
                      if (_dragThreshold < _deltaDown && !_hardDrop) {
                        if (model.wait) {
                        } else {
                          model.moveDown();
                        }
                        _deltaDown = 0;
                      }
                    }

                    /// hard drop 処理
                    if (_flickThreshold < details.delta.dy && !_hardDrop) {
                      _hardDrop = true;
                      _deltaDown = 0;
                      model.hardDrop();
                    }

                    /// hold 処理
                    if (-(_flickThreshold) > details.delta.dy && !_holdMino) {
                      _holdMino = true;
                      _deltaDown = 0;
                      model.holdMino();
                    }
                  },
                  child: Container(
                    color: Colors.white.withOpacity(0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOLD'),
                            CustomPaint(
                              painter: RenderHold(
                                usedHold: model.usedHold,
                                indexHold: model.indexHold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Text(''),
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
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEXT'),
                            CustomPaint(
                              painter: RenderNext(
                                nextMinoList: model.nextMinoList,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        model.countDeletedLine.toString(),
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 80,
                      ),
                    ],
                  ),
                ),
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
                                '${model.countDeletedLine}ライン達成!!',
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
                                    model.reset();
                                    model.countDown();
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
                                    model.reset();
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
                model.count > -1
                    ? Container(
                        color: Colors.brown.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            model.count != 0 ? model.count.toString() : 'GO!!',
                            style: TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[900],
                            ),
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
