import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/spherize_tiles.dart';
import 'package:flutterapp/network/api.dart';
import 'package:flutterapp/post_data/post.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_options.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_plugin.dart';
import '../ui_elements.dart';
import 'package:latlong/latlong.dart';

class SphereMap extends StatefulWidget {
  final Map<String, ui.Image> imageAssets;
  final MediaQueryData queryData;
  final bool isSphere;
  SphereMap(this.imageAssets, this.queryData, this.isSphere, {Key key})
      : super(key: key);

  @override
  SphereMapState createState() => SphereMapState();
}

class SphereMapState extends State<SphereMap> with TickerProviderStateMixin {
  MapController mapController = new MapController();
  List<Marker> markers = [];
//  UserLocationOptions _userLocationOptions;
  TileLayerOptions _tileLayerOptions;
  TileMarkerLayerOptions _tileMarkerLayerOptions;
  MarkerLayerOptions _markerLayerOptions;

  Network network = Network();

  AnimationController _doubleTapController;
  Animation _doubleTapZoomAnimation;
  Animation _doubleTapCenterAnimation;

  Size _size;
  Spherize _spherize;
  double _scaleFactor;

  final double zoomSphereLevel = 12.0;
  final double zoomUnSphereLevel = 16.0;

  String _textFieldData = "";

  // 0 -
  // 1 - sphere level map
  // 2 - graffiti level
  int _navBarIndex = 1;

  void initState() {
    super.initState();
    _doubleTapController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(_handleMapMoveAnimation);

    _size = widget.queryData.size;
    _scaleFactor = _size.width / _size.height;
    _spherize =
        Spherize(_size.width.toInt(), _size.height.toInt(), _scaleFactor);

//    _userLocationOptions = UserLocationOptions(null,
//        context: context,
//        mapController: mapController,
//        markers: markers,
//        onLocationUpdate: (LatLng pos) =>
//            print("onLocationUpdate ${pos.toString()}"),
//        updateMapLocationOnPositionChange: false,
//        showMoveToCurrentLocationFloatingActionButton: false,
//        zoomToCurrentLocationOnLoad: false,
//        fabBottom: 50,
//        fabRight: 50,
//        verbose: false,
//        onTapFAB: onTapFAB);

    _tileLayerOptions = TileLayerOptions(widget.imageAssets, _spherize, _size,
//                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//            urlTemplate:
//                "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.jpg90?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//                        urlTemplate: "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.png100?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//            urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
        urlTemplate:
            "https://api.mapbox.com/styles/v1/naoh1/ckc2i7x1o04a61ip84c8zpnx1/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
        subdomains: ['a', 'b', 'c']);
    _markerLayerOptions = MarkerLayerOptions(_spherize, markers: markers);
    _tileMarkerLayerOptions =
        TileMarkerLayerOptions(_spherize, updateInterval: 1000);
  }

  void beginSphereMode() {
    _startMapMoveAnimation(zoomSphereLevel, mapController.center);
  }

  void beginDrawMode() {
    _startMapMoveAnimation(zoomUnSphereLevel, mapController.center);
  }

  void placeText(Matrix4 matrix, Offset offset, String text, int colour,
      double scale, double skew) {

    Matrix4 m = Matrix4.identity();
    m.scale(2.0);
    m.rotateZ(1.5708);
    LatLng point = mapController.state.offsetToCrs(
        offset, widget.queryData.size.width, widget.queryData.size.height);
    print(scale);
    print(skew);
    setState(() {
      _markerLayerOptions.markers.add(Marker(
          point: point,
          width: 300,
          height: 100,
          builder: (context, widgetScale) => Container(
              child: Transform(
                  transform: Matrix4(scale, skew, 0, 0, -skew, scale, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),
                  child: Text(text,
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .apply(color: Color(colour), fontSizeDelta: 1.0))))));
    });
  }

  void _handleMapMoveAnimation() {
    setState(() {
      mapController.move(
        _doubleTapCenterAnimation.value,
        _doubleTapZoomAnimation.value,
      );
    });
  }

  void _startMapMoveAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation =
        Tween<double>(begin: mapController.zoom, end: newZoom)
            .chain(CurveTween(curve: Curves.fastOutSlowIn))
            .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: mapController.center, end: newCenter)
            .chain(CurveTween(curve: Curves.fastOutSlowIn))
            .animate(_doubleTapController);
    _doubleTapController
      ..value = 0.0
      ..forward();
  }

  void placeMarker(LatLng point) {
    setState(() {
      markers.add(getMarker(point));
    });
  }

  void placeMarkerAtCurentPos() async {
//    placeMarker(mapController.center);
    if (_textFieldData.length > 0) {
      await network
          .createPost(Post(0, _textFieldData, mapController.center, -1));
    }
  }

  void textFieldChange(String newText) {
    _textFieldData = newText;
  }

  onTapFAB() {
    print('Callback function has been called');
    //userLocationOptions.updateMapLocationOnPositionChange = true;
  }

  void TapCallback(LatLng point) {
    print("Tapped! at " + point.toString());
  }

  void LongPressCallback(LatLng point) {
    print("Long pressed! at " + point.toString());
    placeMarker(point);
  }

  Marker getMarker(LatLng point) {
    return Marker(
        point: point,
        width: 20,
        height: 20.0,
        builder: (context, scale) {
          return GestureDetector(
              onTap: () {
                print("POINT HAS BEEN CLICKED!");
                _startMapMoveAnimation(mapController.zoom, point);
              },
              child: Stack(alignment: AlignmentDirectional.center, children: [
                Container(
                  height: 20.0,
                  width: 20.0,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7)),
                ),
                Container(
                  height: 13.0,
                  width: 13.0,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[300].withOpacity(1)),
                ),
              ]));
        });
  }

  Marker getUserMarker() {
    var point =
        LatLng(mapController.center.latitude, mapController.center.longitude);
    return Marker(
        height: 20.0,
        width: 20.0,
        point: point,
        builder: (context, scale) {
          return GestureDetector(
              onTap: () {
                double newZoom;
                if (mapController.zoom == zoomSphereLevel) {
                  newZoom = zoomUnSphereLevel;
                } else {
                  newZoom = zoomSphereLevel;
                }
                _startMapMoveAnimation(newZoom, point);
              },
              child: Stack(alignment: AlignmentDirectional.center, children: [
                Container(
                  height: 20.0,
                  width: 20.0,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.7)),
                ),
                Container(
                  height: 13.0,
                  width: 13.0,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(1)),
                ),
              ]));
        });
  }

  Widget buildMessageBar(double width, double height, double buttonWidth,
      double barHeight, double spacing) {
    double inputWidth = width - buttonWidth;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        curvedTextBox(inputWidth - (spacing * 3), barHeight, textFieldChange),
        sendButton(buttonWidth, barHeight, placeMarkerAtCurentPos),
      ],
    );
  }

  Widget buildNavBar() {
//    return BottomNavigationBar(
//      items: const <BottomNavigationBarItem>[
//        BottomNavigationBarItem(
//          icon: Icon(Icons.person_outline),
//          title: Text(''),
//        ),
//        BottomNavigationBarItem(
//          icon: Icon(Icons.language),
//          title: Text(''),
//        ),
//        BottomNavigationBarItem(
//          icon: Icon(Icons.brush),
//          title: Text(''),
//        ),
//      ],
//      currentIndex: _navBarIndex,
//      selectedItemColor: Colors.amber[800],
//      onTap: (index)=>{setState(() {_navBarIndex = index;})},
//    );
  }

  @override
  Widget build(BuildContext context) {
//    var bottomPos = query.viewInsets.bottom;

    return Material(
        child: Stack(children: [
      FlutterMap(
        options: new MapOptions(
          _spherize,
          center: new LatLng(51.864703, -2.245356),
          zoom: widget.isSphere ? zoomSphereLevel : zoomUnSphereLevel,
          onTap: TapCallback,
          onLongPress: LongPressCallback,
          zoomSphereLevel: zoomSphereLevel,
          zoomUnSphereLevel: zoomUnSphereLevel,
          plugins: [
//            UserLocationPlugin(),
            TileMarkerPlugin(),
          ],
        ),
        layers: [
          _tileLayerOptions,
          _markerLayerOptions,
//          _userLocationOptions,
          _tileMarkerLayerOptions,
        ],
        mapController: mapController,
      ),
//      Positioned(child: curvedTextBox(), ),
//      Positioned(
////        child: buildMessageBar(size.width, size.height, 47, 47, 5),
//        child: buildNavBar(),
////        left: 5,
////        right: 5,
//        left: 0,
//        right: 0,
//        bottom: bottomPos// + 5,
//      ),
//      Align(alignment: Alignment.bottomCenter, child: curvedTextBox()),
    ]));
  }

  @override
  dispose() {
    _doubleTapController.dispose();
    super.dispose();
  }
}
