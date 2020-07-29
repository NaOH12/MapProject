import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/spherize_tiles.dart';
import '../ui_elements.dart';
import 'package:latlong/latlong.dart';
import 'package:user_location/user_location.dart';

class SphereMapPage extends StatelessWidget {
  Widget build(BuildContext context) {

    return FutureBuilder(
        future: loadAssetImages(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, ui.Image>> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return SphereMap(snapshot.data);
          } else {
            return Container();
          }
        });
  }
}

class SphereMap extends StatefulWidget {
  final Map<String, ui.Image> imageAssets;
  SphereMap(this.imageAssets, {Key key}) : super(key: key);

  @override
  _SphereMapState createState() => _SphereMapState();
}

class _SphereMapState extends State<SphereMap> with TickerProviderStateMixin {
  MapController mapController = new MapController();
  List<Marker> markers = [];
  UserLocationOptions userLocationOptions;

  AnimationController _doubleTapController;
  Animation _doubleTapZoomAnimation;
  Animation _doubleTapCenterAnimation;

  final double zoomSphereLevel = 12.0;
  final double zoomUnSphereLevel = 15.0;

  void initState() {
    super.initState();
    _doubleTapController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(_handleMapMoveAnimation);
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

  void placeMarkerAtCurentPos() {
    placeMarker(mapController.center);
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
        builder: (context) {
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
        builder: (context) {
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
        curvedTextBox(inputWidth - (spacing * 3), barHeight),
        sendButton(buttonWidth, barHeight, placeMarkerAtCurentPos),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var query = MediaQuery.of(context);
    var size = query.size;
    final double scaleFactor = 0.5;
    var spherize =
        Spherize(size.width.toInt(), size.height.toInt(), scaleFactor);
    var bottomPos = query.viewInsets.bottom;

    userLocationOptions = UserLocationOptions(null,
        context: context,
        mapController: mapController,
        markers: markers,
        onLocationUpdate: (LatLng pos) =>
            print("onLocationUpdate ${pos.toString()}"),
        updateMapLocationOnPositionChange: false,
        showMoveToCurrentLocationFloatingActionButton: false,
        zoomToCurrentLocationOnLoad: false,
        fabBottom: 50,
        fabRight: 50,
        verbose: false,
        onTapFAB: onTapFAB);

    return Material(
        child: Stack(children: [
      FlutterMap(
        options: new MapOptions(
          spherize,
          center: new LatLng(51.864703, -2.245356),
          zoom: 12.0,
          onTap: TapCallback,
          onLongPress: LongPressCallback,
          zoomSphereLevel: zoomSphereLevel,
          zoomUnSphereLevel: zoomUnSphereLevel,
          plugins: [
            UserLocationPlugin(),
          ],
        ),
        layers: [
          new TileLayerOptions(widget.imageAssets, spherize,
//                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//            urlTemplate:
//                "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.jpg90?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//                        urlTemplate: "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.png100?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//            urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
              urlTemplate:
                  "https://api.mapbox.com/styles/v1/naoh1/ckc2i7x1o04a61ip84c8zpnx1/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
              subdomains: ['a', 'b', 'c']),
          new MarkerLayerOptions(spherize, markers: markers),
          userLocationOptions,
        ],
        mapController: mapController,
      ),
//      Positioned(child: curvedTextBox(), ),
      Positioned(
        child: buildMessageBar(size.width, size.height, 47, 47, 5),
        left: 5,
        right: 5,
        bottom: bottomPos + 5,
      ),
//      Align(alignment: Alignment.bottomCenter, child: curvedTextBox()),
    ]));
  }
}
