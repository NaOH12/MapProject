import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/spherize_tiles.dart';
import 'dart:ui' as ui;

import 'package:flutterapp/tile_marker_plugin/tile_marker_provider.dart';

class TileMarkerLayerOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles.
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
//  final String urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be
  /// displayed (inclusive).
  /// In most tile providers goes from 0 to 19.
  final double maxZoom;

  // Minimum zoom number the tile source has available. If it is specified,
  // the tiles on all zoom levels lower than minNativeZoom will be loaded
  // from minNativeZoom level and auto-scaled.
  final double minNativeZoom;

  // Maximum zoom number the tile source has available. If it is specified,
  // the tiles on all zoom levels higher than maxNativeZoom will be loaded
  // from maxNativeZoom level and auto-scaled.
  final double maxNativeZoom;

  // If set to true, the zoom number used in tile URLs will be reversed (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  // The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
//  final List<String> subdomains;

  ///Color shown behind the tiles.
  final Color backgroundColor;

  ///Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is CachedNetworkTileProvider,
  /// which loads tile images from network and caches them offline.
  ///
  /// If you don't want to cache the tiles, use NetworkTileProvider instead.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileMarkerProvider postTileProvider = TilePostProvider();

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Static informations that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  final Map<String, String> additionalOptions;

  // Tiles will not update more than once every `updateInterval` milliseconds
  // (default 200) when panning.
  // It can be 0 (but it will calculating for loading tiles every frame when panning / zooming, flutter is fast)
  // This can save some fps and even bandwidth
  // (ie. when fast panning / animating between long distances in short time)
  final Duration updateInterval;

  // Tiles fade in duration in milliseconds (default 100),
  // it can 0 to avoid fade in
  final Duration tileFadeInDuration;

  final MarkerBuilder postBuilder;

//  final Map<String, ui.Image> assetImages;

  final Spherize spherize;
  final double postZoom;
  final double stampZoom;

  TileMarkerLayerOptions(this.spherize,
      {
        this.postZoom = 12.0,
        this.stampZoom = 16.0,
        this.tileSize = 256.0,
        this.minZoom = 0.0,
        this.maxZoom = 18.0,
        this.minNativeZoom,
        this.maxNativeZoom,
        this.zoomReverse = false,
        this.zoomOffset = 0.0,
        this.additionalOptions = const <String, String>{},
        this.keepBuffer = 2,
        this.backgroundColor = const Color(0xFFE0E0E0),
        this.tms = false,
        this.opacity = 1.0,
        this.postBuilder,
        // Tiles will not update more than once every `updateInterval` milliseconds
        // (default 200) when panning.
        // It can be 0 (but it will calculating for loading tiles every frame when panning / zooming, flutter is fast)
        // This can save some fps and even bandwidth
        // (ie. when fast panning / animating between long distances in short time)
        int updateInterval = 200,
        // Tiles fade in duration in milliseconds (default 100),
        // it can 0 to avoid fade in
        int tileFadeInDuration = 100,
        rebuild})
      : updateInterval =
  updateInterval <= 0 ? null : Duration(milliseconds: updateInterval),
        tileFadeInDuration = tileFadeInDuration <= 0
            ? null
            : Duration(milliseconds: tileFadeInDuration),
        super(rebuild: rebuild);
}