// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutterapp/spherize_widget.dart';
import 'package:latlong/latlong.dart';
import 'map_management.dart';
import 'sphere_git.dart';
import 'package:flutter/painting.dart' as painting;
import 'dart:math';
//import "map_widget.dart";
//import "spherize_widget.dart";

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
//      home: CustomPaint(painter: VertexPainter(), child: Container()),
//    );
//        home: Sphere(
//          surface: 'assets/images/WorldMap.jpg',
//          radius: 180,
//          latitude: 0,
//          longitude: 0,
//        ));
  }
}

class VertexPainter extends CustomPainter {
  VertexPainter();

  @override
  void paint(Canvas canvas, Size size) {
    print("Painted");
    int vertexCount = 3;
    Float32List vertexList = Float32List(vertexCount * 2);
    vertexList[0] = 0;
    vertexList[1] = 0;
    vertexList[2] = 0;
    vertexList[3] = size.height;
    vertexList[4] = size.width;
    vertexList[5] = size.height;

    Int32List rgbaList = Int32List(vertexCount);
    rgbaList[0] = Color.fromARGB(0, 255, 255, 255).value;
    rgbaList[1] = Color.fromARGB(255, 255, 255, 255).value;
    rgbaList[2] = Color.fromARGB(0, 255, 255, 255).value;

//    Float32List texCoords = Float32List(vertexCount * 2);
//    texCoords[0] = 1;
//    texCoords[1] = 2;
//    texCoords[2] = 3;
//    texCoords[3] = 4;
//    texCoords[4] = 5;
//    texCoords[5] = 6;

    var gradient = RadialGradient(
      center: const Alignment(0.7, -0.6),
      radius: 0.2,
      colors: [const Color(0xFFFFFF00), const Color(0xFF0099FF)],
      stops: [0.4, 1.0],
    );

    final vertices =
        Vertices.raw(VertexMode.triangles, vertexList, colors: rgbaList);

    canvas.drawVertices(vertices, BlendMode.src, Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SphereMap extends StatefulWidget {
  SphereMap({Key key}) : super(key: key);

  @override
  _SphereMapState createState() => _SphereMapState();
}

class _SphereMapState extends State<SphereMap> {
  GlobalKey globalKey = GlobalKey();
//  Spherize spherize;
  bool hasStarted = false;

  void initState() {
    super.initState();
  }

  void TapCallback(LatLng point) {
    print("Tapped! at " + point.toString());
  }

  void LongPressCallback(LatLng point) {
    print("Long pressed! at " + point.toString());
  }

  @override
  Widget build(BuildContext context) {
//    MapManager manager = MapManager(LatLng(51.870170, -2.245810));

    return new FutureBuilder(
        future: loadAssetImages(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, ui.Image>> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            print("#### Assets Loaded ####");
            print(
                "Does map contain data? " + (snapshot.data != null).toString());
            print("Does map contain overlay image? " +
                (snapshot.data["earth_overlay"] != null).toString());
            return FlutterMap(
              options: new MapOptions(
                  center: new LatLng(51.864703, -2.245356),
                  zoom: 12.0,
                  onTap: TapCallback,
                  onLongPress: LongPressCallback,
                  zoomSphereLevel: 12.0,
                  zoomUnSphereLevel: 16.0),
              layers: [
                new TileLayerOptions(
//                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//            urlTemplate:
//                "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.jpg90?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//                        urlTemplate: "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.png100?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
//            urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/naoh1/ckc2i7x1o04a61ip84c8zpnx1/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmFvaDEiLCJhIjoiY2tiZHR5NHdhMGZjaTJyczcyeG45djIzaCJ9.TWAMfj-G7lGxM0WSQOGUnA",
                    subdomains: ['a', 'b', 'c'],
                    assetImages: snapshot.data),
                new MarkerLayerOptions(
                  markers: [
                    new Marker(
                      width: 80.0,
                      height: 80.0,
                      point: new LatLng(51.870170, -2.245810),
                      builder: (ctx) => new Container(),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Container();
          }
        });
  }
}
