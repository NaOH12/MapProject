import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/src/spherize_tiles.dart';

typedef MarkerBuilder = Widget Function(
    BuildContext context, double scale);

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  final Spherize spherize;
  MarkerLayerOptions(this.spherize, {this.markers = const [], rebuild})
      : super(rebuild: rebuild);
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(height, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor.forPos(AnchorPos pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, null);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);
  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
  left,
  right,
  top,
  bottom,
  center,
}

class Marker {
  final LatLng point;
  final MarkerBuilder builder;
  final double width;
  final double height;
  final Anchor anchor;

  Marker({
    this.point,
    this.builder,
    this.width,
    this.height,
    AnchorPos anchorPos,
  }) : anchor = Anchor.forPos(anchorPos, width, height);
}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;

  MarkerLayer(this.markerOpts, this.map, this.stream);

  bool _boundsContainsMarker(Marker marker) {
    var pixelPoint = map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        var markers = <Widget>[];
        for (var markerOpt in markerOpts.markers) {
          var pos = map.project(markerOpt.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();

//          var pixelPosX =
//              (pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();
//          var pixelPosY =
//              (pos.y - (markerOpt.height - markerOpt.anchor.top)).toDouble();
          var pixelPos = CustomPoint(
              pos.x - (markerOpt.width - markerOpt.anchor.left),
              pos.y - (markerOpt.height - markerOpt.anchor.top));

          if (pixelPos.x >= 0 &&
              pixelPos.x < markerOpts.spherize.width &&
              pixelPos.y >= 0 &&
              pixelPos.y < markerOpts.spherize.height) {
            pixelPos = markerOpts.spherize.getPoint(
                (pos.x - (markerOpt.width - markerOpt.anchor.left)).toInt(),
                (pos.y - (markerOpt.height - markerOpt.anchor.top)).toInt(),
                0,
                0,
                map.spherizeVal);
          }

          if (!_boundsContainsMarker(markerOpt)) {
            continue;
          }

          markers.add(
            Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: pixelPos.x,
              top: pixelPos.y,
              child: markerOpt.builder(
                context,
                1,
              ),
            ),
          );
        }
        return Container(
          child: Stack(
            children: markers,
          ),
        );
      },
    );
  }
}
