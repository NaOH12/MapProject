import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:flutterapp/post_data/post.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:flutterapp/gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'map_ui.dart';

class ArtPlacer extends StatefulWidget {
  MediaQueryData queryData;
  ArtPlacer(this.queryData);

  _ArtPlacerState createState() => _ArtPlacerState();
}

class _ArtPlacerState extends State<ArtPlacer> {
  bool _isPlacingTextArt = false;
  bool _isEditingText = false;
//  TextArtPost _textArtPost;
  FocusNode _inputFocusNode = FocusNode();
  KeyboardVisibilityNotification _keyboardVisibility =
      new KeyboardVisibilityNotification();
  int _keyboardVisibilitySubscriberId;

  String _text = "EXAMPLE TEXT";
  Color _colour = HSVColor.fromAHSV(1.0, 0, 1.0, 0.8).toColor();
  double _hue = 0.0;
  Matrix4 _matrix;
  Matrix4 _default;

  List<Color> _sliderColours = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 128, 0),
    Color.fromARGB(255, 255, 255, 0),
    Color.fromARGB(255, 128, 255, 0),
    Color.fromARGB(255, 0, 255, 0),
    Color.fromARGB(255, 0, 255, 128),
    Color.fromARGB(255, 0, 255, 255),
    Color.fromARGB(255, 0, 128, 255),
    Color.fromARGB(255, 0, 0, 255),
    Color.fromARGB(255, 127, 0, 255),
    Color.fromARGB(255, 255, 0, 255),
    Color.fromARGB(255, 255, 0, 127),
    Color.fromARGB(255, 128, 128, 128),
  ];

  @override
  void initState() {
    super.initState();
    reset();
    _keyboardVisibilitySubscriberId =
        _keyboardVisibility.addNewListener(onHide: () {
      if (_isEditingText) {
        setState(() {
          togglePlacingTextArt();
        });
      }
    });
  }

  void toggleTextEdit() {
    _isPlacingTextArt = true;
    _isEditingText = true;
  }

  void togglePlacingTextArt() {
    _isPlacingTextArt = true;
    _isEditingText = false;
  }

  void placement() {
//    c*scale	-skew		0		    dx
//    skew 		c*scale 0		    dy
//    0 		  0 		  1		    0
//    0		    0		    0	      1
    var scale = _matrix.row0.x;
    var skew = _matrix.row1.x;
    Offset offset = Offset(_matrix.row0.w, _matrix.row1.w);
    sphereMapKey.currentState
        .placeText(_matrix, offset, _text, _colour.value, scale, skew);
  }

  void reset() {
    _isPlacingTextArt = false;
    _isEditingText = false;

    _default = Matrix4.identity();
    _default.translate(10.0, widget.queryData.size.height / 2.0, 0);
    _matrix = _default;

//    _translation = _default.getTranslation();
  }

  @override
  Widget build(BuildContext context) {
    return ((!_isPlacingTextArt)
        ? SafeArea(
            child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 25, right: 25),
                  child: GestureDetector(
                    onTap: () => {
                      setState(() {
                        togglePlacingTextArt();
                      })
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 40, 95, 131),
                      ),
                      child: Icon(
                        Icons.text_fields,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ))
        : Container(
            color: Colors.black54,
            child: Stack(
              children: <Widget>[
                ((_isEditingText)
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_inputFocusNode.hasPrimaryFocus) {
                              _inputFocusNode.unfocus();
                            }
                            togglePlacingTextArt();
                          });
                        },
                        child: Container(
                            color: Colors.transparent,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            alignment: Alignment.bottomCenter,
                            child: Container(
//                                    color: Colors.black54,
                                height:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        50,
                                width: MediaQuery.of(context).size.width,
                                child: Material(
                                    child: TextFormField(
                                  focusNode: _inputFocusNode,
                                  textAlign: TextAlign.center,
                                  initialValue: _text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      .apply(
                                        color: _colour,
                                      ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (String val) {
                                    _text = val;
                                  },
                                  onEditingComplete: () {
                                    setState(() {
                                      togglePlacingTextArt();
                                    });
                                  },
                                )))),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            toggleTextEdit();
                            _inputFocusNode.requestFocus();
                          });
                        },
                        child: MatrixGestureDetector(
                            initMatrixPos: _matrix,
                            shouldRotate: true,
                            shouldScale: true,
                            onMatrixUpdate:
                                (Matrix4 m, var tm, var sm, var rm) {
                              setState(() {
//                                  _matrix = m;
                                _matrix = m;
//                                  print(_matrix.getMaxScaleOnAxis());
//                                  _translation = tm;
//                                  _scale+= sm;
//                                  print(m.row3.x.toString() + "\n" + m.row3.y.toString() + "\n" + m.row3.z.toString() + "\n" + m.row3.w.toString() + "\n");
//                                  _rotation = rm;
                              });
                            },
                            child: Container(
                                color: Colors.transparent,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                child: Transform(
                                    transform: _matrix,
                                    child: Text(_text,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6
                                            .apply(
                                                color: _colour,
                                                fontSizeDelta: 1))))))),
                SafeArea(
                    child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 25, right: 25),
                        child: GestureDetector(
                          onTap: () => {
                            setState(() {
                              reset();
                            })
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 40, 95, 131),
                            ),
                            child: Icon(
                              Icons.clear,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 25, right: 25),
                        child: GestureDetector(
                          onTap: () => {
                            setState(() {
                              placement();
                              reset();
                            })
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 40, 95, 131),
                            ),
                            child: Icon(
                              Icons.done,
                              color: Colors.greenAccent,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                            padding: EdgeInsets.only(top: 25, right: 25),
                            child: Container(
                              color: Colors.transparent,
                              width: 40,
                              height: 200,
                              alignment: Alignment.center,
                              child: FlutterSlider(
                                values: [_hue],
                                min: 0,
                                max: 360,
                                axis: Axis.vertical,
                                tooltip: FlutterSliderTooltip(
                                  disabled: true,
                                ),
                                trackBar: FlutterSliderTrackBar(
                                  centralWidget: Container(
                                      width: 22,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: _sliderColours,
                                          ))),
                                  activeTrackBar: BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  inactiveTrackBar: BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  activeTrackBarHeight: 22,
                                  inactiveTrackBarHeight: 22,
                                ),
                                handler: FlutterSliderHandler(
                                  decoration:
                                      BoxDecoration(color: Colors.transparent),
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      color: _colour,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                  ),
                                ),
                                onDragging:
                                    (handlerIndex, lowerValue, upperValue) {
                                  setState(() {
                                    _hue = lowerValue;
                                    _colour =
                                        HSVColor.fromAHSV(1.0, _hue, 1.0, 0.8)
                                            .toColor();
                                  });
                                },
                              ),
                            )))
                  ],
                ))
              ],
            )));
  }

  @override
  void dispose() {
    _keyboardVisibility.removeListener(_keyboardVisibilitySubscriberId);
    _inputFocusNode.dispose();
    super.dispose();
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
