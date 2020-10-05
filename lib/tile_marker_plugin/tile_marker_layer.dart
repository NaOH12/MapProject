import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/map/map.dart';
import 'post_marker.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_options.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_provider.dart';
import 'package:latlong/latlong.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_map/plugin_api.dart';

Queue<TileMarker> queue;

/// Describes the needed properties to create a tile-based layer.
/// A tile is an image binded to a specific geographical position.

//class WMSTileLayerOptions {
//  final service = 'WMS';
//  final request = 'GetMap';
//
//  /// url of WMS service.
//  /// Ex.: 'http://ows.mundialis.de/services/service?'
//  final String baseUrl;
//
//  /// list of WMS layers to show
//  final List<String> layers;
//
//  /// list of WMS styles
//  final List<String> styles;
//
//  /// WMS image format (use 'image/png' for layers with transparency)
//  final String format;
//
//  /// Version of the WMS service to use
//  final String version;
//
//  /// tile transperency flag
//  final bool transparent;
//
//  // TODO find a way to implicit pass of current map [Crs]
//  final Crs crs;
//
//  /// other request parameters
//  final Map<String, String> otherParameters;
//
//  String _encodedBaseUrl;
//
//  double _versionNumber;
//
//  WMSTileLayerOptions({
//    @required this.baseUrl,
//    this.layers = const [],
//    this.styles = const [],
//    this.format = 'image/png',
//    this.version = '1.1.1',
//    this.transparent = true,
//    this.crs = const Epsg3857(),
//    this.otherParameters = const {},
//  }) {
//    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
//    _encodedBaseUrl = _buildEncodedBaseUrl();
//  }
//
//  String _buildEncodedBaseUrl() {
//    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
//    final buffer = StringBuffer(baseUrl)
//      ..write('&service=$service')
//      ..write('&request=$request')
//      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
//      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
//      ..write('&format=${Uri.encodeComponent(format)}')
//      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
//      ..write('&version=${Uri.encodeComponent(version)}')
//      ..write('&transparent=$transparent');
//    otherParameters
//        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
//    return buffer.toString();
//  }
//
//  String getUrl(Coords coords, int tileSize) {
//    final tileSizePoint = CustomPoint(tileSize, tileSize);
//    final nvPoint = coords.scaleBy(tileSizePoint);
//    final sePoint = nvPoint + tileSizePoint;
//    final nvCoords = crs.pointToLatLng(nvPoint, coords.z);
//    final seCoords = crs.pointToLatLng(sePoint, coords.z);
//    final nv = crs.projection.project(nvCoords);
//    final se = crs.projection.project(seCoords);
//    final bounds = Bounds(nv, se);
//    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
//        ? [bounds.min.y, bounds.min.x, bounds.max.y, bounds.max.x]
//        : [bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y];
//
//    final buffer = StringBuffer(_encodedBaseUrl);
//    buffer.write('&width=$tileSize');
//    buffer.write('&height=$tileSize');
//    buffer.write('&bbox=${bbox.join(',')}');
//    return buffer.toString();
//  }
//}

class TileMarkerLayer extends StatefulWidget {
  final TileMarkerLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  TileMarkerLayer({
    this.options,
    this.mapState,
    this.stream,
  });

  @override
  State<StatefulWidget> createState() {
    return _TileMarkerLayerState();
  }
}

class _TileMarkerLayerState extends State<TileMarkerLayer>
    with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  TileMarkerLayerOptions get options => widget.options;
  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;
  //ignore: unused_field
  Level _level;
  StreamSubscription _moveSub;
  StreamController<LatLng> _throttleUpdate;
  CustomPoint _tileSize;

  final TileMarkerProvider _tilePostMarkerProvider = TilePostMarkerProvider();
  final TileMarkerProvider _tileArtMarkerProvider = TileArtMarkerProvider();

  final Map<String, TileMarker> _tiles = {};
  final Map<double, Level> _levels = {};

  @override
  void initState() {
    super.initState();

    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _update(null);
    _moveSub = widget.stream.listen((_) => _handleMove());

    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng>(sync: true);
      _throttleUpdate.stream.transform(
        util.throttleStreamTransformerWithTrailingCall<LatLng>(
          options.updateInterval,
        ),
      )..listen(_update);
    }
  }

  @override
  void dispose() {
    super.dispose();

    _removeAllTiles();
    _moveSub?.cancel();
//    options.tileProvider.dispose();
    _throttleUpdate?.close();
  }

  double _squaredDistance(CustomPoint point1, CustomPoint point2) {
    return pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2);
  }

  @override
  Widget build(BuildContext context) {
    var tilesToRender = _tiles.values.toList()..sort();
    final centre = CustomPoint(
        options.spherize.width / 2.0, (options.spherize.height) / 2.0);
    final squaredRadius = pow((options.spherize.width - 30) / 2.0, 2);
    final fadeDistance = 5000;
    final fadeRadius = squaredRadius + fadeDistance;
    var markers = <Widget>[];
    for (final tile in tilesToRender) {
      if (tile.markers != null) {
        for (final marker in tile.markers) {
          var pos = map.project(marker.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
              map.getPixelOrigin();

          var pixelPos = CustomPoint(
              pos.x - (marker.width - marker.anchor.left),
              pos.y - (marker.height - marker.anchor.top));

          var squaredDistance =
              _squaredDistance(centre, pos /*+ (marker.adjustmentPoint * 2)*/);

          if (pos.x >= 0 &&
              pos.x < (options.spherize.width) &&
              pos.y >= 0 &&
              pos.y < options.spherize.height) {
//            pixelPos = options.spherize.getPoint((pixelPos.x).toInt(),
//                (pixelPos.y).toInt(), 0, 0, map.spherizeVal);
            pixelPos = options.spherize.getPoint(
                (pos.x).toInt(), (pos.y).toInt(), 0, 0, map.spherizeVal);
          }

          if (squaredDistance <= squaredRadius) {
            final sizeScale =
                ((1 - (squaredDistance / squaredRadius)) * 0.5) + 0.5;

            markers.add(
              Positioned(
                width: marker.width,
                height: marker.height,
                left: pixelPos.x - marker.anchor.left,
                top: pixelPos.y - marker.anchor.top,
                child: marker.builder(context, sizeScale),
              ),
            );
          } else if (squaredDistance > squaredRadius &&
              squaredDistance <= fadeRadius) {
            final fade =
                (fadeRadius - squaredDistance) / (fadeRadius - squaredRadius);
            final sizeScale =
            (((1 - (squaredDistance / squaredRadius)) * 0.4) + 0.6) * fade;
            markers.add(
              Positioned(
                width: marker.width,
                height: marker.height,
                left: pixelPos.x - (marker.width / 2),
                top: pixelPos.y - (marker.height / 2),
                child: Opacity(
                    opacity: fade, child: marker.builder(context, sizeScale)),
              ),
            );
          }
        }
      }
    }

//    {
//      var width = 20.0;
//      var height = 20.0;
//      var point_top = LatLng(map.center.latitude + 0.037, map.center.longitude);
//      var point_bottom =
//          LatLng(map.center.latitude - 0.037, map.center.longitude);
//      var point_left =
//          LatLng(map.center.latitude, map.center.longitude + 0.0585);
//      var point_right =
//          LatLng(map.center.latitude, map.center.longitude - 0.0585);
//
//      var pos_top = map.project(point_top);
//      var pos_bottom = map.project(point_bottom);
//      var pos_left = map.project(point_left);
//      var pos_right = map.project(point_right);
//
//      pos_top = pos_top.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
//          map.getPixelOrigin();
//      pos_bottom = pos_bottom.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
//          map.getPixelOrigin();
//      pos_left = pos_left.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
//          map.getPixelOrigin();
//      pos_right = pos_right.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
//          map.getPixelOrigin();
//
//      var pixelPosTop = options.spherize.getPoint(
//          (pos_top.x).toInt(),
//          (pos_top.y).toInt(),
//          0,
//          0,
//          map.spherizeVal);
//      var pixelPosBottom = options.spherize.getPoint(
//          (pos_bottom.x).toInt(),
//          (pos_bottom.y).toInt(),
//          0,
//          0,
//          map.spherizeVal);
//      var pixelPosLeft = options.spherize.getPoint(
//          (pos_left.x).toInt(),
//          (pos_left.y).toInt(),
//          0,
//          0,
//          map.spherizeVal);
//      var pixelPosRight = options.spherize.getPoint(
//          (pos_right.x).toInt(),
//          (pos_right.y).toInt(),
//          0,
//          0,
//          map.spherizeVal);
//
//      markers.addAll([
//        Positioned(
//            width: width,
//            height: height,
//            left: pixelPosTop.x - (width / 2),
//            top: pixelPosTop.y - (height / 2),
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.red.withOpacity(1)),
//            )),
//        Positioned(
//            width: width,
//            height: height,
//            left: pixelPosBottom.x - (width / 2),
//            top: pixelPosBottom.y - (height / 2),
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.red.withOpacity(1)),
//            )),
//        Positioned(
//            width: width,
//            height: height,
//            left: pixelPosLeft.x - (width / 2),
//            top: pixelPosLeft.y - (height / 2),
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.red.withOpacity(1)),
//            )),
//        Positioned(
//            width: width,
//            height: height,
//            left: pixelPosRight.x - (width / 2),
//            top: pixelPosRight.y - (height / 2),
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.red.withOpacity(1)),
//            )),
//        Positioned(
//            width: width,
//            height: height,
//            left: 0 - (width / 2),
//            top: pixelPosLeft.y - height,
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.blue.withOpacity(1)),
//            )),
//        Positioned(
//            width: width,
//            height: height,
//            left: options.spherize.width.toDouble() - (width / 2),
//            top: pixelPosRight.y - height,
//            child: Container(
//              height: height,
//              width: width,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.blue.withOpacity(1)),
//            )),
//      ]);
//    }

    return Container(
      child: Stack(
        children: markers,
      ),
    );
  }

//  Widget _createTileWidget(Tile tile) {
//    var tilePos = tile.tilePos;
//    var level = tile.level;
//    var tileSize = getTileSize();
//    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
//    var width = tileSize.x * level.scale;
//    var height = tileSize.y * level.scale;
//
//    final Widget content = AnimatedTile(
//      tile: tile,
//      errorImage: options.errorImage,
//    );
//
//    return Positioned(
//      key: ValueKey(tile.coordsKey),
//      left: pos.x.toDouble(),
//      top: pos.y.toDouble(),
//      width: width.toDouble(),
//      height: height.toDouble(),
//      child: content,
//    );
//  }

  void _abortLoading() {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (var key in toRemove) {
      var tile = _tiles[key];

      tile.tileReady = null;
      tile.dispose();
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom) ??
          CustomPoint(0.0, 0.0);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    if (map == null) {
      return;
    }

    var zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      tile.retain = tile.current;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.current && !tile.active) {
        var coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeAllTiles() {
    var toRemove = Map<String, TileMarker>.from(_tiles);

    for (var key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    var x2 = (x / 2).floorToDouble();
    var y2 = (y / 2).floorToDouble();
    var z2 = z - 1;
    var coords2 = Coords(x2, y2);
    coords2.z = z2;

    var key = _tileCoordsToKey(coords2);

    var tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        var coords = Coords(i, j);
        coords.z = z + 1;

        var key = _tileCoordsToKey(coords);

        var tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom) {
      return options.minNativeZoom;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom < zoom) {
      return options.maxNativeZoom;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    var tileZoom = _clampZoom(zoom.roundToDouble());
    if ((options.maxZoom != null && tileZoom > options.maxZoom) ||
        (options.minZoom != null && tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _pruneTiles();

    _setZoomTransforms(center, zoom);
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i], center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first =
          (map.project(LatLng(0.0, crs.wrapLng.item1), tileZoom).x / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(0.0, crs.wrapLng.item2), tileZoom).x / tileSize.y)
              .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first =
          (map.project(LatLng(crs.wrapLat.item1, 0.0), tileZoom).y / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(crs.wrapLat.item2, 0.0), tileZoom).y / tileSize.y)
              .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _handleMove() {
    var tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restory fully via _setView call if we are back on trail
      if ((options.maxZoom != null && tileZoom <= options.maxZoom) &&
          (options.minZoom != null && tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);
        } else {
          if (null == _throttleUpdate) {
            _update(null);
          } else {
            _throttleUpdate.add(null);
          }

          _setZoomTransforms(map.center, map.zoom);
        }
      });
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var scale = map.getZoomScale(map.zoom, _tileZoom);
    var pixelCenter = map.project(center, _tileZoom).floor();
    var halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to map bounds
  void _update(LatLng center) {
    if (map == null ||
        _tileZoom == null ||
        (_tileZoom != options.postZoom && _tileZoom != options.stampZoom)) {
      return;
    }

    var zoom = _clampZoom(map.zoom);
    center ??= map.center;

    var pixelBounds = _getTiledPixelBounds(center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords<num>>[];
    var margin = options.keepBuffer;
    var noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      var c = tile.coords;

      if (tile.current == true &&
          (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom).abs() > 1) {
      _setView(center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom;

        if (!_isValidTile(coords)) {
          continue;
        }

        var tile = _tiles[_tileCoordsToKey(coords)];
        if (tile != null) {
          tile.current = true;
        } else {
          queue.add(coords);
        }
      }
    }

    // sort tile queue to load tiles in order of their distance to center
//    queue.sort((a, b) =>
//        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());
    // ^^ not too important if done in bulk

    if (queue.length > 0) {
      List<TileMarker> newlyCreated = List<TileMarker>();

      for (var i = 0; i < queue.length; i++) {
        newlyCreated.add(_addTile(queue[i]));
      }

      // Make a batch request for tile post data and then make tile
      _batchLoadTileData(queue, newlyCreated, _tileZoom);
    }
  }

  void _batchLoadTileData(
      List<Coords<num>> coords, List<TileMarker> tiles, double zoom) async {

    // Tell the provider to make batch request
    // This method will set data to the passed tiles
    // We check zoom level to determine which marker provider to use
    if (zoom == options.postZoom) {
      await _tilePostMarkerProvider.getMarkerData(coords, tiles, options);
    } else if (zoom == options.stampZoom) {
      await _tileArtMarkerProvider.getMarkerData(coords, tiles, options);
    }

    // Iterate over tiles and declare ready
    for (final tile in tiles) {
      _tileReady(_wrapCoords(tile.coords), tile);
    }
  }

  bool _isValidTile(Coords coords) {
    var crs = map.options.crs;

    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    var k = key.split(':');
    var coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose();
    _tiles.remove(key);
  }

  TileMarker _addTile(Coords<double> coords) {
    var tileCoordsToKey = _tileCoordsToKey(coords);
    _tiles[tileCoordsToKey] = TileMarker(
      coords: coords,
      wrapCoords: _wrapCoords(coords),
      coordsKey: tileCoordsToKey,
      options: options,
      tilePos: _getTilePos(coords),
      current: true,
      level: _levels[coords.z],
//      markerProvider:
//          (options.postZoom == coords.z) ? _tilePostMarkerProvider : null,
      tileReady: _tileReady,
    );
    return _tiles[tileCoordsToKey];
  }

  void _tileReady(Coords<double> coords, TileMarker tile) {
    var key = _tileCoordsToKey(coords);
    tile = _tiles[key];
    if (null == tile) {
      return;
    }

    tile.loaded = DateTime.now();
    tile.active = true;
//    if (options.tileFadeInDuration == null) {
//      tile.active = true;
//    } else {
//      tile.startFadeInAnimation(options.tileFadeInDuration, this);
//    }

    if (this.mounted) {
      setState(() {});
    }

    if (_noTilesToLoad()) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile fade-in)
      // to trigger a pruning.
      Future.delayed(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (this.mounted) {
            setState(_pruneTiles);
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z];
    return coords.scaleBy(getTileSize()) - level.origin;
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  bool _noTilesToLoad() {
    for (var entry in _tiles.entries) {
      if (entry.value.loaded == null) {
        return false;
      }
    }
    return true;
  }
}

typedef void TileReady(Coords<double> coords, TileMarker tile);

class TileMarker implements Comparable<TileMarker> {
  final String coordsKey;
  final Coords<double> coords;
  final Coords<double> wrapCoords;
  final CustomPoint<num> tilePos;
//  final TileMarkerProvider markerProvider;

  final Level level;

  Color testColour;
  bool current;
  bool retain;
  bool active;
  DateTime loaded;

  AnimationController animationController;
  double get opacity => animationController == null
      ? (active ? 1.0 : 0.0)
      : animationController.value;

  // callback when tile is ready / error occurred
  // it maybe be null forinstance when download aborted
  TileReady tileReady;
  List<Marker> markers;
  TileMarkerLayerOptions options;
//  ImageInfo imageInfo;
//  ImageStream _imageStream;
//  ImageStreamListener _listener;

  TileMarker({
    this.coordsKey,
    this.coords,
    this.wrapCoords,
    this.options,
    this.tilePos,
//    this.markerProvider,
    this.tileReady,
    this.level,
    this.current = false,
    this.active = false,
    this.retain = false,
  }) {
//      _imageStream = imageProvider.resolve(ImageConfiguration());
//      _listener = ImageStreamListener(_tileOnLoad, onError: _tileOnError);
//      _imageStream.addListener(_listener);
//    setTileMarkers();
  }

//  void setTileMarkers() async {
//    if (tileReady != null) {
//      if (markerProvider != null) {
//        markers = await markerProvider.getData(wrapCoords, options);
//      }
//      tileReady(coords, this);
//    }
//  }

  void setTestColour(Color colour) {
    if (testColour == null) {
      testColour = colour;
    }
  }

  // call this before GC!
  void dispose([bool evict = false]) {
//    if (evict && imageProvider != null) {
//      imageProvider
//          .evict()
//          .then((bool succ) => print('evict tile: $coords -> $succ'))
//          .catchError((error) => print('evict tile: $coords -> $error'));
//    }

    animationController?.removeStatusListener(_onAnimateEnd);
//    _imageStream?.removeListener(_listener);
  }

  void startFadeInAnimation(Duration duration, TickerProvider vsync) {
    animationController = AnimationController(duration: duration, vsync: vsync)
      ..addStatusListener(_onAnimateEnd);

    animationController.forward();
  }

  void _onAnimateEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      active = true;
    }
  }

  @override
  int compareTo(TileMarker other) {
    var zIndexA = level.zIndex;
    var zIndexB = other.level.zIndex;

    if (zIndexA == zIndexB) {
      return 0;
    } else {
      return zIndexB.compareTo(zIndexA);
    }
  }

  @override
  int get hashCode => coords.hashCode;

  @override
  bool operator ==(other) {
    return other is TileMarker && coords == other.coords;
  }
}

//class AnimatedTile extends StatefulWidget {
//  final Tile tile;
//  final ImageProvider errorImage;
//
//  AnimatedTile({Key key, this.tile, this.errorImage})
//      : assert(null != tile),
//        super(key: key);
//
//  @override
//  _AnimatedTileState createState() => _AnimatedTileState();
//}
//
//class _AnimatedTileState extends State<AnimatedTile> {
//  bool listenerAttached = false;
//
//  @override
//  Widget build(BuildContext context) {
////    return Opacity(
////      opacity: widget.tile.opacity,
////      child: (widget.tile.loadError && widget.errorImage != null)
////          ? Image(
////              image: widget.errorImage,
////              fit: BoxFit.fill,
////            )
////          : RawImage(
////              image: widget.tile.imageInfo?.image,
////              fit: BoxFit.fill,
////            ),
////    );
//    return Container();
//  }
//
//  @override
//  void initState() {
//    super.initState();
//
//    if (null != widget.tile.animationController) {
//      widget.tile.animationController.addListener(_handleChange);
//      listenerAttached = true;
//    }
//  }
//
//  @override
//  void dispose() {
//    if (listenerAttached) {
//      widget.tile.animationController?.removeListener(_handleChange);
//    }
//
//    super.dispose();
//  }
//
//  @override
//  void didUpdateWidget(AnimatedTile oldWidget) {
//    super.didUpdateWidget(oldWidget);
//
//    if (!listenerAttached && null != widget.tile.animationController) {
//      widget.tile.animationController.addListener(_handleChange);
//      listenerAttached = true;
//    }
//  }
//
//  void _handleChange() {
//    setState(() {});
//  }
//}

//class Level {
//  double zIndex;
//  CustomPoint origin;
//  double zoom;
//  CustomPoint translatePoint;
//  double scale;
//}

//class Coords<T extends num> extends CustomPoint<T> {
//  T z;
//
//  Coords(T x, T y) : super(x, y);
//
//  @override
//  String toString() => 'Coords($x, $y, $z)';
//
//  @override
//  bool operator ==(dynamic other) {
//    if (other is Coords) {
//      return x == other.x && y == other.y && z == other.z;
//    }
//    return false;
//  }
//
//  @override
//  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
//}
