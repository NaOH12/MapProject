import 'package:flutter_map/flutter_map.dart';
import 'package:flutterapp/post_data/post.dart';

class PostMarker extends Marker {

  final Post post;

  PostMarker({
    this.post,
    point,
    width,
    builder,
    height,
    AnchorPos anchorPos,
  }) : super(
    point: point,
    builder: builder,
    width: width,
    height: height,
    anchorPos: anchorPos,
  );

}

class ArtPostMarker extends Marker {

  final ArtPost post;

  ArtPostMarker({
    this.post,
    point,
    width,
    builder,
    height,
    AnchorPos anchorPos,
  }) : super(
    point: point,
    builder: builder,
    width: width,
    height: height,
    anchorPos: anchorPos,
  );

}