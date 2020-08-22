import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_layer.dart';
import 'dart:async';
import 'tile_marker_options.dart';
import 'tile_marker_layer.dart';

class TileMarkerPlugin implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is TileMarkerLayerOptions) {
      return TileMarkerLayer(
          options: options, mapState: mapState, stream: stream);
    }
    throw Exception('Unknown options type for MyCustom'
        'plugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is TileMarkerLayerOptions;
  }
}
