// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutterapp/spherize_widget.dart';
import 'package:flutterapp/ui_elements.dart';
import 'package:latlong/latlong.dart';
import 'package:user_location/user_location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  ui.Image image;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Earth App',
        theme: new ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: SphereMap());
  }
}

class SphereMap extends StatefulWidget {
  SphereMap({Key key}) : super(key: key);

  @override
  _SphereMapState createState() => _SphereMapState();
}

class _SphereMapState extends State<SphereMap> {
  MapController mapController = new MapController();
  List<Marker> markers = [];
  StreamController<LatLng> markerlocationStream = StreamController();
  UserLocationOptions userLocationOptions;

  void initState() {
    super.initState();
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
//    mapController.move(new LatLng(51.864703, -2.245356), 12.0);
//    setState(() {
    markers.add(getMarker(point));
//    });
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var scaleFactor = 0.7;
    var spherize =
        Spherize(size.width.toInt(), size.height.toInt(), scaleFactor);

    userLocationOptions = UserLocationOptions(
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

    return new FutureBuilder(
        future: loadAssetImages(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, ui.Image>> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return Material(
                child: Stack(children: [
              FlutterMap(
                options: new MapOptions(
                  spherize,
                  center: new LatLng(51.864703, -2.245356),
                  zoom: 12.0,
                  onTap: TapCallback,
                  onLongPress: LongPressCallback,
                  zoomSphereLevel: 12.0,
                  zoomUnSphereLevel: 15.0,
                  plugins: [
                    UserLocationPlugin(),
                  ],
                ),
                layers: [
                  new TileLayerOptions(snapshot.data, spherize,
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

//                  markers: [
//                    new Marker(
//                      width: 80.0,
//                      height: 80.0,
//                      point: new LatLng(51.870170, -2.245810),
//                      builder: (ctx) => new Container(),
//                    ),
//                  ],
                ],
                mapController: mapController,
              ),
//              Align(
//                  alignment: Alignment.bottomCenter,
//                  child: curvedTextBox()),
            ]));
          } else {
            return Container();
          }
        });
  }
}
