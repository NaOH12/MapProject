import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/src/spherize_tiles.dart';
import 'art_placer.dart';
import 'sphere_map.dart';

GlobalKey<SphereMapState> sphereMapKey = GlobalKey();

class HomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadAssetImages(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, ui.Image>> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return HomeScaffold(snapshot.data, MediaQuery.of(context));
          } else {
            return Container();
          }
        });
  }
}

class HomeScaffold extends StatefulWidget {
  final Map<String, ui.Image> imageAssets;
  final MediaQueryData queryData;
  HomeScaffold(this.imageAssets, this.queryData);

  @override
  _HomeScaffoldState createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold>
    with TickerProviderStateMixin {
  int _prevNavIndex = 1;
  int _navIndex = 2;
  double _navBackgroundOpacity = 0.0;

  AnimationController _navChangeController;
  Animation _navChangeAnimation;

  void initState() {
    super.initState();
    _navChangeController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(_handleNavChangeTransition);
  }

  void setNavIndex(int index) {
    _prevNavIndex = _navIndex;
    if (_navIndex == 1 && index == 2) {
      sphereMapKey.currentState.beginDrawMode();
    } else if (_navIndex == 2 && index == 1) {
      sphereMapKey.currentState.beginSphereMode();
    }

    _startMapMoveAnimation(index);

    _navIndex = index;
  }

  void _handleNavChangeTransition() {
    setState(() {
      _navBackgroundOpacity = _navChangeAnimation.value;
    });
  }

  void _startMapMoveAnimation(int newIndex) {
    var targetVal = (newIndex == 1) ? 0.0 : 1.0;
    _navChangeAnimation =
        Tween<double>(begin: _navBackgroundOpacity, end: targetVal)
            .chain(CurveTween(curve: Curves.fastOutSlowIn))
            .animate(_navChangeController);
    _navChangeController
      ..value = _navBackgroundOpacity
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
//        SphereMap(widget.imageAssets, MediaQuery.of(context)),
        (_navIndex == 0)
            ? Container(
                child: Text("PROFILE"),
                color: Colors.white,
                width: widget.queryData.size.width,
                height: widget.queryData.size.height,
              )
            : Stack(children: [
                SphereMap(
                  widget.imageAssets,
                  widget.queryData,
                  (_navIndex == 1),
                  key: sphereMapKey,
                ),
                (_navIndex == 2)
                    ? ArtPlacer(widget.queryData)
                    : Container(),
              ]),
        Align(
          alignment: FractionalOffset.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(
                        (_navBackgroundOpacity * 255).toInt(), 70, 120, 131),
                    Color.fromARGB(
                        (_navBackgroundOpacity * 255).toInt(), 40, 95, 131)
                  ]),
//              color: Color.fromARGB(
//                  (_navBackgroundOpacity * 255).toInt(), 50, 50, 50),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: 10, top: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      setNavIndex(0);
                    });
                  },
                  child: _navIndex == 0
                      ? ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.0,
                              colors: <Color>[
                                Colors.orange[400],
                                Colors.blue[200]
                              ],
                              tileMode: TileMode.mirror,
                            ).createShader(bounds);
                          },
                          child: Icon(Icons.person, size: 30),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white70,
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      setNavIndex(1);
                    });
                  },
                  child: _navIndex == 1
                      ? ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return RadialGradient(
                              center: Alignment.bottomLeft,
                              radius: 1,
                              stops: [
                                0.5,
                                1.0,
                              ],
                              colors: <Color>[
                                Colors.greenAccent[400],
                                Colors.blueAccent[200]
                              ],
//                              tileMode: TileMode.mirror,
                            ).createShader(bounds);
                          },
                          child: Icon(Icons.language, size: 50),
                        )
                      : Icon(
                          Icons.language,
                          size: 50,
                          color: Colors.white70,
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      setNavIndex(2);
                    });
                  },
                  child: _navIndex == 2
                      ? ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return RadialGradient(
                              center: Alignment.bottomLeft,
                              radius: 1.0,
                              colors: <Color>[
                                Colors.orangeAccent[400],
                                Colors.brown[200]
                              ],
                              tileMode: TileMode.mirror,
                            ).createShader(bounds);
                          },
                          child: Icon(Icons.brush, size: 30),
                        )
                      : Icon(
                          Icons.brush,
                          size: 30,
                          color: Colors.white70,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _navChangeController.dispose();
    super.dispose();
  }
}