import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutterapp/post_data/post.dart' as post;
import 'package:flutterapp/post_data/tile.dart' as tile;
import 'package:flutterapp/post_data/tile_data_caching.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutterapp/network/api.dart';
import 'post_marker.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_layer.dart';
import 'package:flutterapp/tile_marker_plugin/tile_marker_options.dart';

abstract class TileMarkerProvider {
  TileMarkerProvider();

  Future<void> getMarkerData(List<Coords<num>> coords,
      List<TileMarker> tiles, TileMarkerLayerOptions options);

  void dispose() {}

  String _getTileUrl(
      List<Coords<num>> coordsList, TileMarkerLayerOptions options);

  int _getTileIndex(Coords coords, TileMarkerLayerOptions options,
      {double zoom}) {
    var z = (zoom == null) ? _getZoomForUrl(coords, options) : zoom;
    var x = coords.x.round();
    var y = coords.y.round();
    if (options.tms) {
      y = invertY(coords.y.round(), z.round());
    }
    var size = pow(2, z);
    return ((y * size) + x + 1).toInt();
  }

  Coords _getTileCoords(int tileIndex, double zoom);

  double _getZoomForUrl(Coords coords, TileMarkerLayerOptions options) {
    var zoom = coords.z;

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return zoom += options.zoomOffset;
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  MarkerBuilder defaultBuilder(
      post.Post post, double outerSize, double innerSize) {
    return (context, scale) {
      return GestureDetector(
          onTap: () {
            print(post.postContent);
          },
          child: Stack(alignment: AlignmentDirectional.center, children: [
            Container(
              height: outerSize * scale,
              width: outerSize * scale,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.black.withOpacity(0.7)),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [Colors.greenAccent, Colors.blueAccent])),
            ),
            Container(
              height: innerSize * scale,
              width: innerSize * scale,
//              child: Icon(Icons.home),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withOpacity(1)),
            ),
          ]));
    };
  }
}

class TilePostMarkerProvider extends TileMarkerProvider {
  TilePostMarkerProvider();

  final DBProvider _dbProvider = DBProvider();
  final Network _network = Network();

  // Keeps track of posts recently requested in this session.
  // We want to avoid making repeat http requests.
  final Map<String, DateTime> _recentTiles = Map<String, DateTime>();

  Coords _getTileCoords(int tileIndex, double zoom) {
    var size = pow(2, zoom);
    return Coords((tileIndex - 1) % size, ((tileIndex - 1) / size).floor());
  }

  @override
  String _getTileUrl(List<Coords<num>> coords, TileMarkerLayerOptions options) {
    String url = '/api/tiles/';
    for (final coord in coords) {
      url = url + _getTileIndex(coord, options).toString() + ',';
    }
    return url + '/posts';
  }

  String _getPostFetchPullUrl(List<int> fetchPostIds, List<int> pullTileIds) {
    String url = '/api/tiles/';
    for (final postId in fetchPostIds) {
      url = url + postId.toString() + ',';
    }
    url = url + ':';
    for (final postId in pullTileIds) {
      url = url + postId.toString() + ',';
    }
    return url + '/posts/fetch_pull/';
  }

  List<post.Post> _handleNewJsonTilePosts(
      tileJson, TileMarkerLayerOptions options) {
    // Convert the tiles json post data to posts
    List<post.Post> newTilePosts = List<post.Post>();
    try {
      for (var postJson in tileJson['posts']) {
        newTilePosts
            .add(post.Post.fromJsonWithTileId(postJson, tileJson['tile_id']));
      }
    } catch (e) {
      print("ERRORORORROROR: \n" + tileJson.toString());
      rethrow;
    }
    // Make sure to save this new data
    _dbProvider.newPosts(
        newTilePosts,
        tile.Tile(tileJson['tile_id'],
            _getTileCoords(tileJson['tile_id'], options.postZoom)));

    return newTilePosts;
  }

  /// Determines whether we should make another request for this resource based on how recent the last request was.
  /// If allowed, the tile id will be recorded.
  bool _allowRequest(int tileId) {
    if (_recentTiles[tileId.toString()] != null &&
        DateTime.now().difference(_recentTiles[tileId.toString()]).inMinutes <
            1.0) {
      return false;
    } else {
      _recentTiles[tileId.toString()] = DateTime.now();
      return true;
    }
  }

  Future<Map<String, List<post.Post>>> _getData(
      List<Coords<num>> coordsList, TileMarkerLayerOptions options) async {
    Map<String, List<post.Post>> posts = Map<String, List<post.Post>>();
    // Marks the latest saved posts (used to send to server)
    List<int> fetchPostIds = List<int>();
    // For any tiles with no existing saved posts, then get all the posts.
    List<int> pullTileIds = List<int>();
    // For each tile, look for existing post data and determine if
    // new data should be requested.
    for (final coords in coordsList) {
      // Find the tile id
      int tileId = _getTileIndex(coords, options);
      // Get any existing posts
      var existingPosts = await _dbProvider.getPostsByTile(tileId);
      // If there are existing posts, then load them in
      if (existingPosts != null) {
        posts[tileId.toString()] = (existingPosts);
        if (_allowRequest(tileId)) fetchPostIds.add(existingPosts.last.postId);
      } else {
        // Otherwise initialise with empty list of posts for that tile
        posts[tileId.toString()] = List<post.Post>();
        if (_allowRequest(tileId)) pullTileIds.add(tileId);
      }
    }

    // Make a http request for more data if there are tiles to request.
    if (fetchPostIds.length != 0 || pullTileIds.length != 0) {
      // Ask the server if there's any new posts to get
      var body = await _network
          .getData(_getPostFetchPullUrl(fetchPostIds, pullTileIds));
      if (body['success']) {
        // For each returned tile
        for (var tileJson in body['data']['fetch']) {
          // Convert the tiles json post data to posts
          var newTilePosts = _handleNewJsonTilePosts(tileJson, options);

          // This is fricking inefficient but over a small list it shouldn't
          // really matter.
          posts[tileJson['tile_id'].toString()].addAll(newTilePosts);
        }

        for (var tileJson in body['data']['pull']) {
          // Convert the tiles json post data to posts
          var newTilePosts = _handleNewJsonTilePosts(tileJson, options);

          // This is fricking inefficient but over a small list it shouldn't
          // really matter.
          posts[tileJson['tile_id'].toString()].addAll(newTilePosts);
        }
      }
    }
    return posts;
  }

  @override
  Future<void> getMarkerData(List<Coords<num>> coords,
      List<TileMarker> tiles, TileMarkerLayerOptions options) async {
    if (coords.length == 0 || tiles.length == 0) {
      return null;
    }
    // Get posts
    Map<String, List<post.Post>> posts = await _getData(coords, options);

    int i = 0;
    double radius = 50.0;
    // For each tile
    for (final tilePosts in posts.values) {
      var list = List<PostMarker>();
      // For each post in tile
      for (final post in tilePosts) {
        // Create marker and add to list
        list.add(PostMarker(
            post: post,
            point: post.point,
            width: radius,
            height: radius,
            builder: (options.postBuilder != null)
                ? options.postBuilder
                : defaultBuilder(post, radius, radius - 10.0)));
      }
      tiles[i].markers = list;
      i++;
    }

  }
}

class TileArtMarkerProvider extends TileMarkerProvider {
  TileArtMarkerProvider();

  final DBProvider _dbProvider = DBProvider();
  final Network _network = Network();

  // Keeps track of posts recently requested in this session.
  // We want to avoid making repeat http requests.
  final Map<String, DateTime> _recentTiles = Map<String, DateTime>();

  Coords _getTileCoords(int tileIndex, double zoom) {
    var size = pow(2, zoom);
    return Coords((tileIndex - 1) % size, ((tileIndex - 1) / size).floor());
  }

  @override
  String _getTileUrl(List<Coords<num>> coords, TileMarkerLayerOptions options) {
    String url = '/api/tiles/';
    for (final coord in coords) {
      url = url + _getTileIndex(coord, options).toString() + ',';
    }
    return url + '/art_posts';
  }

  String _getArtPostFetchPullUrl(
      List<int> fetchArtPostIds, List<int> pullArtTileIds) {
    String url = '/api/tiles/';
    for (final artPostId in fetchArtPostIds) {
      url = url + artPostId.toString() + ',';
    }
    url = url + ':';
    for (final artPostId in pullArtTileIds) {
      url = url + artPostId.toString() + ',';
    }
    return url + '/art_posts/fetch_pull/';
  }

  List<post.ArtPost> _handleNewJsonTilePosts(
      tileJson, TileMarkerLayerOptions options) {
    // Convert the tiles json post data to posts
    List<post.ArtPost> newTileArtPosts = List<post.ArtPost>();
    try {
      for (var postJson in tileJson['posts']) {
        if (postJson['postable']['text_content'] != null) {
          newTileArtPosts.add(post.TextArtPost.fromJsonWithTileId(
              postJson, tileJson['tile_id']));
        }
      }
    } catch (e) {
      print("ERRORORORROROR: \n" + tileJson.toString());
      rethrow;
    }
    // Make sure to save this new data
    _dbProvider.newArtPosts(
        newTileArtPosts,
        tile.Tile(tileJson['tile_id'],
            _getTileCoords(tileJson['tile_id'], options.stampZoom)));

    return newTileArtPosts;
  }

  /// Determines whether we should make another request for this resource based on how recent the last request was.
  /// If allowed, the tile id will be recorded.
  bool _allowRequest(int tileId) {
    if (_recentTiles[tileId.toString()] != null &&
        DateTime.now().difference(_recentTiles[tileId.toString()]).inMinutes <
            1.0) {
      return false;
    } else {
      _recentTiles[tileId.toString()] = DateTime.now();
      return true;
    }
  }

  Future<Map<String, List<post.ArtPost>>> _getData(
      List<Coords<num>> coordsList, TileMarkerLayerOptions options) async {
    Map<String, List<post.ArtPost>> posts = Map<String, List<post.ArtPost>>();
    // Marks the latest saved posts (used to send to server)
    List<int> fetchPostIds = List<int>();
    // For any tiles with no existing saved posts, then get all the posts.
    List<int> pullTileIds = List<int>();
    // For each tile, look for existing post data and determine if
    // new data should be requested.
    for (final coords in coordsList) {
      // Find the tile id
      int tileId = _getTileIndex(coords, options, zoom: options.stampZoom);
      // Get any existing posts
      var existingPosts = await _dbProvider.getArtPostsByTile(tileId);
      // If there are existing posts, then load them in
      if (existingPosts != null) {
        posts[tileId.toString()] = (existingPosts);
        if (_allowRequest(tileId)) fetchPostIds.add(existingPosts.last.postId);
      } else {
        // Otherwise initialise with empty list of posts for that tile
        posts[tileId.toString()] = List<post.ArtPost>();
        if (_allowRequest(tileId)) pullTileIds.add(tileId);
      }
    }

    // Make a http request for more data if there are tiles to request.
    if (fetchPostIds.length != 0 || pullTileIds.length != 0) {
      // Ask the server if there's any new posts to get
      var body = await _network
          .getData(_getArtPostFetchPullUrl(fetchPostIds, pullTileIds));
      if (body['success']) {
        // For each returned tile
        for (var tileJson in body['data']['fetch']) {
          // Convert the tiles json post data to posts
          var newTilePosts = _handleNewJsonTilePosts(tileJson, options);

          // This is fricking inefficient but over a small list it shouldn't
          // really matter.
          posts[tileJson['tile_id'].toString()].addAll(newTilePosts);
        }

        for (var tileJson in body['data']['pull']) {
          // Convert the tiles json post data to posts
          var newTilePosts = _handleNewJsonTilePosts(tileJson, options);

          // This is fricking inefficient but over a small list it shouldn't
          // really matter.
          posts[tileJson['tile_id'].toString()].addAll(newTilePosts);
        }
      }
    }
    return posts;
  }

  @override
  Future<void> getMarkerData(List<Coords<num>> coords,
      List<TileMarker> tiles, TileMarkerLayerOptions options) async {
    if (coords.length == 0 || tiles.length == 0) {
      return null;
    }
    // Get posts
    Map<String, List<post.ArtPost>> posts = await _getData(coords, options);

    int i = 0;
    double radius = 50.0;
    // For each tile
    for (final tilePosts in posts.values) {
      var list = List<ArtPostMarker>();
      // For each post in tile
      for (final artPost in tilePosts) {
        // Check if art post is text art post
        if (artPost is post.TextArtPost) {
          // Create marker and add to list
          list.add(ArtPostMarker(
              post: artPost,
              point: artPost.point,
              width: radius,
              height: radius,
              builder: (options.postBuilder != null)
                  ? options.postBuilder
                  : textArtPostDefaultBuilder(artPost, radius, radius - 10.0)));
        }
      }
      tiles[i].markers = list;
      i++;
    }

  }

  @override
  MarkerBuilder textArtPostDefaultBuilder(
      post.TextArtPost post, double outerSize, double innerSize) {
    return (context, scale) {
      return GestureDetector(
          onTap: () {
            print(post.textContent);
          },
          child: Stack(alignment: AlignmentDirectional.center, children: [
            Container(
              height: outerSize * scale,
              width: outerSize * scale,
//              decoration: BoxDecoration(
//                  shape: BoxShape.circle, color: Colors.black.withOpacity(0.7)),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [Colors.greenAccent, Colors.blueAccent])),
            ),
            Container(
              height: innerSize * scale,
              width: innerSize * scale,
//              child: Icon(Icons.home),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withOpacity(1)),
            ),
          ]));
    };
  }

}
